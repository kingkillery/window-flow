import sys
import json
import os
import requests
import time
import difflib
from pathlib import Path

def relace_edit_tool(tool_input_json):
    """
    Implements the RelaceEditTool logic as a standalone script.
    Accepts a JSON string with { "path": "...", "instruction": "...", "edit": "..." }
    Reads the file, calls Relace API (via OpenRouter), applies changes, and returns a diff.
    """
    try:
        # Parse input
        if isinstance(tool_input_json, str):
            data = json.loads(tool_input_json)
        else:
            data = tool_input_json

        # Handle potential PromptOpt wrapping (bridge compatibility)
        if "api_request" in data:
            return "Error: Received 'api_request' format. The prompt should output {path, instruction, edit}."
            
        path_str = data.get("path")
        instruction = data.get("instruction")
        edit_snippet = data.get("edit")

        if not path_str or not instruction or not edit_snippet:
            return "Error: Missing required fields (path, instruction, edit)."


        # Normalize path (Handle Git Bash /c/ style if present)
        if path_str.startswith("/") and len(path_str) > 2 and path_str[2] == "/":
             path_str = path_str[1] + ":" + path_str[2:]
        
        file_path = Path(path_str)

        # 1. Handle New File Creation
        if not file_path.exists():
            try:
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.write_text(edit_snippet, encoding="utf-8")
                return f"Created new file: {file_path} ({file_path.stat().st_size} bytes)\n\nContent:\n{edit_snippet}"
            except Exception as e:
                return f"Error creating file {file_path}: {e}"

        # 2. Handle Existing File Edit
        try:
            initial_code = file_path.read_text(encoding="utf-8")
        except Exception as e:
            return f"Error reading file {file_path}: {e}"

        # 3. Prepare Relace Apply request (OpenRouter by default; optional direct endpoint)
        api_key = os.environ.get("OPENROUTER_API_KEY") or os.environ.get("PROMPTOPT_API_KEY")
        if not api_key:
            return "Error: Missing API Key. Set OPENROUTER_API_KEY or PROMPTOPT_API_KEY."

        use_direct = os.environ.get("RELACE_USE_DIRECT") == "1"
        if use_direct:
            url = "https://instantapply.endpoint.relace.run/v1/code/apply"
            payload = {
                "initial_code": initial_code,
                "edit_snippet": edit_snippet,
                "instruction": instruction,
                "model": "relace-apply-3",
                "stream": False,
            }
        else:
            url = "https://openrouter.ai/api/v1/chat/completions"
            user_content = f"<instruction>{instruction}</instruction>\n<code>{initial_code}</code>\n<update>{edit_snippet}</update>"
            payload = {
                "model": "relace/relace-apply-3",
                "messages": [
                    {
                        "role": "user",
                        "content": user_content
                    }
                ],
                "temperature": 0.0
            }

        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/kingkillery/PromptOpt",
            "X-Title": "PromptOpt Relace Tool"
        }

        print(f"Applying changes to {file_path}...", file=sys.stderr)

        # Basic retry for transient 429/5xx
        def post_with_retry():
            backoff = 1.0
            for attempt in range(3):
                resp = requests.post(url, headers=headers, json=payload, timeout=30)
                if resp.status_code in (429, 500, 502, 503, 504):
                    time.sleep(backoff)
                    backoff *= 2
                    continue
                return resp
            return resp

        response = post_with_retry()
        
        if response.status_code == 200:
            result = response.json()

            if use_direct:
                if isinstance(result, str):
                    merged_code = result
                else:
                    merged_code = (
                        result.get("merged_code")
                        or result.get("updated_code")
                        or result.get("code")
                        or result.get("content")
                    )
            else:
                merged_code = result["choices"][0]["message"]["content"]

            if not merged_code:
                return "Error: API returned empty content."

            # Sanity check: avoid empty/None responses overwriting files
            merged_code_stripped = merged_code.strip()
            if not merged_code_stripped:
                return "Error: API returned empty content."

            # Guard against runaway outputs unless explicitly allowed
            allow_bloat = os.environ.get("RELACE_ALLOW_BLOAT") == "1"
            if (len(merged_code) > len(initial_code) * 2) and not allow_bloat:
                return (
                    "Error: Refusing to apply changes because merged output is more than "
                    "2x the original size. Set RELACE_ALLOW_BLOAT=1 to override."
                )

            # 4. Generate Diff
            diff = "".join(
                difflib.unified_diff(
                    initial_code.splitlines(keepends=True),
                    merged_code.splitlines(keepends=True),
                    fromfile="original",
                    tofile="modified",
                )
            )

            # 5. Write changes
            file_path.write_text(merged_code, encoding="utf-8")

            if diff:
                return f"Applied code changes using Relace API.\n\nChanges made:\n{diff}"
            else:
                return "Relace API processed the request but no changes were detected in the file."
        else:
            return f"Error calling Relace API: {response.status_code} - {response.text}"

    except json.JSONDecodeError as e:
        return f"Error parsing JSON payload: {e}"
    except Exception as e:
        return f"Error executing RelaceEditTool: {e}"

if __name__ == "__main__":
    # Set encoding for stdout to handle special chars in diffs
    sys.stdout.reconfigure(encoding='utf-8')
    
    # Read from stdin or file
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        with open(input_file, 'r', encoding='utf-8') as f:
            payload = f.read()
    else:
        print("Reading JSON payload from stdin (Ctrl+Z/D to finish)...", file=sys.stderr)
        payload = sys.stdin.read()

    result = relace_edit_tool(payload)
    print(result)
