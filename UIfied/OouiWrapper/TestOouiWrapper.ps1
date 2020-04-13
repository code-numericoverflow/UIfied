﻿dir $PSScriptRoot\..\bin\*.dll | ForEach-Object {
    [Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes($_))
}
 
$hostWrapper = [OouiWrapper.OouiWrapper]::new()
$hostWrapper.Publish()
Add-Member -InputObject $hostWrapper -MemberType NoteProperty -Name sb -Value {[Ooui.Button]::new("hola mundo " + [DateTime]::Now.ToString())}

Register-ObjectEvent -InputObject $hostWrapper -EventName OnPublish -MessageData $hostWrapper -Action {
    param ($hostWrapper)
    $event.MessageData.Frame = Invoke-Command -ScriptBlock $event.MessageData.sb
}
