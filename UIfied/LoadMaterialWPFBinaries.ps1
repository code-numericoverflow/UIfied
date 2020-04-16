Add-Type -AssemblyName PresentationFramework
[Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("$PSScriptRoot\Bin\MaterialDesignColors.dll"))
[Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("$PSScriptRoot\Bin\MaterialDesignThemes.Wpf.dll"))