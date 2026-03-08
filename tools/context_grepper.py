#!/usr/bin/env python3
"""Context Grepper for PromptOpt.

Primary mode: Morph WarpGrep direct API (model: morph-warp-grep) with local tool execution.
Fallback mode: local scan for likely-relevant files.

The output is a context bundle formatted as a sequence of:

<file path="relative/path">
... contents ...
</file>

This tool is READ-ONLY.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple


MORPH_API_URL = os.environ.get("MORPH_API_URL", "https://api.morphllm.com/v1/chat/completions")

MAX_TURNS = 4
MAX_GREP_LINES = 200
MAX_LIST_LINES = 200
MAX_READ_LINES = 800


SYSTEM_PROMPT = (
    "You are a code search agent. Your task is to find all relevant code for a given query. "
    "You have exactly 4 turns. The 4th turn MUST be a `finish` call. "
    "Tools: <grep>, <read>, <list_directory>, <finish>. "
    "Always wrap reasoning in <think>...</think> then output tool calls as XML elements."
)


DEFAULT_EXCLUDE_DIRS = {
    ".git",
    "node_modules",
    "dist",
    "build",
    "__pycache__",
    ".venv",
    "venv",
    ".idea",
    ".vscode",
    ".embedding-index",
}

DEFAULT_EXCLUDE_GLOBS = {
    ".env",
    "*.env",
    "*.env.*",
    "secrets.txt",
    "api-keys.txt",
    "*.key",
    "*.pem",
    "*.p12",
    "*.exe",
    "*.dll",
    "*.pdb",
    "*.zip",
    "*.7z",
    "*.png",
    "*.jpg",
    "*.jpeg",
    "*.gif",
    "*.pdf",
}


SENSITIVE_FILENAMES = {
    ".env",
    "secrets.txt",
    "api-keys.txt",
}


@dataclass
class ToolCall:
    name: str
    args: Dict[str, object]


def _eprint(msg: str) -> None:
    try:
        print(msg, file=sys.stderr)
    except Exception:
        pass


def _get_morph_api_key() -> Optional[str]:
    key = os.environ.get("MORPH_API_KEY")
    if key:
        key = key.strip()
    return key or None


def call_warpgrep(messages: List[Dict[str, str]], timeout_sec: int = 30) -> str:
    api_key = _get_morph_api_key()
    if not api_key:
        raise RuntimeError("MORPH_API_KEY not set")

    body = {
        "model": "morph-warp-grep",
        "messages": messages,
        "temperature": 0.0,
        "max_tokens": 2048,
    }
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(MORPH_API_URL, data=data, method="POST")
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")

    with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
        raw = resp.read().decode("utf-8", errors="replace")
        obj = json.loads(raw)
        return obj["choices"][0]["message"]["content"]


def parse_xml_elements(content: str) -> Dict[str, object]:
    args: Dict[str, object] = {}
    for match in re.finditer(r"<(\w+)>(.*?)</\1>", content, re.DOTALL):
        key = match.group(1)
        value = match.group(2).strip()
        if key == "file":
            args.setdefault("files", []).append(parse_xml_elements(value))
        else:
            args[key] = value
    return args


def parse_tool_calls(response: str) -> List[ToolCall]:
    response = re.sub(r"<think>.*?</think>", "", response, flags=re.DOTALL)
    calls: List[ToolCall] = []
    for name in ["grep", "read", "list_directory", "finish"]:
        for match in re.finditer(rf"<{name}>(.*?)</{name}>", response, re.DOTALL):
            calls.append(ToolCall(name=name, args=parse_xml_elements(match.group(1))))
    return calls


def _safe_relpath(path: Path, repo_root: Path) -> str:
    try:
        return str(path.relative_to(repo_root)).replace("\\", "/")
    except Exception:
        return str(path).replace("\\", "/")


def _is_binary(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            chunk = f.read(4096)
        return b"\x00" in chunk
    except Exception:
        return True


def _is_sensitive_path(rel_path: str) -> bool:
    p = rel_path.replace("\\", "/")
    base = p.split("/")[-1]
    if base in SENSITIVE_FILENAMES:
        return True
    if base.startswith(".") and base.endswith("env"):
        return True
    if base == ".env":
        return True
    if base.endswith(".env") or ".env." in base:
        return True
    return False


def execute_grep(repo_root: Path, pattern: str, sub_dir: str = ".", glob: Optional[str] = None) -> str:
    path = repo_root / sub_dir
    cmd = ["rg", "--line-number", "--no-heading", "--color", "never", "-C", "1"]
    if glob:
        cmd.extend(["--glob", glob])
    cmd.extend([pattern, str(path)])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10, cwd=str(repo_root))
        output = (result.stdout or "").strip()
    except FileNotFoundError:
        return "Error: ripgrep (rg) not found"
    except subprocess.TimeoutExpired:
        return "Error: search timed out"
    except Exception as e:
        return f"Error: {e}"

    lines = output.split("\n") if output else []
    if len(lines) > MAX_GREP_LINES:
        return "query not specific enough, tool call tried to return too much context and failed"
    return output or "no matches"


def execute_read(repo_root: Path, rel_path: str, lines: Optional[str] = None) -> str:
    if _is_sensitive_path(rel_path):
        return f"Error: refused to read sensitive file: {rel_path}"

    fp = repo_root / rel_path
    if not fp.exists():
        return f"Error: file not found: {rel_path}"
    if _is_binary(fp):
        return f"Error: binary file: {rel_path}"

    try:
        all_lines = fp.read_text(encoding="utf-8", errors="replace").splitlines()
    except Exception as e:
        return f"Error: {e}"

    if lines and lines != "*":
        selected: List[int] = []
        for part in lines.split(","):
            part = part.strip()
            if not part:
                continue
            if "-" in part:
                s, e = part.split("-", 1)
                start, end = int(s), int(e)
            else:
                start = end = int(part)
            selected.extend(range(start - 1, min(end, len(all_lines))))

        out: List[str] = []
        prev = -2
        for idx in sorted(set(selected)):
            if idx < 0 or idx >= len(all_lines):
                continue
            if prev >= 0 and idx > prev + 1:
                out.append("...")
            out.append(f"{idx + 1}|{all_lines[idx]}")
            prev = idx

        if len(out) > MAX_READ_LINES:
            out = out[:MAX_READ_LINES]
            out.append(f"... truncated ({len(all_lines)} total lines)")
        return "\n".join(out)

    out2 = [f"{i + 1}|{line}" for i, line in enumerate(all_lines[:MAX_READ_LINES])]
    if len(all_lines) > MAX_READ_LINES:
        out2.append(f"... truncated ({len(all_lines)} total lines)")
    return "\n".join(out2)


def fallback_list_dir(dir_path: Path, pattern: Optional[str], max_depth: int = 3) -> str:
    lines: List[str] = []
    compiled = re.compile(pattern) if pattern else None

    def walk(p: Path, depth: int = 0) -> None:
        if depth > max_depth:
            return
        try:
            for item in sorted(p.iterdir()):
                if item.name.startswith("."):
                    continue
                if item.is_dir() and item.name in DEFAULT_EXCLUDE_DIRS:
                    continue
                suffix = "/" if item.is_dir() else ""
                line = (" " * depth) + item.name + suffix
                if compiled is None or compiled.search(line):
                    lines.append(line)
                if item.is_dir():
                    walk(item, depth + 1)
        except PermissionError:
            return

    walk(dir_path)
    return "\n".join(lines[:MAX_LIST_LINES])


def execute_list_directory(repo_root: Path, path: str, pattern: Optional[str] = None) -> str:
    dp = repo_root / path
    if not dp.exists():
        return f"Error: directory not found: {path}"

    if os.name == "nt":
        output = fallback_list_dir(dp, pattern)
        lines = output.split("\n") if output else []
    else:
        cmd = [
            "tree",
            "-L",
            "3",
            "-i",
            "-F",
            "--noreport",
            "-I",
            "__pycache__|node_modules|.git|*.pyc|.DS_Store|.venv|venv|dist|build",
            str(dp),
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5, cwd=str(repo_root))
            output = (result.stdout or "").strip()
            lines = output.split("\n") if output else []
        except FileNotFoundError:
            output = fallback_list_dir(dp, pattern)
            lines = output.split("\n") if output else []
        except subprocess.TimeoutExpired:
            return "Error: directory listing timed out"
        except Exception as e:
            return f"Error: {e}"

    if pattern:
        try:
            compiled = re.compile(pattern)
            lines = [l for l in lines if compiled.search(l)]
        except Exception:
            pass

    if len(lines) > MAX_LIST_LINES:
        return "query not specific enough, tool call tried to return too much context and failed"
    return "\n".join(lines)


def format_result(tc: ToolCall, output: str) -> str:
    if tc.name == "grep":
        attrs = f'pattern="{tc.args.get("pattern", "")}"'
        if "sub_dir" in tc.args:
            attrs += f' sub_dir="{tc.args["sub_dir"]}"'
        if "glob" in tc.args:
            attrs += f' glob="{tc.args["glob"]}"'
        return f"<grep {attrs}>\n{output}\n</grep>"

    if tc.name == "read":
        attrs = f'path="{tc.args.get("path", "")}"'
        if "lines" in tc.args:
            attrs += f' lines="{tc.args["lines"]}"'
        return f"<read {attrs}>\n{output}\n</read>"

    if tc.name == "list_directory":
        attrs = f'path="{tc.args.get("path", "")}"'
        return f"<list_directory {attrs}>\n{output}\n</list_directory>"

    return output


def get_repo_structure(repo_root: Path) -> str:
    out = execute_list_directory(repo_root, ".", None)
    return f"<repo_structure>\n{out}\n</repo_structure>"


def resolve_finish(repo_root: Path, finish_call: ToolCall) -> List[Dict[str, str]]:
    results: List[Dict[str, str]] = []
    files = finish_call.args.get("files", [])
    if not isinstance(files, list):
        return results

    for spec in files:
        if not isinstance(spec, dict):
            continue
        path = str(spec.get("path", ""))
        if not path:
            continue
        lines = spec.get("lines")
        if isinstance(lines, str) and lines.strip() == "*":
            lines = None
        content = execute_read(repo_root, path, str(lines) if isinstance(lines, str) else None)
        results.append({"path": path, "content": content})

    return results


def run_warpgrep(query: str, repo_root: Path) -> List[Dict[str, str]]:
    messages: List[Dict[str, str]] = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": f"{get_repo_structure(repo_root)}\n\n<search_string>\n{query}\n</search_string>",
        },
    ]

    for turn in range(MAX_TURNS):
        response = call_warpgrep(messages)
        messages.append({"role": "assistant", "content": response})

        tool_calls = parse_tool_calls(response)
        if not tool_calls:
            break

        finish_call = next((tc for tc in tool_calls if tc.name == "finish"), None)
        if finish_call:
            return resolve_finish(repo_root, finish_call)

        results: List[str] = []
        for tc in tool_calls:
            if tc.name == "grep":
                out = execute_grep(
                    repo_root,
                    str(tc.args.get("pattern", "")),
                    str(tc.args.get("sub_dir", ".")),
                    str(tc.args.get("glob", "")) if tc.args.get("glob") else None,
                )
            elif tc.name == "read":
                out = execute_read(
                    repo_root,
                    str(tc.args.get("path", "")),
                    str(tc.args.get("lines", "")) if tc.args.get("lines") else None,
                )
            elif tc.name == "list_directory":
                out = execute_list_directory(
                    repo_root,
                    str(tc.args.get("path", ".")),
                    str(tc.args.get("pattern", "")) if tc.args.get("pattern") else None,
                )
            else:
                out = f"Unknown tool: {tc.name}"
            results.append(format_result(tc, out))

        remaining = MAX_TURNS - (turn + 1)
        messages.append({
            "role": "user",
            "content": "\n\n".join(results) + f"\nYou have used {turn + 1} turns and have {remaining} remaining\n",
        })

    return []


def _should_exclude_path(path: Path, repo_root: Path, exclude_dirs: set, exclude_globs: set) -> bool:
    try:
        rel = path.relative_to(repo_root)
    except Exception:
        return True

    for part in rel.parts:
        if part in exclude_dirs:
            return True

    if path.is_file():
        rel_norm = str(rel).replace("\\", "/")
        base = rel_norm.split("/")[-1]
        if base in SENSITIVE_FILENAMES:
            return True

    for g in exclude_globs:
        if path.is_file() and fnmatch.fnmatch(path.name, g):
            return True

    return False


def local_fallback_collect(repo_root: Path, query: str, max_files: int) -> List[Dict[str, str]]:
    needles = [w.lower() for w in re.findall(r"[A-Za-z_][A-Za-z0-9_\-]{2,}", query)][:8]
    if not needles:
        needles = [query.lower()[:32]]

    scored: List[Tuple[int, Path]] = []
    for p in repo_root.rglob("*"):
        if _should_exclude_path(p, repo_root, DEFAULT_EXCLUDE_DIRS, DEFAULT_EXCLUDE_GLOBS):
            continue
        if not p.is_file():
            continue
        if p.stat().st_size > 512_000:
            continue
        if _is_binary(p):
            continue

        try:
            txt = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        score = 0
        low = txt.lower()
        for n in needles:
            if n and n in low:
                score += low.count(n)
        if score > 0:
            scored.append((score, p))

    scored.sort(key=lambda t: t[0], reverse=True)
    out: List[Dict[str, str]] = []
    for _, p in scored[:max_files]:
        rel = _safe_relpath(p, repo_root)
        out.append({"path": rel, "content": execute_read(repo_root, rel, None)})
    return out


def render_context(files: List[Dict[str, str]], repo_root: Path, max_chars: int) -> str:
    parts: List[str] = []
    used = 0

    for f in files:
        path = f.get("path", "")
        content = f.get("content", "")
        if not path or not content:
            continue

        block = f"<file path=\"{path}\">\n{content}\n</file>\n"
        if used + len(block) > max_chars:
            break
        parts.append(block)
        used += len(block)

    return "\n".join(parts).strip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", required=True)
    ap.add_argument("--query", required=True)
    ap.add_argument("--output-file", required=True)
    ap.add_argument("--max-files", type=int, default=12)
    ap.add_argument("--max-chars", type=int, default=40000)
    ap.add_argument("--force-fallback", action="store_true")
    args = ap.parse_args()

    repo_root = Path(args.repo_root).expanduser().resolve()
    if not repo_root.exists() or not repo_root.is_dir():
        _eprint(f"Error: repo root not found: {repo_root}")
        return 2

    query = args.query.strip()
    if not query:
        _eprint("Error: empty query")
        return 2

    files: List[Dict[str, str]] = []
    if not args.force_fallback:
        try:
            files = run_warpgrep(query, repo_root)
        except Exception as e:
            _eprint(f"WarpGrep unavailable; falling back. ({e})")

    if not files:
        files = local_fallback_collect(repo_root, query, args.max_files)

    ctx = render_context(files, repo_root, args.max_chars)
    out_path = Path(args.output_file).expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(ctx, encoding="utf-8", newline="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
