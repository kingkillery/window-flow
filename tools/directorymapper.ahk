; ==================================================
; Directory Map Generator (AHK v1 - Unicode Version)
; Hotkey: Ctrl+Alt+End opens the Folder Selection GUI
; Save this file as UTF-8 (with BOM) and run using the Unicode version of AHK.
; ==================================================

#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

; Global settings and output holders
global g_MaxDepth := 0        ; 0 = unlimited depth
global g_ExcludeDirs := []    ; Directories to exclude
global g_ExcludeFiles := []   ; Files to exclude (patterns)
global mapText := ""
global mermaidText := ""
global g_NodeCounter := 0
global g_IncludeFileContents := false ; Toggle to include file contents below the map

^!End::
    ; ----------------------------------------------------------
    ; Advanced Options GUI
    ; ----------------------------------------------------------
    Gui, New, , Directory Mapper
    Gui, Add, Text, x10 y10, Enter folder path or click Browse:
    Gui, Add, Edit, vFolderPath x10 y30 w400
    Gui, Add, Button, x420 y30 w80 gBrowseFolder, Browse...

    ; Advanced options group
    Gui, Add, GroupBox, x10 y70 w490 h130, Options
    Gui, Add, Text, x20 y90, Max Depth (0 = unlimited):
    Gui, Add, Edit, vMaxDepth x150 y90 w50, %g_MaxDepth%
    Gui, Add, Text, x20 y120, Exclude Directories (comma-separated):
    Gui, Add, Edit, vExcludeDirs x20 y140 w470, .git,node_modules,__pycache__
    Gui, Add, Text, x20 y170, Exclude Files (comma-separated):
    Gui, Add, Edit, vExcludeFiles x20 y190 w470, *.tmp,*.log,*.bak

    ; Output format options
    Gui, Add, GroupBox, x10 y210 w490 h80, Output Format
    Gui, Add, Radio, vOutputFormat x20 y230 Checked, Tree View
    Gui, Add, Radio, x120 y230, Mermaid Diagram
    Gui, Add, Radio, x230 y230, Both
    Gui, Add, Checkbox, vIncludeFileContents x20 y250, Include File Contents

    ; Generate Map button
    Gui, Add, Button, x10 y300 w100 h30 gGenerateMap, Generate Map
    Gui, Show, , Directory Mapper
return

BrowseFolder:
    FileSelectFolder, selectedFolder, , 3, Select a folder:
    if (selectedFolder != "")
        GuiControl,, FolderPath, %selectedFolder%
return

GenerateMap:
    Gui, Submit, NoHide
    if (FolderPath = "")
    {
        MsgBox, Please enter or select a folder path.
        return
    }

    ; Update global settings from the GUI values:
    g_MaxDepth := (MaxDepth = "" ? 0 : MaxDepth)
    g_ExcludeDirs := StrSplit(ExcludeDirs, ",")
    g_ExcludeFiles := StrSplit(ExcludeFiles, ",")
    ; Trim any extraneous spaces from each exclusion pattern
    for index, v in g_ExcludeDirs
        g_ExcludeDirs[index] := Trim(v)
    for index, v in g_ExcludeFiles
        g_ExcludeFiles[index] := Trim(v)

    g_IncludeFileContents := IncludeFileContents

    ; Reset Mermaid node counter
    g_NodeCounter := 0

    ; Generate outputs based on the output format selection
    if (OutputFormat = 1 || OutputFormat = 3)
        mapText := GenerateTreeForFolder(FolderPath, "", true, 0)
    else
        mapText := ""

    if (OutputFormat = 2 || OutputFormat = 3)
        mermaidText := "graph TD`n" . GenerateMermaidForFolder(FolderPath, "", 0)
    else
        mermaidText := ""

    ; Show results in the proper view(s)
    if (OutputFormat = 1)
        ShowTreeView(mapText, FolderPath)
    else if (OutputFormat = 2)
        ShowMermaidDiagram(mermaidText)
    else
        ShowBothViews(mapText, mermaidText, FolderPath)

    Gui, Destroy
return

ShowTreeView(mapText, folderPath) {
    Gui, New, +Resize, Directory Map - Tree View
    Gui, Font, s10, Consolas
    Gui, Add, Edit, x10 y10 w800 h600 vMapOutput ReadOnly +WantCtrlA +WantTab +Wrap +HScroll +VScroll, %mapText%
    Gui, Add, Button, x10 y620 w100 h30 gSaveMap, Save Map

    if (g_IncludeFileContents) {
        fileContents := GenerateFileContents(folderPath)
        Gui, Add, Edit, x10 y660 w800 h200 ReadOnly +WantCtrlA +WantTab +Wrap +HScroll +VScroll vContentsOutput, %fileContents%
        Gui, Add, Button, x10 y870 w100 h30 gSaveFileContents, Save Contents
    }

    Gui, Show, , Directory Map for %folderPath%
}

ShowMermaidDiagram(mermaidText) {
    htmlContent := GenerateMermaidHTML(mermaidText)
    tempFile := A_Temp "\\DirectoryMap_Mermaid.html"
    FileDelete, %tempFile%
    FileAppend, %htmlContent%, %tempFile%
    Run, file://%tempFile%
}

ShowBothViews(mapText, mermaidText, folderPath) {
    Gui, New, +Resize, Directory Map - Combined View
    Gui, Font, s10, Consolas

    Gui, Add, Edit, x10 y10 w800 h300 vMapOutput ReadOnly +WantCtrlA +WantTab +Wrap +HScroll +VScroll, %mapText%
    htmlContent := GenerateMermaidHTML(mermaidText)
    tempFile := A_Temp "\\DirectoryMap_Mermaid.html"
    FileDelete, %tempFile%
    FileAppend, %htmlContent%, %tempFile%
    Gui, Add, ActiveX, x10 y320 w800 h300 vWB, Shell.Explorer
    WB.Navigate("file://" . tempFile)
    Gui, Add, Button, x10 y630 w100 h30 gSaveMap, Save Map

    if (g_IncludeFileContents) {
        fileContents := GenerateFileContents(folderPath)
        Gui, Add, Edit, x10 y670 w800 h200 ReadOnly +WantCtrlA +WantTab +Wrap +HScroll +VScroll vContentsOutput, %fileContents%
        Gui, Add, Button, x10 y880 w100 h30 gSaveFileContents, Save Contents
    }

    Gui, Show, , Directory Map for %folderPath%
}

GenerateMermaidHTML(mermaidText) {
    ; Use a multiline string to avoid syntax issues
    html =
    (LTrim
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@9.4.3/dist/mermaid.min.js"></script>
  <style>
    body { margin: 20px; background: white; }
    .mermaid { font-family: Arial, sans-serif; }
  </style>
</head>
<body>
  <div class="mermaid">
MERMAID_PLACEHOLDER
  </div>
  <script>
    mermaid.initialize({
      startOnLoad: true,
      theme: "forest",
      flowchart: { curve: "linear", htmlLabels: true, useMaxWidth: true },
      securityLevel: "loose"
    });
  </script>
</body>
</html>
    )

    ; Insert the mermaid diagram text
    StringReplace, html, html, MERMAID_PLACEHOLDER, %mermaidText%
    return html
}

SaveMap:
    FileSelectFile, filePath, S16, , Save Directory Map, Tree Files (*.txt)|*.txt|Mermaid Diagram (*.mmd)|*.mmd
    if (filePath = "")
        return
    if (RegExMatch(filePath, "\\.mmd$"))
        output := mermaidText
    else
        output := mapText
    FileDelete, %filePath%
    FileAppend, %output%, %filePath%
    MsgBox, Map saved to:`n%filePath%
return

SaveFileContents:
    fileContents := GenerateFileContents(FolderPath)
    FileSelectFile, filePath, S16, , Save File Contents, Text Files (*.txt)|*.txt
    if (filePath = "")
        return
    FileDelete, %filePath%
    FileAppend, %fileContents%, %filePath%
    MsgBox, File contents saved to:`n%filePath%
return

GuiClose:
    Gui, Destroy
return

; --------------------------------------------------
; Helper function to sanitize text for Mermaid labels.
; --------------------------------------------------
EscapeMermaidLabel(text) {
    StringReplace, text, text, [, ［, All
    StringReplace, text, text, ], ］, All
    StringReplace, text, text, (, （, All
    StringReplace, text, text, ), ）, All
    StringReplace, text, text, {, ｛, All
    StringReplace, text, text, }, ｝, All
    StringReplace, text, text, &, &amp;, All
    StringReplace, text, text, <, &lt;, All
    StringReplace, text, text, >, &gt;, All
    if (InStr(text, ".") && !RegExMatch(text, "\\.([^\\.]*)$"))
        StringReplace, text, text, ., ․, All
    StringReplace, text, text, ", &quot;, All
    return text
}

; --------------------------------------------------
; Wildcard match function (case-insensitive)
; --------------------------------------------------
WildcardMatch(str, pat) {
    pat := RegExReplace(Trim(pat), "([\\.+?$$(){}^$|$])", "\\$1")
    pat := StrReplace(pat, "*", ".*")
    pat := StrReplace(pat, "?", ".")
    regex := "^" . pat . "$"
    return RegExMatch(str, regex)
}

; --------------------------------------------------
; Generate tree-format map (text) recursively.
; --------------------------------------------------
GenerateTreeForFolder(dir, indent="", isLast=true, depth=0) {
    if (g_MaxDepth > 0 && depth >= g_MaxDepth)
        return ""

    SplitPath, dir, folderName
    for index, ex in g_ExcludeDirs {
        if (folderName = ex)
            return ""
    }

    output := ""
    if (indent = "")
        output := folderName . "`r`n"
    else {
        branch := isLast ? "└── " : "├── "
        output := indent . branch . folderName . "`r`n"
    }
    newIndent := indent . (isLast ? "    " : "│   ")
    children := []

    Loop, Files, %dir%\\*, D
    {
        SplitPath, A_LoopFileFullPath, childName
        skipDir := false
        for index, ex in g_ExcludeDirs {
            if (childName = ex) {
                skipDir := true
                break
            }
        }
        if (!skipDir)
            children.Push({type:"D", path: A_LoopFileFullPath, name: childName})
    }
    Loop, Files, %dir%\\*, F
    {
        skipFile := false
        for index, ex in g_ExcludeFiles {
            if (WildcardMatch(A_LoopFileName, ex)) {
                skipFile := true
                break
            }
        }
        if (!skipFile)
            children.Push({type:"F", name: A_LoopFileName})
    }

    totalChildren := children.Length()
    loopIndex := 1
    for index, child in children {
        childIsLast := (loopIndex = totalChildren)
        if (child.type = "D")
            output .= GenerateTreeForFolder(child.path, newIndent, childIsLast, depth+1)
        else {
            branch := childIsLast ? "└── " : "├── "
            output .= newIndent . branch . child.name . "`r`n"
        }
        loopIndex++
    }
    return output
}

; --------------------------------------------------
; Generate Mermaid diagram recursively.
; --------------------------------------------------
GenerateMermaidForFolder(dir, parentId="", depth=0) {
    if (g_MaxDepth > 0 && depth >= g_MaxDepth)
        return ""

    SplitPath, dir, folderName
    for index, ex in g_ExcludeDirs {
        if (folderName = ex)
            return ""
    }
    folderName := EscapeMermaidLabel(folderName)
    global g_NodeCounter
    g_NodeCounter++
    thisId := "node" . g_NodeCounter
    output := ""

    if (parentId != "")
        output .= parentId . " --> " . thisId . "[" . folderName . "]`n"
    else
        output .= thisId . "[" . folderName . "]`n"

    children := []
    Loop, Files, %dir%\\*, D
    {
        SplitPath, A_LoopFileFullPath, childName
        skipDir := false
        for index, ex in g_ExcludeDirs {
            if (childName = ex) {
                skipDir := true
                break
            }
        }
        if (!skipDir)
            children.Push({type:"D", path: A_LoopFileFullPath, name: childName})
    }
    Loop, Files, %dir%\\*, F
    {
        skipFile := false
        for index, ex in g_ExcludeFiles {
            if (WildcardMatch(A_LoopFileName, ex)) {
                skipFile := true
                break
            }
        }
        if (!skipFile)
            children.Push({type:"F", name: A_LoopFileName})
    }

    for index, child in children {
        if (child.type = "D")
            output .= GenerateMermaidForFolder(child.path, thisId, depth+1)
        else {
            global g_NodeCounter
            g_NodeCounter++
            fileId := "node" . g_NodeCounter
            fileName := EscapeMermaidLabel(child.name)
            output .= thisId . " --> " . fileId . "[" . fileName . "]`n"
        }
    }
    return output
}

; --------------------------------------------------
; Generate file contents (for non-excluded files)
; --------------------------------------------------
GenerateFileContents(folderPath) {
    contentsOutput := "=== File Contents ===`r`n"

    Loop, Files, %folderPath%\\*, FR
    {
        skipFile := false
        for index, ex in g_ExcludeFiles {
            if (WildcardMatch(A_LoopFileName, ex)) {
                skipFile := true
                break
            }
        }
        if (!skipFile)
        {
            contentsOutput .= "`r`n--- " . A_LoopFileName . " ---`r`n"
            FileRead, thisFileContents, %A_LoopFileFullPath%
            contentsOutput .= thisFileContents . "`r`n"
        }
    }
    return contentsOutput
}
