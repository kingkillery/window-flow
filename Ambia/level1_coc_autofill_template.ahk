^+!f:: ; Ctrl+Alt+Shift+F
; === Auto-generated AHK (v1) template for: Level-1-Certificate-of-Completion (1).pdf ===
; Tab order inferred from PDF annotation order. Start with cursor in the FIRST field.
; Replace placeholders with real values. For checkboxes/radios, send {Space} when needed.

values =
(
<Name>
<Mailing_Address>
<City>
<State>
<Zip_Code>
<Contact_Person_If_other_than_Above>
<Mailing_Address_If_other_than_Above>
<Telephone_Daytime>
<Evening>
<Facsimile_Number>
<EMail_Address>
<Facility_Address>
<City>
<State_PA_Zip_Code>
<Nearest_Crossing_Street>
<Electric_Distribution_Company_EDC_Select_Utility>
<Account>
<Meter>
<Number_of_Units>
<Manufacturer>
<Model_Number_of_Inverter>
<Inverter_Rating>
<Check_if_ownerinstalled>  ; (checkbox/radio) Use {Space} to toggle
<Name>
<Mailing_Address>
<City>
<State>
<Zip_Code>
<Contact_Person_If_other_than_Above>
<Telephone_Daytime>
<Evening>
<Facsimile_Number>
<E_Mail_Address>
<Energy_Source_COC>
<Inverter_Type_COC>
<Date>
<Printed_Name>
<Title>
<Name_3>
<Mailing_Address>
<City>
<State>
<Zip_Code>
<Contact_Person_If_other_than_Above>
<Telephone_Daytime>
<Evening>
<Facsimile_Number>
<E_Mail_Address>
<Date>
<Printed_Name>
<Title>
<By>
<Date>
<Date>
<Printed_Name_1>
<Title>
<Name>
<Customer_Generator_Signature>
<Signed_Equipment_Installer>
<Electrical_Contractor_Signature>
<If_no_Successful_Witness_Test_Date>
<EDC_Signature>
<Date>
<Printed_Name>
<Title>
<WT_Yes>  ; (checkbox/radio) Use {Space} to toggle
<WT_No>  ; (checkbox/radio) Use {Space} to toggle
<Check_if_owner_installed>  ; (checkbox/radio) Use {Space} to toggle
)

SetKeyDelay, 500, 50
Loop, Parse, values, `n, `r
{
    if (A_LoopField != "")
    {
        ; If placeholder contains {Space}, send it literally, else send the text
        if InStr(A_LoopField, "{Space}")
            SendInput, {Space}
        else
            SendInput, %A_LoopField%
        Sleep, 300
    }
    SendInput, {Tab}
    Sleep, 300
}
return

^Esc::ExitApp  ; Ctrl+Esc to exit
