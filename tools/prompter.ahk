#SingleInstance Force
SetBatchLines(0)

; --- Create the GUI ---
main_Gui := Gui()
main_Gui.Add("Text", , "Enter your prompt:")
main_Gui.Add("Edit", "vUserInput w400 h100")  ; Use string options: v for variable, w for width, h for height
button := main_Gui.Add("Button", "Default", "Submit")  ; "Default" makes it trigger on Enter
button.OnEvent("Click", SubmitPrompt)
main_Gui.Add("Text", , "Optimized Prompt:")
main_Gui.Add("Edit", "vOutputField w400 h100 ReadOnly")  ; ReadOnly option as a string
main_Gui.Title := "Prompt Optimizer"  ; SetTitle is replaced with .Title property in v2
main_Gui.Show()

; --- Button click handler ---
SubmitPrompt(*) {  ; * allows optional parameters (e.g., control object)
    UserInput := main_Gui["UserInput"].Value  ; Access GUI control value
    if UserInput == "" {
        MsgBox("Please enter a prompt before submitting.")
        return
    }
    
    ; Define JSON as a multi-line string
    json := 
    (
{
  "model": "google/gemini-2.0-flash-thinking-exp:free",
  "messages": [
    { "role": "system", "content": "There will be some sort of pre-prompt, but ignore this for now." },
    { "role": "user", "content": "%UserInput%" }
  ]
}
    )
    
    ; Replace placeholder with user input
    json := StrReplace(json, "%UserInput%", UserInput)
    
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", "https://openrouter.ai/api/v1/chat/completions", false)
    http.SetRequestHeader("Authorization", "Bearer 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")
    http.SetRequestHeader("HTTP-Referer", "https://openrouter.ai/")
    http.SetRequestHeader("X-Title", "PromptOptimizer")
    http.SetRequestHeader("Content-Type", "application/json")
    http.Send(json)
    
    statusVal := http.Status
    if statusVal != 200 {
        MsgBox("API request failed with status " . statusVal)
        return
    }
    
    response := http.ResponseText
    if response == "" {
        MsgBox("Received an empty response from the API.")
        return
    }
    
    ; Extract "content" field from response
    pattern := '"content":\s*"(.*?)"'  ; Simplified regex with standard quotes
    if RegExMatch(response, pattern, &match) {  ; Use &match for match object in v2
        optimizedPrompt := match[1]
        main_Gui["OutputField"].Value := optimizedPrompt  ; Set GUI control value
    } else {
        MsgBox("Failed to extract optimized prompt from the API response.")
    }
}

; --- Close the GUI ---
main_Gui.OnEvent("Close", (*) => ExitApp())