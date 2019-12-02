#using module ..\UIfied
#using module ..\UIfied.Wpf

Import-Module "$PSScriptRoot\..\UIfied"

Set-UICf

$w = Get-Window -Caption "titulo" -Components {
    Get-StackPannel -Orientation Vertical -Components {
        Get-Label    -Caption "Hola"
        Get-Button   -Caption "boton"    -Action {
            param($this)
            $this.Form.MyButton.Caption = Get-Date
        }
        Get-Label    -Caption "Adios"
        Get-Button   -Caption "boton2"  -Name MyButton -Action {
            param($this)
            $this.Form.Caption = Get-Date
        }
        Get-Label    -Caption "TextBox"
        Get-TextBox  -Change {
            param($this)
            $this.Form.MyButton.Caption = $this.Control.Text
        }
        Get-CheckBox -Caption "CheckBox" -Click {
            param($this)
            $this.Form.MyButton.Caption = $this.Control.IsChecked
        }
        Get-RadioGroup -Components {
            Get-RadioButton -Caption "RadioButton 1" -Click {
                param($this)
                $this.Form.MyButton.Caption = $this.Control.IsChecked
            }
            Get-RadioButton -Caption "RadioButton 2" -Click {
                param($this)
                $this.Form.MyButton.Caption = Get-Date
            }
        }
        #Get-List -Columns {
        #    Get-ListColumn -Title "Columna 1"
        #    Get-ListColumn -Title "Columna 2"
        #} -Items {
        #    Get-ListItem -Components {
        #        Get-Label -Caption "Hola 1,1"
        #        Get-CheckBox -Caption "Hola 1,2"
        #    }
        #    Get-ListItem -Components {
        #        Get-Label -Caption "Hola 2,1"
        #        Get-CheckBox -Caption "Hola 2,2"
        #    }
        #    Get-ListItem -Components {
        #        Get-Label -Caption "Hola 3,1"
        #        Get-CheckBox -Caption "Hola 3,2"
        #    }
        #}

    }
}
pause
$h = Get-Host
$h.ShowFrame($w)

