#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode("Input")
SetWorkingDir(A_ScriptDir)

; ====================================================================
; PROMPT TRACE SYSTEM - Capture all requests/responses for dataset building
; ====================================================================

global TRACE_DIR := A_ScriptDir . "\traces"
global TRACE_ENABLED := true
global CURRENT_TRACE_SESSION := ""
global TRACE_COUNTER := 0

; Create traces directory if it doesn't exist
if (!DirExist(TRACE_DIR)) {
    DirCreate(TRACE_DIR)
}

; Initialize trace session with timestamp
CURRENT_TRACE_SESSION := Format("{:yyyyMMdd_HHmmss}", A_Now)
TraceLog("=== TRACE SESSION STARTED: " . CURRENT_TRACE_SESSION . " ===")

; ====================================================================
; PUBLIC API - Call these functions to trace prompts
; ====================================================================

; Start tracing a new prompt optimization request
; Returns: trace_id for this request
TraceStartRequest(systemPrompt, userInput, model, profile := "") {
    global TRACE_ENABLED, CURRENT_TRACE_SESSION, TRACE_COUNTER

    if (!TRACE_ENABLED) {
        return ""
    }

    TRACE_COUNTER++
    traceId := CURRENT_TRACE_SESSION . "_" . Format("{:04d}", TRACE_COUNTER)

    ; Create trace directory for this request
    requestDir := TRACE_DIR . "\" . traceId
    DirCreate(requestDir)

    ; Build request metadata
    request := {
        trace_id: traceId,
        timestamp: Format("{:yyyy-MM-dd HH:mm:ss}", A_Now),
        timestamp_unix: A_Now,
        model: model,
        profile: profile,
        system_prompt: systemPrompt,
        user_input: userInput,
        metadata: {
            session_id: CURRENT_TRACE_SESSION,
            request_number: TRACE_COUNTER,
            ahk_script: A_ScriptName,
            working_dir: A_ScriptDir,
            active_window: WinGetTitle("A"),
            clipboard_length: StrLen(A_Clipboard)
        }
    }

    ; Save request data
    SaveJson(requestDir . "\request.json", request)

    ; Save individual components for easy analysis
    SaveText(requestDir . "\system_prompt.txt", systemPrompt)
    SaveText(requestDir . "\user_input.txt", userInput)
    SaveText(requestDir . "\metadata.txt", "Model: " . model . "`nProfile: " . profile . "`nTimestamp: " . Format("{:yyyy-MM-dd HH:mm:ss}", A_Now))

    TraceLog("REQUEST START: " . traceId . " | Model: " . model . " | Profile: " . profile . " | Input length: " . StrLen(userInput))

    return traceId
}

; Complete tracing with the response from the model
TraceCompleteRequest(traceId, responseText, responseMetadata := "") {
    global TRACE_ENABLED

    if (!TRACE_ENABLED || !traceId) {
        return
    }

    requestDir := TRACE_DIR . "\" . traceId

    ; Build response metadata
    response := {
        trace_id: traceId,
        timestamp: Format("{:yyyy-MM-dd HH:mm:ss}", A_Now),
        timestamp_unix: A_Now,
        response_text: responseText,
        response_metadata: responseMetadata,
        metrics: {
            response_length: StrLen(responseText),
            response_time_ms: "",
            token_estimate: "",
            word_count: CountWords(responseText),
            line_count: CountLines(responseText)
        }
    }

    ; Save response data
    SaveJson(requestDir . "\response.json", response)
    SaveText(requestDir . "\response.txt", responseText)

    ; Create consolidated analysis file
    CreateAnalysisFile(traceId, requestDir)

    TraceLog("REQUEST COMPLETE: " . traceId . " | Response length: " . StrLen(responseText) . " | Words: " . CountWords(responseText))
}

; Trace an error or failure
TraceError(traceId, errorMessage, errorDetails := "") {
    global TRACE_ENABLED

    if (!TRACE_ENABLED) {
        return
    }

    requestDir := TRACE_DIR . "\" . traceId

    error := {
        trace_id: traceId,
        timestamp: Format("{:yyyy-MM-dd HH:mm:ss}", A_Now),
        error_message: errorMessage,
        error_details: errorDetails
    }

    SaveJson(requestDir . "\error.json", error)
    SaveText(requestDir . "\error.txt", errorMessage . (errorDetails ? "`n`n" . errorDetails : ""))

    TraceLog("ERROR: " . traceId . " | " . errorMessage)
}

; Enable/disable tracing
TraceSetEnabled(enabled) {
    global TRACE_ENABLED
    TRACE_ENABLED := enabled
    TraceLog("Tracing " . (enabled ? "ENABLED" : "DISABLED"))
}

; Get trace statistics
TraceGetStats() {
    global TRACE_DIR, CURRENT_TRACE_SESSION

    stats := {
        total_requests: 0,
        session_requests: 0,
        traces_dir: TRACE_DIR,
        current_session: CURRENT_TRACE_SESSION,
        recent_traces: []
    }

    ; Count total traces
    try {
        Loop Files, TRACE_DIR . "\*", "D" {
            if (RegExMatch(A_LoopFileName, "^\d{8}_\d{6}_\d{4}$")) {
                stats.total_requests++

                ; Check if it's from current session
                if (InStr(A_LoopFileName, CURRENT_TRACE_SESSION)) {
                    stats.session_requests++

                    ; Add to recent traces (last 10)
                    if (stats.recent_traces.Length < 10) {
                        stats.recent_traces.Push(A_LoopFileName)
                    }
                }
            }
        }
    }

    return stats
}

; Export traces for dataset creation
TraceExportDataset(format := "json") {
    global TRACE_DIR, CURRENT_TRACE_SESSION

    exportFile := TRACE_DIR . "\dataset_export_" . CURRENT_TRACE_SESSION . "." . format
    dataset := []

    ; Collect all completed requests
    try {
        Loop Files, TRACE_DIR . "\*", "D" {
            if (RegExMatch(A_LoopFileName, "^\d{8}_\d{6}_\d{4}$")) {
                traceDir := TRACE_DIR . "\" . A_LoopFileName

                ; Check if we have both request and response
                if (FileExist(traceDir . "\request.json") && FileExist(traceDir . "\response.json")) {
                    try {
                        request := LoadJson(traceDir . "\request.json")
                        response := LoadJson(traceDir . "\response.json")

                        dataset.Push({
                            trace_id: A_LoopFileName,
                            request: request,
                            response: response,
                            combined_text: request.system_prompt . "`n`n--- USER INPUT ---`n`n" . request.user_input . "`n`n--- MODEL RESPONSE ---`n`n" . response.response_text
                        })
                    }
                }
            }
        }
    }

    ; Save export
    if (format = "json") {
        SaveJson(exportFile, dataset)
    } else if (format = "csv") {
        ExportCsv(dataset, exportFile)
    } else if (format = "markdown") {
        ExportMarkdown(dataset, exportFile)
    }

    TraceLog("DATASET EXPORTED: " . dataset.Length . " traces to " . exportFile)
    return exportFile
}

; ====================================================================
; HELPER FUNCTIONS
; ====================================================================

TraceLog(message) {
    global TRACE_ENABLED, TRACE_DIR, CURRENT_TRACE_SESSION

    if (!TRACE_ENABLED) {
        return
    }

    logFile := TRACE_DIR . "\trace_log.txt"
    logEntry := Format("{:yyyy-MM-dd HH:mm:ss.fff}", A_Now) . " | " . message . "`n"

    try {
        FileAppend(logEntry, logFile, "UTF-8")
    }
}

SaveText(filePath, content) {
    try {
        FileDelete(filePath)
        FileAppend(content, filePath, "UTF-8")
    }
}

SaveJson(filePath, obj) {
    try {
        jsonText := JsonStringify(obj, 2)
        FileDelete(filePath)
        FileAppend(jsonText, filePath, "UTF-8")
    }
}

LoadJson(filePath) {
    try {
        content := FileRead(filePath, "UTF-8")
        return JsonParse(content)
    }
}

CreateAnalysisFile(traceId, requestDir) {
    try {
        request := LoadJson(requestDir . "\request.json")
        response := LoadJson(requestDir . "\response.json")

        analysis := ""
        analysis .= "# Prompt Trace Analysis: " . traceId . "`n`n"
        analysis .= "## Request Information`n"
        analysis .= "- **Timestamp**: " . request.timestamp . "`n"
        analysis .= "- **Model**: " . request.model . "`n"
        analysis .= "- **Profile**: " . request.profile . "`n"
        analysis .= "- **System Prompt Length**: " . StrLen(request.system_prompt) . " chars`n"
        analysis .= "- **User Input Length**: " . StrLen(request.user_input) . " chars`n"
        analysis .= "- **Input Word Count**: " . CountWords(request.user_input) . "`n`n"

        analysis .= "## Response Information`n"
        analysis .= "- **Response Length**: " . response.metrics.response_length . " chars`n"
        analysis .= "- **Word Count**: " . response.metrics.word_count . "`n"
        analysis .= "- **Line Count**: " . response.metrics.line_count . "`n`n"

        analysis .= "## Quality Metrics`n"
        analysis .= "- **Prompt/Response Ratio**: " . Round(StrLen(request.user_input) / response.metrics.response_length, 2) . "`n"
        analysis .= "- **Response Efficiency**: " . (response.metrics.word_count > 50 ? "Good" : "Poor") . "`n"
        analysis .= "- **Input Complexity**: " . (CountWords(request.user_input) > 20 ? "High" : "Low") . "`n`n"

        analysis .= "## Content Preview`n"
        analysis .= "**User Input (first 200 chars):**`n"
        analysis .= "````n" . SubStr(request.user_input, 1, 200) . (StrLen(request.user_input) > 200 ? "..." : "") . "`n````n`n"
        analysis .= "**Response (first 200 chars):**`n"
        analysis .= "````n" . SubStr(response.response_text, 1, 200) . (StrLen(response.response_text) > 200 ? "..." : "") . "`n````n"

        SaveText(requestDir . "\analysis.md", analysis)
    }
}

CountWords(text) {
    text := Trim(text)
    if (!text) {
        return 0
    }
    ; Simple word count - split by whitespace
    words := StrSplit(text, A_Space, A_Tab, "`n", "`r")
    count := 0
    for word in words {
        if (Trim(word) != "") {
            count++
        }
    }
    return count
}

CountLines(text) {
    if (!text) {
        return 0
    }
    lines := StrSplit(text, "`n")
    return lines.Length
}

ExportCsv(dataset, filePath) {
    csv := "trace_id,timestamp,model,profile,system_prompt_length,user_input_length,response_length,word_count,combined_text`n"

    for item in dataset {
        timestamp := item.request.timestamp
        model := item.request.model
        profile := item.request.profile
        sysLen := StrLen(item.request.system_prompt)
        userLen := StrLen(item.request.user_input)
        respLen := item.response.metrics.response_length
        wordCount := item.response.metrics.word_count
        combined := StrReplace(StrReplace(item.combined_text, "`n", " "), "`r", " ")
        combined := StrReplace(combined, '"', '""') ; Escape quotes

        csv .= '"' . item.trace_id . '","' . timestamp . '","' . model . '","' . profile . '","' . sysLen . '","' . userLen . '","' . respLen . '","' . wordCount . '","' . combined . '"`n'
    }

    SaveText(filePath, csv)
}

ExportMarkdown(dataset, filePath) {
    md := "# Prompt Optimization Dataset`n`n"
    md .= "Generated: " . Format("{:yyyy-MM-dd HH:mm:ss}", A_Now) . "`n"
    md .= "Total traces: " . dataset.Length . "`n`n"

    for item in dataset {
        md .= "## Trace: " . item.trace_id . "`n`n"
        md .= "**Metadata:**`n"
        md .= "- Timestamp: " . item.request.timestamp . "`n"
        md .= "- Model: " . item.request.model . "`n"
        md .= "- Profile: " . item.request.profile . "`n`n"

        md .= "**System Prompt:**`n"
        md .= "```markdown`n" . item.request.system_prompt . "`n```n`n"

        md .= "**User Input:**`n"
        md .= "```text`n" . item.request.user_input . "`n```n`n"

        md .= "**Model Response:**`n"
        md .= "```text`n" . item.response.response_text . "`n```n`n"

        md .= "---`n`n"
    }

    SaveText(filePath, md)
}

; ====================================================================
; HOTKEYS FOR TRACE MANAGEMENT
; ====================================================================

; Ctrl+Alt+T - Toggle tracing
^!t:: {
    global TRACE_ENABLED
    TRACE_ENABLED := !TRACE_ENABLED
    ShowTip("Prompt tracing " . (TRACE_ENABLED ? "ENABLED" . " 🔥" : "DISABLED"), 1500)
    TraceLog("Tracing toggled via hotkey: " . (TRACE_ENABLED ? "ON" : "OFF"))
}

; Ctrl+Alt+Shift+T - Show trace statistics
^!+t:: {
    stats := TraceGetStats()
    msg := "Prompt Trace Statistics`n"
    msg .= "═══════════════════════════════════`n"
    msg .= "Total Requests: " . stats.total_requests . "`n"
    msg .= "Session Requests: " . stats.session_requests . "`n"
    msg .= "Current Session: " . stats.current_session . "`n"
    msg .= "Traces Directory: " . stats.traces_dir . "`n`n"

    if (stats.recent_traces.Length > 0) {
        msg .= "Recent Traces:`n"
        for trace in stats.recent_traces {
            msg .= "• " . trace . "`n"
        }
    }

    MsgBox(msg, "Prompt Trace Statistics", "Iconi")
}

; Ctrl+Alt+Shift+E - Export current session dataset
^!+e:: {
    exportFile := TraceExportDataset("json")
    msg := "Dataset exported to:`n" . exportFile . "`n`nWould you like to open the traces folder?"

    result := MsgBox(msg, "Dataset Exported", "Iconi YesNo")
    if (result = "Yes") {
        Run('explorer "' . A_ScriptDir . '\traces"')
    }
}

; Ctrl+Alt+Shift+R - Open traces folder
^!+r:: {
    Run('explorer "' . A_ScriptDir . '\traces"')
}

; ====================================================================
; AUTO-SHUTDOWN HANDLING
; ====================================================================

; Save trace log on script exit
OnExit(TraceShutdown)

TraceShutdown(*) {
    TraceLog("=== TRACE SESSION ENDED: " . CURRENT_TRACE_SESSION . " ===")
    ExitApp()
}

; Show initial tooltip
ShowTip("Prompt Trace System Active`n🔥 Ctrl+Alt+T to toggle`n📊 Ctrl+Alt+Shift+T for stats", 3000)