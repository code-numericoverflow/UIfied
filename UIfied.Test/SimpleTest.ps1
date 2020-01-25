Import-Module UIfied

$sample = {
    $wsb = {
        UIWindow -Caption "Title" -Components {
            UIStackPannel -Orientation Vertical -Components {
                UILabel    -Caption "Hello"
                UIButton   -Caption "Button" -Action {
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

#Set-UICF
#Invoke-Command -ScriptBlock $sample
#
#Set-UIOoui
#Invoke-Command -ScriptBlock $sample
