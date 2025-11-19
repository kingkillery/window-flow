#Requires AutoHotkey v2.0

; Test basic syntax from templates.ahk
test_function() {
    text := ""
    text .= "# Usage: const sections = parseIniTsv(blockString); sections[``"IMPLEMENT v1``"] => string[][]`n"
    text .= "{}" . "`n"
    text .= Chr(34) . "test" . Chr(34) . ": " . Chr(34) . "value" . Chr(34) . "`n"
    return text
}

; Test hotstring syntax
Hotstring(":*:testtrigger", (*) => SendHotstringText(test_function()))

MsgBox("Syntax test completed successfully!")