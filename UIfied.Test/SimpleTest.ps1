Import-Module .\UIfied

$sample = {
    $wsb = {
        Get-Window -Caption "Title" -Components {
            Get-StackPannel -Orientation Vertical -Components {
                Get-Label    -Caption "Hello"
                Get-Button   -Caption "Button" -Action {
                    param($this)
                    $this.Control.Caption = Get-Date
                }
            }
        }
    }
    $h = Get-UIHost
    $h.ShowFrame($wsb)
}

Set-UIWpf
Invoke-Command -ScriptBlock $sample

Set-UICF
Invoke-Command -ScriptBlock $sample

Set-UIOoui
Invoke-Command -ScriptBlock $sample
