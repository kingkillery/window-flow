#!/usr/bin/env python3
import argparse
import json
import os
import sys
import urllib.request
import urllib.error
from typing import Optional, Generator
import traceback
import time

# Import agent mode prompts
try:
    from agent_mode_prompts import (
        STAGE1_PROMPT, STAGE2_PROMPT, STAGE3_PROMPT, STAGE4_PROMPT,
        STAGE5_PROMPT, STAGE5_REWRITE_PROMPT, AGENT_MODE_SYSTEM
    )
    AGENT_MODE_AVAILABLE = True
except ImportError:
    AGENT_MODE_AVAILABLE = False


def dbg(msg: str) -> None:
    try:
        print(f"DBG: {msg}", file=sys.stderr)
    except Exception:
        pass


def read_text(path: str) -> str:
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()


def write_text(path: str, content: str) -> None:
    # Ensure parent dir exists
    os.makedirs(os.path.dirname(path), exist_ok=True) if os.path.dirname(path) else None
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(content)


def build_payload(model: str, sys_prompt: str, user_input: str) -> dict:
    return {
        "model": model,
        "instructions": sys_prompt,
        "input": f"Task, Goal, or Current Prompt:\n{user_input}",
        "temperature": 0.2,
        "reasoning": {"effort": "high"},
    }


def extract_output_text(obj: dict) -> str:
    # Try direct "output_text"
    txt = obj.get("output_text")
    if isinstance(txt, str) and txt.strip():
        return txt

    # Responses API: output[0].content[*] with type == 'output_text'
    output = obj.get("output")
    if isinstance(output, list) and output:
        first = output[0]
        content = first.get("content") if isinstance(first, dict) else None
        if isinstance(content, list):
            for part in content:
                if isinstance(part, dict) and part.get("type") == "output_text":
                    t = part.get("text")
                    if isinstance(t, str) and t.strip():
                        return t

    # OpenAI/compatible Chat Completions: choices[0].message.content
    choices = obj.get("choices")
    if isinstance(choices, list) and choices:
        first = choices[0]
        msg = first.get("message") if isinstance(first, dict) else None
        if isinstance(msg, dict):
            content = msg.get("content")
            if isinstance(content, str) and content.strip():
                return content

    # Fallback: return compact JSON for debugging
    return json.dumps(obj, ensure_ascii=False)


def post_json(url: str, body: dict, api_key: str, extra_headers: Optional[dict] = None, timeout_sec: int = 20) -> dict:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("User-Agent", "PromptOpt/1.0 (+https://localhost)")
    req.add_header("Accept", "application/json")
    if extra_headers:
        for k, v in extra_headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            return json.loads(raw)
    except urllib.error.HTTPError as e:
        error_body = ""
        try:
            error_body = e.read().decode("utf-8", errors="replace")
            error_obj = json.loads(error_body) if error_body else {}
            error_msg = error_obj.get("error", {}).get("message", str(e))
            dbg(f"HTTP {e.code}: {error_body}")
            if e.code == 401:
                raise ValueError(f"Authentication failed (401): {error_msg}. Please verify your API key is valid and not expired. Check your .env file for OPENROUTER_API_KEY.")
            raise ValueError(f"HTTP {e.code}: {error_msg}")
        except json.JSONDecodeError:
            dbg(f"HTTP {e.code}: {error_body}")
            if e.code == 401:
                raise ValueError(f"Authentication failed (401). Please verify your API key is valid and not expired. Check your .env file for OPENROUTER_API_KEY.")
            raise ValueError(f"HTTP {e.code}: {error_body}")


def stream_chat_completions(url: str, payload: dict, api_key: str, extra_headers: Optional[dict] = None, timeout_sec: int = 60) -> Generator[str, None, None]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("User-Agent", "PromptOpt/1.0 (+https://localhost)")
    req.add_header("Accept", "text/event-stream")
    if extra_headers:
        for k, v in extra_headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            while True:
                line = resp.readline()
                if not line:
                    break
                try:
                    s = line.decode("utf-8", errors="replace").strip()
                except Exception:
                    continue
                if not s:
                    continue
                if not s.startswith("data:"):
                    continue
                d = s[5:].strip()
                if d == "[DONE]":
                    break
                try:
                    obj = json.loads(d)
                except Exception:
                    continue
                choices = obj.get("choices")
                if isinstance(choices, list) and choices:
                    ch0 = choices[0] if isinstance(choices[0], dict) else None
                    if not ch0:
                        continue
                    delta = ch0.get("delta", {})
                    if isinstance(delta, dict):
                        piece = delta.get("content")
                        if isinstance(piece, str) and piece:
                            yield piece
    except urllib.error.HTTPError as e:
        error_body = ""
        try:
            error_body = e.read().decode("utf-8", errors="replace")
            error_obj = json.loads(error_body) if error_body else {}
            error_msg = error_obj.get("error", {}).get("message", str(e))
            dbg(f"HTTP {e.code}: {error_body}")
            if e.code == 401:
                raise ValueError(f"Authentication failed (401): {error_msg}. Please verify your API key is valid and not expired. Check your .env file for OPENROUTER_API_KEY.")
            raise ValueError(f"HTTP {e.code}: {error_msg}")
        except json.JSONDecodeError:
            dbg(f"HTTP {e.code}: {error_body}")
            if e.code == 401:
                raise ValueError(f"Authentication failed (401). Please verify your API key is valid and not expired. Check your .env file for OPENROUTER_API_KEY.")
            raise ValueError(f"HTTP {e.code}: {error_body}")


def try_call(base_url: str, model: str, sys_prompt: str, user_input: str, api_key: str, timeout_sec: int) -> dict:
    lb = base_url.rstrip("/")
    # Detect OpenRouter and use chat/completions compatibility
    is_openrouter = ("openrouter.ai" in lb) or api_key.startswith("sk-or-")
    if is_openrouter:
        # Force correct base for OpenRouter regardless of provided base_url
        lb = "https://openrouter.ai/api/v1"
        dbg(f"using OpenRouter endpoint: {lb}")
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": user_input},
            ],
            "temperature": 0.2,
        }
        # Support provider routing via environment variable
        # PROMPTOPT_PROVIDER_ONLY can be a comma-separated list like "cerebras" or "cerebras,deepinfra"
        provider_only = os.environ.get("PROMPTOPT_PROVIDER_ONLY")
        if provider_only:
            providers = [p.strip() for p in provider_only.split(",") if p.strip()]
            if providers:
                payload["provider"] = {"only": providers}
                dbg(f"provider routing: only={providers}")
        # Optional headers OpenRouter recognizes; configurable via env
        title = os.environ.get("PROMPTOPT_TITLE", "PromptOpt")
        referer = os.environ.get("PROMPTOPT_REFERER") or os.environ.get("OPENROUTER_SITE_URL") or "https://localhost/"
        extra = {"X-Title": title, "HTTP-Referer": referer}
        return post_json(f"{lb}/chat/completions", payload, api_key, extra_headers=extra, timeout_sec=timeout_sec)
    else:
        # Prefer Chat Completions for broad compatibility
        dbg(f"using OpenAI Chat Completions endpoint: {lb}/chat/completions")
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": user_input},
            ],
            "temperature": 0.2,
        }
        return post_json(f"{lb}/chat/completions", payload, api_key, timeout_sec=timeout_sec)


def call_api_simple(base_url: str, model: str, sys_prompt: str, user_input: str, api_key: str, timeout_sec: int = 60) -> str:
    """Simple API call that returns the response text. Used for agent mode stages."""
    resp = try_call(base_url, model, sys_prompt, user_input, api_key, timeout_sec)
    return extract_output_text(resp)


def call_api_streaming(base_url: str, model: str, sys_prompt: str, user_input: str, api_key: str, output_file: str, timeout_sec: int = 60) -> str:
    """Streaming API call that writes chunks to file and returns full response. Used for agent mode streaming."""
    full_response = []
    for piece in try_stream(base_url, model, sys_prompt, user_input, api_key, timeout_sec):
        full_response.append(piece)
        # Append each chunk to the output file for live preview
        try:
            with open(output_file, 'a', encoding='utf-8', newline='') as f:
                f.write(piece)
        except Exception:
            pass
    return ''.join(full_response)


def run_agent_mode(user_input: str, model: str, base_url: str, api_key: str, output_file: str, timeout_sec: int = 60, streaming: bool = False, enable_eval: bool = False) -> int:
    """
    Execute 5-stage Agent Mode pipeline with GPT-5.1 best practices.
    Writes progress to output_file for live streaming display.

    Args:
        user_input: The prompt/task to optimize
        model: Model to use for optimization
        base_url: API base URL
        api_key: API key
        output_file: File to write progress/results to
        timeout_sec: Timeout per API call
        streaming: If True, stream each stage's output live to file
        enable_eval: If True, run Stage 5 self-eval pass

    Returns: 0 on success, 1 on error
    """
    if not AGENT_MODE_AVAILABLE:
        dbg("Agent mode prompts not available")
        return 1

    total_stages = 5 if enable_eval else 4
    dbg(f"Starting Agent Mode pipeline ({total_stages} stages, streaming={streaming})")

    # Clear output file
    try:
        with open(output_file, 'w', encoding='utf-8', newline='') as f:
            f.write(f"Agent Mode: Starting {total_stages}-stage optimization...\n\n")
    except Exception as e:
        dbg(f"Failed to clear output file: {e}")
        return 1

    def write_stage_header(stage_name: str):
        """Write stage header for streaming mode."""
        try:
            with open(output_file, 'a', encoding='utf-8', newline='') as f:
                f.write(f'<STAGE name="{stage_name}">\n')
        except Exception as e:
            dbg(f"Failed to write stage header: {e}")

    def write_stage_footer():
        """Write stage footer for streaming mode."""
        try:
            with open(output_file, 'a', encoding='utf-8', newline='') as f:
                f.write('\n</STAGE>\n\n')
        except Exception as e:
            dbg(f"Failed to write stage footer: {e}")

    def write_progress(stage_name: str, content: str):
        """Append stage output to file for non-streaming display."""
        try:
            with open(output_file, 'a', encoding='utf-8', newline='') as f:
                f.write(f'<STAGE name="{stage_name}">\n{content}\n</STAGE>\n\n')
        except Exception as e:
            dbg(f"Failed to write progress: {e}")

    def update_status(msg: str):
        """Update status in output file."""
        try:
            with open(output_file, 'a', encoding='utf-8', newline='') as f:
                f.write(f"[STATUS] {msg}\n")
        except Exception:
            pass

    def call_stage(sys_prompt: str, user_prompt: str, stage_name: str) -> str:
        """Call API for a stage, with optional streaming."""
        if streaming:
            write_stage_header(stage_name)
            result = call_api_streaming(base_url, model, sys_prompt, user_prompt, api_key, output_file, timeout_sec)
            write_stage_footer()
            return result
        else:
            result = call_api_simple(base_url, model, sys_prompt, user_prompt, api_key, timeout_sec)
            write_progress(stage_name, result)
            return result

    try:
        # Stage 1: Goal Extraction (outputs JSON with task_type)
        update_status(f"Stage 1/{total_stages}: Extracting goals and intent...")
        stage1_prompt = STAGE1_PROMPT.format(input=user_input)
        dbg("Stage 1: Goal Extraction")
        stage1_raw = call_stage(AGENT_MODE_SYSTEM, stage1_prompt, "Goal Extraction")

        # Parse task_type from Stage 1 JSON for use in Stage 3
        task_type = "other"
        try:
            # Try to find JSON in the response (may be wrapped in markdown code blocks)
            json_str = stage1_raw
            if "```json" in json_str:
                json_str = json_str.split("```json")[1].split("```")[0]
            elif "```" in json_str:
                json_str = json_str.split("```")[1].split("```")[0]
            stage1_json = json.loads(json_str.strip())
            task_type = stage1_json.get("task_type", "other")
            dbg(f"Detected task_type: {task_type}")
        except json.JSONDecodeError as e:
            dbg(f"Could not parse Stage 1 JSON: {e}")
            task_type = "other"

        # Stage 2: Redundancy Removal & Clarification
        update_status(f"Stage 2/{total_stages}: Removing ambiguity and redundancy...")
        stage2_prompt = STAGE2_PROMPT.format(input=user_input, analysis=stage1_raw)
        dbg("Stage 2: Clarification")
        stage2_raw = call_stage(AGENT_MODE_SYSTEM, stage2_prompt, "Clarification")

        # Stage 3: Structure Optimization (uses task_type for scaffolding)
        update_status(f"Stage 3/{total_stages}: Optimizing structure...")
        stage3_prompt = STAGE3_PROMPT.format(clarified=stage2_raw, task_type=task_type)
        dbg("Stage 3: Structure")
        stage3_raw = call_stage(AGENT_MODE_SYSTEM, stage3_prompt, "Structure")

        # Stage 4: Final Assembly with GPT-5.1 enhancements
        update_status(f"Stage 4/{total_stages}: Final assembly and polish...")
        stage4_prompt = STAGE4_PROMPT.format(skeleton=stage3_raw, intent=stage1_raw)
        dbg("Stage 4: Final Assembly")
        stage4_raw = call_stage(AGENT_MODE_SYSTEM, stage4_prompt, "Final Assembly")

        final_prompt = stage4_raw

        # Stage 5: Self-Eval (optional)
        if enable_eval:
            update_status(f"Stage 5/{total_stages}: Self-evaluation and refinement...")
            stage5_prompt = STAGE5_PROMPT.format(prompt=stage4_raw, intent=stage1_raw)
            dbg("Stage 5: Self-Eval")
            stage5_raw = call_stage(AGENT_MODE_SYSTEM, stage5_prompt, "Self-Eval")

            # Parse eval result
            eval_passed = True
            try:
                eval_json_str = stage5_raw
                if "```json" in eval_json_str:
                    eval_json_str = eval_json_str.split("```json")[1].split("```")[0]
                elif "```" in eval_json_str:
                    eval_json_str = eval_json_str.split("```")[1].split("```")[0]
                eval_result = json.loads(eval_json_str.strip())
                eval_passed = eval_result.get("pass", True)
                overall_score = eval_result.get("overall_score", 5.0)
                dbg(f"Eval score: {overall_score}, pass: {eval_passed}")

                # If eval failed, apply fixes
                if not eval_passed and eval_result.get("suggested_fixes"):
                    update_status("Stage 5b: Applying evaluation fixes...")
                    rewrite_prompt = STAGE5_REWRITE_PROMPT.format(
                        prompt=stage4_raw,
                        feedback=json.dumps(eval_result, indent=2)
                    )
                    dbg("Stage 5b: Rewrite")
                    final_prompt = call_stage(AGENT_MODE_SYSTEM, rewrite_prompt, "Rewrite")
            except json.JSONDecodeError as e:
                dbg(f"Could not parse Stage 5 JSON: {e}")
                # Keep stage4 output as final

        # Write final result with separator
        with open(output_file, 'a', encoding='utf-8', newline='') as f:
            f.write(f"---FINAL---\n{final_prompt}")

        dbg("Agent Mode pipeline complete")
        return 0

    except Exception as e:
        dbg(f"Agent Mode error: {e}")
        try:
            with open(output_file, 'a', encoding='utf-8', newline='') as f:
                f.write(f"\n[ERROR] Agent Mode failed: {e}\n")
        except Exception:
            pass
        return 1


def try_stream(base_url: str, model: str, sys_prompt: str, user_input: str, api_key: str, timeout_sec: int) -> Generator[str, None, None]:
    lb = base_url.rstrip("/")
    is_openrouter = ("openrouter.ai" in lb) or api_key.startswith("sk-or-")
    if is_openrouter:
        lb = "https://openrouter.ai/api/v1"
        dbg(f"using OpenRouter endpoint (stream): {lb}")
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": user_input},
            ],
            "temperature": 0.2,
            "stream": True,
        }
        # Support provider routing via environment variable
        # PROMPTOPT_PROVIDER_ONLY can be a comma-separated list like "cerebras" or "cerebras,deepinfra"
        provider_only = os.environ.get("PROMPTOPT_PROVIDER_ONLY")
        if provider_only:
            providers = [p.strip() for p in provider_only.split(",") if p.strip()]
            if providers:
                payload["provider"] = {"only": providers}
                dbg(f"provider routing: only={providers}")
        title = os.environ.get("PROMPTOPT_TITLE", "PromptOpt")
        referer = os.environ.get("PROMPTOPT_REFERER") or os.environ.get("OPENROUTER_SITE_URL") or "https://localhost/"
        extra = {"X-Title": title, "HTTP-Referer": referer}
        yield from stream_chat_completions(f"{lb}/chat/completions", payload, api_key, extra_headers=extra, timeout_sec=timeout_sec)
    else:
        dbg(f"using OpenAI Chat Completions endpoint (stream): {lb}/chat/completions")
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": sys_prompt},
                {"role": "user", "content": user_input},
            ],
            "temperature": 0.2,
            "stream": True,
        }
        yield from stream_chat_completions(f"{lb}/chat/completions", payload, api_key, timeout_sec=timeout_sec)


def main() -> int:
    p = argparse.ArgumentParser(description="PromptOpt backend: call Responses API and emit text")
    p.add_argument("--system-prompt-file", required=True)
    p.add_argument("--user-input-file", required=True)
    p.add_argument("--output-file", required=True)
    p.add_argument("--api-key", required=False)
    p.add_argument("--model", default="openai/gpt-oss-120b")
    p.add_argument("--base-url", default="https://openrouter.ai/api/v1")
    p.add_argument("--stream", action="store_true", help="Enable streaming writes to the output file for live preview")
    p.add_argument("--agent-mode", action="store_true", help="Enable Agent Mode: 4-stage iterative prompt optimization")
    p.add_argument("--agent-mode-streaming", action="store_true", help="Enable Agent Mode with streaming: live output per stage")
    p.add_argument("--agent-mode-eval", action="store_true", help="Enable Agent Mode Stage 5: self-evaluation and refinement")
    args = p.parse_args()

    try:
        dbg("start main")
        sys_prompt = read_text(args.system_prompt_file).strip()
        user_input = read_text(args.user_input_file).strip()
        if not user_input:
            raise ValueError("Empty user input")

        api_key = args.api_key or os.environ.get("PROMPTOPT_API_KEY") or os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("API key not provided. Set PROMPTOPT_API_KEY or OPENAI_API_KEY.")
        # Strip whitespace that might have been introduced from .env file
        api_key = api_key.strip()
        if not api_key:
            raise ValueError("API key is empty after stripping whitespace. Check your .env file.")
        # Log key prefix for debugging (without exposing full key)
        if api_key and len(api_key) > 4:
            dbg(f"api_key prefix: {api_key[:7]}... (length: {len(api_key)})")
        else:
            dbg("WARN: API key appears to be empty or invalid")

        # Respect the base_url provided by the caller (PowerShell bridge)
        base_url = args.base_url
        dbg(f"base_url={base_url}")
        dbg(f"model_req={args.model}")

        # Allow override of timeout via env (seconds)
        try:
            timeout_sec = int(os.environ.get("PROMPTOPT_TIMEOUT", "60"))
        except Exception:
            timeout_sec = 60

        # Agent Mode: 4/5-stage iterative optimization
        if args.agent_mode or args.agent_mode_streaming:
            streaming = args.agent_mode_streaming
            enable_eval = args.agent_mode_eval
            dbg(f"Agent Mode enabled (streaming={streaming}, eval={enable_eval})")
            if not AGENT_MODE_AVAILABLE:
                print("Error: Agent mode prompts not available. Ensure agent_mode_prompts.py exists.", file=sys.stderr)
                return 1
            return run_agent_mode(user_input, args.model, base_url, api_key, args.output_file, timeout_sec, streaming=streaming, enable_eval=enable_eval)

        # Standard mode: Try requested model, then fallbacks
        is_openrouter = ("openrouter.ai" in base_url.lower()) or (api_key.startswith("sk-or-"))
        if is_openrouter:
            models_to_try = [args.model, "moonshotai/kimi-k2-0905", "z-ai/glm-4.5v", "deepseek/deepseek-chat-v3.1:free", "qwen/qwen3-next-80b-a3b-thinking", "openai/gpt-5-mini"]
        else:
            models_to_try = [args.model, "gpt-4o-mini", "gpt-4o"]
        last_err = None
        for m in models_to_try:
            try:
                dbg(f"trying model: {m}")
                if args.stream:
                    # Truncate output file and stream content
                    try:
                        with open(args.output_file, 'w', encoding='utf-8', newline='') as outf:
                            pass
                    except Exception:
                        pass
                    wrote_any = False
                    for piece in try_stream(base_url, m, sys_prompt, user_input, api_key, timeout_sec):
                        # Open/close for every chunk to avoid file locking issues on Windows
                        # so the frontend can read it in real-time
                        with open(args.output_file, 'a', encoding='utf-8', newline='') as outf:
                            outf.write(piece)
                        wrote_any = True
                    
                    if wrote_any:
                        dbg("stream complete with content")
                        return 0
                    else:
                        dbg("stream produced no content; attempting non-stream")
                        # fall through to non-stream
                # Non-streaming path
                resp = try_call(base_url, m, sys_prompt, user_input, api_key, timeout_sec)
                out_text = extract_output_text(resp)
                if out_text:
                    dbg("received output text")
                    write_text(args.output_file, out_text)
                    return 0
            except urllib.error.HTTPError as e:
                try:
                    details = e.read().decode("utf-8", errors="replace")
                except Exception:
                    details = ""
                msg = f"HTTP {e.code}: {details}"
                last_err = msg
                dbg(msg)
                # Retry with next model on common client-side issues and rate limits
                if ("model" in details.lower()) or (e.code in (400, 404, 429)):
                    continue
                print(msg, file=sys.stderr)
                return 2
            except urllib.error.URLError as e:
                last_err = f"URL error: {e.reason}"
                dbg(last_err)
                break
            except Exception as e:
                last_err = str(e)
                dbg(f"exception: {last_err}")
                break

        if last_err:
            print(f"Error: {last_err}", file=sys.stderr)
            return 1
        # Unexpected path
        print("Error: Unknown failure without details", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        try:
            traceback.print_exc()
        except Exception:
            pass
        return 1


if __name__ == "__main__":
    sys.exit(main())
