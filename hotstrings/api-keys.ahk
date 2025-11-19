#Requires AutoHotkey v2.0
; ####################################################################
; # API KEYS HOTSTRINGS MODULE                                       #
; # Security: These hotstrings only read from environment variables #
; # Note: Requires SendSecretFromEnv() from core/environment.ahk    #
; ####################################################################

Hotstring(":*:Orouterkey", (*) => SendSecretFromEnv("OPENROUTER_API_KEY", "Enter your OpenRouter API key"))

Hotstring(":*:hftoken", (*) => SendSecretFromEnv("HF_TOKEN", "Enter your HuggingFace token"))

Hotstring(":*:browserkeyuse", (*) => SendSecretFromEnv("BROWSER_USE_KEY", "Enter your BrowserUse API key"))

Hotstring(":*:browser-use-key", (*) => SendSecretFromEnv("BROWSER_USE_KEY_2", "Enter your BrowserUse API key"))

Hotstring(":*:gittoken", (*) => SendSecretFromEnv("GH_TOKEN", "Enter your GitHub token"))

Hotstring(":*:arceekey", (*) => SendSecretFromEnv("ARCEE_API_KEY", "Enter your ARCEE API key"))

Hotstring(":*:perplexitykey", (*) => SendSecretFromEnv("PPLX_API_KEY", "Enter your Perplexity API key"))

Hotstring(":*:mem0key", (*) => SendSecretFromEnv("MEM0_API_KEY", "Enter your Mem0 API key"))

Hotstring(":*:npmtoken", (*) => SendSecretFromEnv("NPM_TOKEN", "Enter your npm token"))

Hotstring(":*:geminikey", (*) => SendSecretFromEnv("GEMINI_API_KEY", "Enter your Google AI Studio key"))

Hotstring(":*:openpipekey", (*) => SendSecretFromEnv("OPENPIPE_API_KEY", "Enter your OpenPipe API key"))

Hotstring(":*:groqkey", (*) => SendSecretFromEnv("GROQ_API_KEY", "Enter your Groq API key"))

Hotstring(":*:OAIKey", (*) => SendSecretFromEnv("OPENAI_API_KEY", "Enter your OpenAI API key"))

Hotstring(":*:OAI2Key", (*) => SendSecretFromEnv("OPENAI_API_KEY_2", "Enter your OpenAI secondary key"))

Hotstring(":*:ClaudeKey", (*) => SendSecretFromEnv("CLAUDE_API_KEY", "Enter your Anthropic API key"))

Hotstring(":*:cloudflare-worker-key", (*) => SendSecretFromEnv("CLOUDFLARE_WORKER_KEY", "Enter your Cloudflare Worker API key"))

Hotstring(":*:zaikey", (*) => SendSecretFromEnv("ZAI_API_KEY", "Enter your ZAI API key"))
