[Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("$PSScriptRoot\Bin\Binding.dll"))
[Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("$PSScriptRoot\Bin\ConsoleFramework.dll"))
[Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("$PSScriptRoot\Bin\Xaml.dll"))

Add-Type -AssemblyName System.Drawing 
