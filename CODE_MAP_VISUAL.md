# PromptOpt System - Visual Code Map

## Complete System Architecture

```mermaid
graph TB
    subgraph "ENTRY POINT"
        A[Template.ahk<br/>Main Orchestrator<br/>920 lines]
    end
    
    subgraph "CORE MODULES"
        B[core/environment.ahk<br/>Environment & Clipboard<br/>98 lines]
        B1[LoadDotEnv<br/>SendSecretFromEnv<br/>SendHotstringText<br/>SaveClipboard]
    end
    
    subgraph "HOTSTRING MODULES"
        C1[hotstrings/api-keys.ahk<br/>API Key Expansions<br/>41 lines]
        C2[hotstrings/general.ahk<br/>General Expansions<br/>138 lines]
        C3[hotstrings/templates.ahk<br/>Large Templates<br/>1072 lines]
        C4[hotstrings/role-task-constraint.ahk<br/>Role Template<br/>126 lines]
    end
    
    subgraph "HOTKEY MODULES"
        D1[hotkeys/mouse.ahk<br/>Mouse Remapping<br/>37 lines]
        D2[hotkeys/media.ahk<br/>Media Controls<br/>30 lines]
        D3[hotkeys/windows.ahk<br/>Window Management<br/>54 lines]
    end
    
    subgraph "PROMPTOPT SYSTEM"
        E[promptopt/promptopt.ahk<br/>AHK v2 Orchestrator<br/>997 lines]
        F[promptopt/promptopt.ps1<br/>PowerShell Bridge<br/>275 lines]
        G[promptopt/promptopt.py<br/>Python API Client<br/>306 lines]
        H[meta-prompts/<br/>Meta-Prompt Templates<br/>*.md files]
    end
    
    subgraph "EXTERNAL"
        I[Raw-to-Prompt Tool<br/>External Python Script]
        J[OpenAI/OpenRouter API<br/>Cloud Service]
    end
    
    A -->|#Include| B
    A -->|#Include| C1
    A -->|#Include| C2
    A -->|#Include| C3
    A -->|#Include| C4
    A -->|#Include| D1
    A -->|#Include| D2
    A -->|#Include| D3
    
    C1 -->|Uses| B1
    C2 -->|Uses| B1
    C3 -->|Uses| B1
    C4 -->|Uses| B1
    
    A -->|Ctrl+Alt+P| E
    E -->|Launches| F
    F -->|Loads| H
    F -->|Calls| G
    G -->|HTTP Request| J
    J -->|Response| G
    G -->|Writes| E
    E -->|Displays| E
    
    A -->|Shift+Alt+RButton| I
    
    style A fill:#ff6b6b,stroke:#c92a2a,stroke-width:3px
    style E fill:#4ecdc4,stroke:#2d9cdb,stroke-width:2px
    style F fill:#95e1d3,stroke:#2d9cdb,stroke-width:2px
    style G fill:#a8e6cf,stroke:#2d9cdb,stroke-width:2px
    style J fill:#ffeaa7,stroke:#fdcb6e,stroke-width:2px
```

## PromptOpt Execution Flow (Detailed)

```mermaid
sequenceDiagram
    participant User
    participant Template as Template.ahk
    participant PromptOptAHK as promptopt.ahk
    participant PowerShell as promptopt.ps1
    participant Python as promptopt.py
    participant API as OpenAI/OpenRouter
    participant Clipboard
    participant TempFiles as Temp Files
    
    User->>Template: Press Ctrl+Alt+P
    Template->>Template: PromptOpt_Run()
    Template->>PromptOptAHK: TryRunWithAHKv2()
    
    PromptOptAHK->>Clipboard: Copy Selection (Ctrl+C)
    Clipboard-->>PromptOptAHK: User Text
    
    PromptOptAHK->>PromptOptAHK: Validate Text Size
    PromptOptAHK->>PromptOptAHK: Get API Key (env or prompt)
    PromptOptAHK->>PromptOptAHK: PickProfile() GUI
    PromptOptAHK->>PromptOptAHK: PickModel() GUI
    
    PromptOptAHK->>TempFiles: Create tmpSel.txt
    PromptOptAHK->>TempFiles: Create tmpOut.txt
    PromptOptAHK->>TempFiles: Write selection to tmpSel.txt
    
    PromptOptAHK->>PromptOptAHK: StartStreamTip() - Live Preview
    PromptOptAHK->>PowerShell: Launch with parameters
    
    PowerShell->>PowerShell: Load .env files
    PowerShell->>PowerShell: Resolve meta-prompt file
    Note over PowerShell: meta-prompts/Meta_Prompt[.Profile].md
    PowerShell->>PowerShell: Extract META_PROMPT = """..."""
    PowerShell->>TempFiles: Write system prompt to temp file
    
    PowerShell->>Python: Call with args
    Note over Python: --system-prompt-file<br/>--user-input-file<br/>--output-file<br/>--model<br/>--base-url
    
    Python->>TempFiles: Read system prompt
    Python->>TempFiles: Read user input
    Python->>Python: Detect Provider (OpenRouter/OpenAI)
    Python->>Python: Build Chat Completions payload
    
    Python->>API: POST /chat/completions
    Note over API: Streaming or Non-Streaming
    API-->>Python: SSE Stream or JSON Response
    
    loop Streaming Mode
        Python->>TempFiles: Append chunk to tmpOut.txt
        TempFiles-->>PromptOptAHK: File updated
        PromptOptAHK->>PromptOptAHK: UpdateStreamTip() - Live Preview
    end
    
    Python-->>PowerShell: Exit Code 0
    PowerShell-->>PromptOptAHK: Process Complete
    
    PromptOptAHK->>TempFiles: Read tmpOut.txt
    TempFiles-->>PromptOptAHK: Optimized Prompt
    PromptOptAHK->>Clipboard: Copy Result
    PromptOptAHK->>PromptOptAHK: ShowResultWindow() - GUI
    PromptOptAHK->>PromptOptAHK: SoundBeep() - Success
    
    PromptOptAHK-->>User: Result Window + Clipboard
```

## PK_PROMPT Automation Flow

```mermaid
sequenceDiagram
    participant User
    participant Clipboard
    participant Template as Template.ahk
    participant PromptOptAHK as promptopt.ahk
    participant PowerShell as promptopt.ps1
    participant Python as promptopt.py
    
    User->>User: Type "PK_PROMPT <text>"
    User->>Clipboard: Copy (Ctrl+C)
    
    Clipboard->>Template: PK_HandleClipboard() Event
    Template->>Template: Check for "PK_PROMPT" prefix
    Template->>Template: Extract prompt text
    
    Template->>Template: PK_RunPromptOpt(promptText)
    Template->>Template: PK_CopyEntireFieldText()
    Template->>Template: Create temp files
    
    Template->>PromptOptAHK: Launch (same as Ctrl+Alt+P flow)
    PromptOptAHK->>PowerShell: Process
    PowerShell->>Python: API Call
    Python-->>PowerShell: Result
    PowerShell-->>PromptOptAHK: Complete
    PromptOptAHK-->>Template: PK_ProcessResult()
    
    Template->>Template: SendHotstringText() - Paste inline
    Template-->>User: Optimized prompt pasted
```

## Hotstring Expansion Flow

```mermaid
graph LR
    A[User Types Trigger] --> B{Which Module?}
    
    B -->|API Keys| C[api-keys.ahk]
    B -->|General| D[general.ahk]
    B -->|Templates| E[templates.ahk]
    B -->|Role| F[role-task-constraint.ahk]
    
    C --> G[SendSecretFromEnv<br/>Read from Environment]
    D --> H[SendHotstringText<br/>Clipboard Paste]
    E --> I[Function Builds Text<br/>SendHotstringText]
    F --> J[Function Builds Text<br/>SendHotstringText]
    
    G --> K[core/environment.ahk]
    H --> K
    I --> K
    J --> K
    
    K --> L[SaveClipboard]
    K --> M[Set Clipboard]
    K --> N[Send Ctrl+V]
    K --> O[RestoreClipboard]
    
    L --> P[Text Expanded]
    M --> P
    N --> P
    O --> P
```

## Meta-Prompt Resolution Logic

```mermaid
graph TD
    A[PowerShell Bridge] --> B{Mode?}
    
    B -->|meta| C[baseName = Meta_Prompt]
    B -->|edit| D[baseName = Meta_Prompt_Edits]
    
    C --> E{Profile Set?}
    D --> E
    
    E -->|Yes| F[Try: baseName.Profile.md]
    E -->|No| G[Try: baseName.md]
    
    F --> H{File Exists?}
    G --> H
    
    H -->|Yes| I[Extract META_PROMPT]
    H -->|No| J[Try baseName.md]
    
    J --> K{File Exists?}
    K -->|Yes| I
    K -->|No| L[Use Hardcoded Fallback]
    
    I --> M[Write to Temp File]
    L --> M
    
    M --> N[Pass to Python]
```

## Configuration & Environment Flow

```mermaid
graph TB
    A[.env File] --> B[LoadDotEnv]
    B --> C[Environment Variables]
    
    C --> D[API Keys]
    C --> E[Configuration]
    C --> F[Development Flags]
    
    D --> D1[OPENAI_API_KEY]
    D --> D2[OPENROUTER_API_KEY]
    D --> D3[PROMPTOPT_API_KEY]
    
    E --> E1[PROMPTOPT_MODE]
    E --> E2[OPENAI_MODEL]
    E --> E3[PROMPTOPT_PROFILE]
    E --> E4[PROMPTOPT_STREAM]
    E --> E5[OPENAI_BASE_URL]
    
    F --> F1[PROMPTOPT_DRYRUN]
    F --> F2[PROMPTOPT_DRYRUN_STREAM]
    
    G[config.ini<br/>%AppData%\PromptOpt] --> H[Profile Preferences]
    G --> I[Model Preferences]
    
    H --> H1[last profile]
    H --> H2[autoselect flag]
    
    I --> I1[last model global]
    I --> I2[last model per profile]
    I --> I3[autoselect flag]
```

## File Size & Complexity Overview

```mermaid
pie title Lines of Code by Component
    "Template.ahk" : 920
    "promptopt.ahk" : 997
    "templates.ahk" : 1072
    "promptopt.py" : 306
    "promptopt.ps1" : 275
    "general.ahk" : 138
    "role-task-constraint.ahk" : 126
    "environment.ahk" : 98
    "windows.ahk" : 54
    "api-keys.ahk" : 41
    "mouse.ahk" : 37
    "media.ahk" : 30
```

## Error Handling & Recovery Paths

```mermaid
graph TD
    A[Operation Starts] --> B{Error?}
    
    B -->|No| C[Success]
    B -->|Yes| D{Error Type?}
    
    D -->|Clipboard Timeout| E[Retry Copy<br/>Max 2 attempts]
    D -->|AHK v2 Missing| F[Fallback to PowerShell]
    D -->|API Failure| G[Try Fallback Model]
    D -->|File Error| H[Show Error Message]
    D -->|Python Missing| I[Show Installation Guide]
    
    E --> J{Success?}
    F --> J
    G --> J
    H --> K[Log Error]
    I --> K
    
    J -->|Yes| C
    J -->|No| K
    
    K --> L[Error Log File]
    L --> M[User Notification]
    
    style C fill:#51cf66
    style K fill:#ff6b6b
    style L fill:#ffd43b
```

## Data Flow: Clipboard & Temp Files

```mermaid
graph LR
    A[Original Clipboard] --> B[SaveClipboard]
    B --> C[Clipboard Saved State]
    
    D[Clear Clipboard] --> E[Send Ctrl+C]
    E --> F[ClipWait]
    F --> G[User Text]
    
    G --> H[Write to tmpSel.txt]
    H --> I[Process]
    
    I --> J[Write to tmpOut.txt]
    J --> K[Read Result]
    K --> L[Set Clipboard]
    L --> M[RestoreClipboard]
    M --> C
    C --> N[Original Restored]
    
    style C fill:#ffeaa7
    style G fill:#a8e6cf
    style J fill:#95e1d3
    style N fill:#51cf66
```

## Provider Detection & API Routing

```mermaid
graph TD
    A[Python API Client] --> B{Base URL Contains<br/>openrouter.ai?}
    A --> C{API Key Starts<br/>with sk-or-?}
    
    B -->|Yes| D[OpenRouter]
    C -->|Yes| D
    B -->|No| E{Check Base URL}
    C -->|No| E
    
    E -->|api.openai.com| F[OpenAI]
    E -->|Other| G[OpenAI-Compatible]
    
    D --> H[Endpoint:<br/>openrouter.ai/api/v1/chat/completions]
    F --> I[Endpoint:<br/>api.openai.com/v1/chat/completions]
    G --> J[Endpoint:<br/>base_url/chat/completions]
    
    H --> K[Add X-Title Header<br/>Add HTTP-Referer Header]
    I --> L[Standard Headers]
    J --> L
    
    K --> M[Make Request]
    L --> M
    
    style D fill:#4ecdc4
    style F fill:#95e1d3
    style G fill:#a8e6cf
```

