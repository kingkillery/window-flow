---
description: Helps convert from AHK 1 to AHK 2
auto_execution_mode: 1
---

AutoHotkey Wiki
AutoHotkey Wiki
The ultimate automation scripting language for Windows
Search
 
 
 Themes 
You are hereHomeGuidesv1→2 Conversion Cheat Sheet
guides:v1_v2_cheat_sheet

AutoHotkey Wiki
Community
Editors Optimized for AutoHotkey
Guides
Hardware
Libraries
Script Showcase
User Pages
Alternatives
CloudAHK Sandbox
Should I choose v1 or v2?
 Table of Contents 
v1→2 Conversion Cheat Sheet
Converter
General
Functions
Objects
Classes
v1→2 Conversion Cheat Sheet
Converter
Attempt to convert AHKv1 syntax to AHKv2 using the AHK-v2-script-converter project.

  



General
There is no more Auto Execute section. Automatic execution starts at the top and goes around any defined hotkeys 1).
Get rid of ❌ top-level returns, add ✅ auto-execute code below hotkeys (if you want)
You no longer need the boilerplate at the top of each script. #NoEnv, SendMode Input, SetWorkingDir %A_ScriptDir%, and SetBatchLines, -1 are all defaults in v2.
Get rid of ❌ boilerplate
Legacy assignments (=) were removed.
Change ❌var = text to ✅var := "text"
Commands do not support a first comma anymore.
Change ❌Sleep, 1000 to ✅Sleep 1000.
All commands have been turned into functions. Command syntax is just a function call without parentheses (commands can be any function, even user defined ones). Consequently, plain text parameters are gone and all parameters are expressions all the time.
Change ❌MsgBox Hello to ✅MsgBox "Hello" or ✅MsgBox("Hello")
Memory is reserved using Buffer() objects not VarSetCapacity(). Buffer is an Object, which always pass by reference, so you don't pass binary data by reference anymore. VarSetStrCapacity() exists but ONLY for string optimization.
Change ❌VarSetCapacity(var, capacity, fillByte) to ✅var := Buffer(capacity, fillByte)
Ampersand (&) is no longer the "address of" operator.
Change ❌DllCall(…, "Ptr", &var) to ✅DllCall(…, "Ptr", var) (where var is a Buffer object)
Guis are fully object-oriented, distinguished by variable reference not by name.
Multi-value expressions return the last value, not the first value.
Change ❌return (varToReturn, tmp := 1234) to ✅return (tmp := 1234, varToReturn)
Single-quoted strings can contain text with double quotes. Doubling up quote marks no longer escapes quotes.
Change ❌var := "Some ""quoted"" text" to ✅var := 'Some "quoted" text' or ✅var := "Some `"quoted`" text"
Hotkeys are now functions. They do not need a return. You only need you to specify global variables that you modify.
s:: {
    global varWritable
    MsgBox "Hi " varReadable
    MsgBox "Bye " (varWritable := "Jeff")
}
Variables start as unset (which is a state, not a value). Unset variables throw when read. Unset makes a great default parameter.
Change ❌MyFunc(param1, param2 := "") {…} to ✅MyFunc(param1, param2 := unset) {…}
Change ❌if (param2 != "") to ✅if IsSet(param2)
Change ❌var := [1, , 2] to ✅var := [1, unset, 2]
Change ❌FunctionCall(required1, required2, , optional2) to ✅FunctionCall(required1, required2, unset, optional2)
Change ❌var := "" ; Empty the variable to ✅var := Unset (unless you need var to be an empty string)
New Stuff

For loops can iterate values directly. In v1, the variable i will return 1, 2, 3… this is not a problem in v2 and will return a, b c.
for v in ["a", "b", "c"]
    MsgBox v
ComCall can iterate through a virtual function table without 3 DllCalls
Functions
Functions can read Global Variables by default, but not write to them.
ByRef is now done by ampersand, and must be specified by both caller and callee.
Change ❌MyFunc(ByRef a) {…} to ✅MyFunc(&a) {…}
Change ❌result := MyFunc(a) to ✅result := MyFunc(&a)
New Stuff

First class functions are supported. So you can use MsgBox as a function reference.
execute(func) {
    func("a message")
}
execute(MsgBox)
In v1, you had to pass execute(Func("MsgBox")).

Fat arrow syntax allows easy definition of functions and function objects, so long as those functions can be written as a single return statement.
; This code:
;FAIL() {
;    MsgBox "Function Failed"
;}
; Can become:
FAIL() => MsgBox("Function failed")
 
; This code:
;SomeGlobalFunc(x) {
;    x *= 5
;    MsgBox "Times 5: " x
;    return x
;}
;FuncObj := Func("SomeGlobalFunc")
; Can become (no longer needing a global function):
FuncObj := (x) => (x *= 5, MsgBox("Times 5: " x), x)
Functions can be defined inside functions, forming Closures. Closures are like bound functions, but they bind variables by reference not value meaning they can modify enclosed variables.
closureFactory(valueToBeEnclosed) {
    myClosure(newValue := unset) {
        return IsSet(newValue) ? valueToBeEnclosed := newValue : valueToBeEnclosed
    }
    return myClosure
}
myFuncObject := closureFactory(24)
MsgBox myFuncObject()
myFuncObject(25)
MsgBox myFuncObject()
Objects
Objects now have specific sub-types, Map and Array.
Change ❌var := {"key": value} to ✅var := Map("key", value) (unless you are sure you want a basic Object not a Map)
Keep ✅var := [] or ✅var := Array() (both work)
Objects now have two key value stores, one for Properties and one for Items. The basic object only supports Properties, the Map and Array support Items in different ways. Properties should have set literal names, Items can have dynamic names, like from a variable. Properties are accessed by object.LiteralName, Items by object[variableName].
data := Map("Count", 1234)
MsgBox data.Count ; Access Property "Count" -> 1
MsgBox data["Count"] ; Access Item "Count" -> 1234
Classes
You do not use new to create a class anymore, you just call it by name.
Change ❌inst := new Class() to ✅inst := Class()
Classes create both a Global Object and a Prototype now. The global object (ClassName) holds items that are static, the prototype (ClassName.Prototype) is copied to make new instances. In v1, the global object served both purposes.
You can't mix "static" and "instance" class members anymore. Static members can only be called ClassName.Method() or ClassName.Property and instance methods can only be called instance.Method() or instance.Property. From inside a static method, this refers to the Global Object. From inside a normal method, this refers to the instance.
To create a static member, put static before its name.
class Test {
    static Property := 1234
    Property := 5768
    static Method() {
        MsgBox "Static Method: " this.Property
    }
    Method() {
        MsgBox "Instance Method: " this.Property
    }
}
Test.Method() ; Static Method: 1234
Test().Method() ; Instance Method: 5678
1) And into the static __New() of any class definitions
