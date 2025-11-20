#!/usr/bin/env python3
"""
Simple prompt optimizer without DSPy compatibility issues.
Uses OpenAI API directly to format prompts according to Ability_Formatter.md templates.
"""

import os
import re
import argparse
from dotenv import load_dotenv
import openai

def load_formatters(formatter_path):
    """Load format definitions from Ability_Formatter.md"""
    if not os.path.exists(formatter_path):
        raise FileNotFoundError(f"Formatter file not found: {formatter_path}")

    with open(formatter_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by headers like "## 1. Format Name"
    sections = re.split(r'^## \d+\. ', content, flags=re.MULTILINE)

    formats = {}
    # Skip the first section (intro)
    for section in sections[1:]:
        lines = section.strip().split('\n')
        title = lines[0].strip()
        body = '\n'.join(lines[1:]).strip()
        formats[title] = body

    return formats

def get_matching_format(formats, format_name):
    """Find the best matching format"""
    # Try exact match first
    if format_name in formats:
        return format_name, formats[format_name]

    # Try case-insensitive partial match
    for name, body in formats.items():
        if format_name.lower() in name.lower():
            return name, body

    return None, None

def create_optimization_prompt(raw_request, format_definition):
    """Create the prompt to send to the LLM"""
    return f"""You are a prompt optimization expert. Transform the user's raw request into a structured, high-performance prompt following the specific format provided.

USER'S RAW REQUEST:
{raw_request}

FORMAT TO FOLLOW:
{format_definition}

Please transform the raw request into an optimized prompt that strictly follows the format above. Return ONLY the formatted prompt content, with no additional commentary or explanation."""

def optimize_prompt(raw_request, format_definition, api_key, api_base, model):
    """Optimize the prompt using OpenAI API"""
    try:
        client = openai.OpenAI(api_key=api_key, base_url=api_base)

        prompt = create_optimization_prompt(raw_request, format_definition)

        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "system": "You are an expert prompt optimizer. Always follow the provided format exactly."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=2000
        )

        return response.choices[0].message.content

    except Exception as e:
        raise Exception(f"API call failed: {e}")

def main():
    parser = argparse.ArgumentParser(description="Simple prompt optimizer using OpenAI API.")
    parser.add_argument("--request", type=str, help="The raw user request")
    parser.add_argument("--request-file", type=str, help="Path to a file containing the raw request")
    parser.add_argument("--format", type=str, help="The name of the format to use")
    parser.add_argument("--list-formats", action="store_true", help="List available formats")
    parser.add_argument("--model", type=str, default="anthropic/claude-3.5-sonnet", help="The LLM model to use")
    parser.add_argument("--provider", type=str, choices=["openai", "openrouter"], default="openrouter", help="API provider to use")

    args = parser.parse_args()

    # Load environment variables
    script_dir = os.path.dirname(__file__)
    env_path = os.path.join(script_dir, '..', '.env')
    load_dotenv(env_path)

    # Load formatters
    formatter_path = os.path.join(script_dir, "Ability_Formatter.md")
    try:
        formats = load_formatters(formatter_path)
    except Exception as e:
        print(f"Error loading formatters: {e}")
        return

    if args.list_formats:
        print("Available Formats:")
        for i, name in enumerate(formats, 1):
            print(f"{i:2d}. {name}")
        return

    if not args.format:
        print("Error: --format is required unless --list-formats is specified.")
        return

    # Get raw request
    if not args.request and not args.request_file:
        print("Error: Must provide either --request or --request-file")
        return

    raw_request = args.request
    if args.request_file:
        try:
            with open(args.request_file, 'r', encoding='utf-8') as f:
                raw_request = f.read()
        except Exception as e:
            print(f"Error reading request file: {e}")
            return

    # Find format
    format_name, format_definition = get_matching_format(formats, args.format)
    if not format_name:
        print(f"Error: Format '{args.format}' not found.")
        print("Use --list-formats to see available formats.")
        return

    print(f"Using Format: {format_name}")

    # Get API configuration
    if args.provider == "openrouter":
        api_key = os.getenv("OPENROUTER_API_KEY")
        api_base = "https://openrouter.ai/api/v1"
        provider_name = "OpenRouter"
    else:  # openai
        api_key = os.getenv("OPENAI_API_KEY")
        api_base = os.getenv("OPENAI_API_BASE", "https://api.openai.com/v1")
        provider_name = "OpenAI"

    if not api_key:
        print(f"Error: {provider_name} API key not found in environment.")
        return

    print(f"Using {provider_name} with model: {args.model}")
    print(f"API Key: {api_key[:8]}...{api_key[-4:]}")

    # Optimize prompt
    print("Optimizing prompt...")
    try:
        optimized_prompt = optimize_prompt(
            raw_request=raw_request,
            format_definition=format_definition,
            api_key=api_key,
            api_base=api_base,
            model=args.model
        )

        print("\n" + "="*50)
        print("OPTIMIZED PROMPT")
        print("="*50)
        print(optimized_prompt)
        print("="*50)

    except Exception as e:
        print(f"Optimization failed: {e}")
        return

if __name__ == "__main__":
    main()