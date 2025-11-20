import os
import re
import argparse
import dspy
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

class OptimizePrompt(dspy.Signature):
    """Transform a raw request into a structured, high-performance prompt following a specific format."""
    raw_request = dspy.InputField(desc="The user's original, potentially vague intent")
    format_definition = dspy.InputField(desc="The strict structural template the output must follow")
    optimized_prompt = dspy.OutputField(desc="The fully optimized prompt adhering exactly to the format_definition")

# Custom LM implementation to handle compatibility issues
class CompatibleOpenAI(dspy.LM):
    """Compatible LM implementation that works with current DSPy version"""

    def __init__(self, model, api_key, api_base=None, **kwargs):
        super().__init__(model)
        self.model = model
        self.api_key = api_key
        self.api_base = api_base or "https://api.openai.com/v1"
        self.kwargs = kwargs

        # Set default parameters
        if "temperature" not in self.kwargs:
            self.kwargs["temperature"] = 0.7
        if "max_tokens" not in self.kwargs:
            self.kwargs["max_tokens"] = 2000

    def basic_request(self, prompt, **kwargs):
        """Make a basic API request"""
        try:
            import openai

            client = openai.OpenAI(
                api_key=self.api_key,
                base_url=self.api_base
            )

            # Merge kwargs with defaults
            request_kwargs = {**self.kwargs, **kwargs}

            response = client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                **request_kwargs
            )

            return response.choices[0].message.content

        except Exception as e:
            print(f"API request failed: {e}")
            raise

    def __call__(self, prompt, only_completed=True, return_sorted=False, **kwargs):
        """Main entry point for DSPy"""
        try:
            result = self.basic_request(prompt, **kwargs)
            # Return exactly what DSPy expects - a simple string, not a dict
            return result
        except Exception as e:
            print(f"LM call failed: {e}")
            raise


class PromptOptimizer(dspy.Module):
    def __init__(self):
        super().__init__()
        # Use Predict instead of ChainOfThought to avoid compatibility issues
        self.generate = dspy.Predict(OptimizePrompt)

    def forward(self, raw_request, format_definition):
        return self.generate(raw_request=raw_request, format_definition=format_definition)

def parse_formatter_file(file_path):
    """Parses the Ability_Formatter.md file into a dictionary of formats."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Formatter file not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by headers like "## 1. Format Name"
    # Regex looks for "## " followed by a number, a dot, and space
    sections = re.split(r'^## \d+\. ', content, flags=re.MULTILINE)
    
    formats = {}
    # Skip the first section (intro)
    for section in sections[1:]:
        lines = section.strip().split('\n')
        title = lines[0].strip()
        body = '\n'.join(lines[1:]).strip()
        formats[title] = body
        
    return formats

def main():
    parser = argparse.ArgumentParser(description="Optimize prompts using DSPy and strict formats.")
    parser.add_argument("--request", type=str, help="The raw user request")
    parser.add_argument("--request-file", type=str, help="Path to a file containing the raw request")
    parser.add_argument("--format", type=str, help="The name of the format to use (e.g., 'XML Agent Spec')")
    parser.add_argument("--list-formats", action="store_true", help="List available formats")
    parser.add_argument("--model", type=str, default="anthropic/claude-3.5-sonnet", help="The LLM model to use")
    parser.add_argument("--provider", type=str, choices=["openai", "openrouter"], default="openrouter", help="API provider to use")
    
    args = parser.parse_args()

    formatter_path = os.path.join(os.path.dirname(__file__), "Ability_Formatter.md")
    formats = parse_formatter_file(formatter_path)

    if args.list_formats:
        print("Available Formats:")
        for name in formats:
            print(f"- {name}")
        return

    if not args.format:
        print("Error: --format is required unless --list-formats is specified.")
        return

    if not args.request and not args.request_file:
        print("Error: Must provide either --request or --request-file")
        return

    raw_request = args.request
    if args.request_file:
        with open(args.request_file, 'r', encoding='utf-8') as f:
            raw_request = f.read()

    # Fuzzy match format name
    selected_format_name = None
    selected_format_body = None
    
    # Try exact match first
    if args.format in formats:
        selected_format_name = args.format
        selected_format_body = formats[args.format]
    else:
        # Try case-insensitive partial match
        for name, body in formats.items():
            if args.format.lower() in name.lower():
                selected_format_name = name
                selected_format_body = body
                break
    
    if not selected_format_name:
        print(f"Error: Format '{args.format}' not found.")
        return

    print(f"Using Format: {selected_format_name}")
    
    # Select API provider and key based on user choice
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
        print(f"Please set {'OPENROUTER_API_KEY' if args.provider == 'openrouter' else 'OPENAI_API_KEY'} in your .env file.")
        return

    api_key = api_key.strip()
    print(f"Using {provider_name} with model: {args.model}")
    print(f"{provider_name} credentials detected and loaded.")

    # Initialize LM using our compatible implementation
    try:
        lm = CompatibleOpenAI(
            model=args.model,
            api_key=api_key,
            api_base=api_base,
            temperature=0.7,
            max_tokens=2000
        )
        print(f"Successfully initialized {provider_name} LM")

        # Configure DSPy settings
        dspy.settings.configure(lm=lm)
        print(f"DSPy configured with compatible LM")

        # Test the LM with a simple request to verify it works
        print("Testing LM with a simple request...")
        test_result = lm("Say 'Hello, this is working!' in exactly these words.")
        if test_result and len(test_result) > 0:
            print("LM test successful")
        else:
            print("LM test failed - no response received")
            return

    except Exception as e:
        print(f"Failed to initialize {provider_name} LM: {e}")
        print("This could be due to:")
        print("  - Invalid API key")
        print("  - Incorrect model name")
        print("  - Network issues")
        print("  - API service unavailable")
        print("  - DSPy compatibility issues")
        return

    optimizer = PromptOptimizer()

    print("Running optimization...")
    try:
        # Use the configured LM directly - no need for context manager if already configured
        result = optimizer(raw_request=raw_request, format_definition=selected_format_body)

        print("\n--- Optimized Prompt ---\n")
        print(result.optimized_prompt)
        print("\n------------------------\n")

    except Exception as e:
        print(f"Optimization failed: {e}")
        print("\nDebugging information:")
        print(f"  - Raw request length: {len(raw_request) if raw_request else 0}")
        print(f"  - Format definition length: {len(selected_format_body) if selected_format_body else 0}")
        print(f"  - Model: {args.model}")
        print(f"  - Provider: {provider_name}")

        # Show full traceback for debugging
        import traceback
        print("\nFull traceback:")
        traceback.print_exc()

        # Provide helpful suggestions
        print("\nPossible solutions:")
        print("  1. Check if your API key is valid and active")
        print("  2. Verify the model name is correct for your provider")
        print("  3. Try with a simpler request first")
        print("  4. Check network connectivity")

if __name__ == "__main__":
    main()
