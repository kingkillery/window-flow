"""
Simple formatter smoke test.

Runs dspy_prompt_opt.py with a small request and asserts:
- First character is not whitespace
- Output does not start with common preambles (“Below is”, “Here is”, etc.)
Skips cleanly if no API key is available.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "dspy_prompt_opt.py"


def extract_output(stdout: str) -> str:
    """Grab the optimized prompt block from the CLI output."""
    marker = "--- Optimized Prompt ---"
    if marker in stdout:
        after = stdout.split(marker, 1)[1]
        # Trim anything after the trailing dashed line if present
        if "------------------------" in after:
            after = after.split("------------------------", 1)[0]
        return after.strip()
    return stdout.strip()


def validate_output(text: str) -> None:
    if not text:
        raise AssertionError("Output is empty")
    if text[0].isspace():
        raise AssertionError("Output starts with whitespace")
    stripped = text.lstrip()
    if re.match(r"^(Below is|Here is|Here are|Below are)", stripped):
        raise AssertionError("Output starts with a preamble")
    if not re.match(r"^[\\[{<\\w]", stripped):
        raise AssertionError("Output does not start with structured content")


def main() -> int:
    if not (os.getenv("OPENAI_API_KEY") or os.getenv("OPENROUTER_API_KEY")):
        print("SKIP: No API key available for smoke test.")
        return 0

    cmd = [
        sys.executable,
        str(SCRIPT),
        "--request",
        "Summarize this into a checklist.",
        "--format",
        "Easy to Read",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(proc.stdout)
        print(proc.stderr, file=sys.stderr)
        raise SystemExit(proc.returncode)

    output = extract_output(proc.stdout)
    validate_output(output)
    print("Formatter smoke test passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
