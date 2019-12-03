
class OouiElement : UIElement {

    OouiElement() {
        $this.WrapNegatedProperty("Enable", "IsDisabled")
        $this.WrapNegatedProperty("Visible", "IsHidden")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.NativeUI.AppendChild($element.NativeUI) | Out-Null
        }
    }
}

class OouiHost : UIHost {

    [void] ShowFrame([WindowBase]$window) {
        [Ooui.UI]::Port = 8185
        [Ooui.UI]::Publish("/Form", $window.NativeUI)
    }

}

class OouiWindow : WindowBase {

    OouiWindow() {
        $this.SetNativeUI([Ooui.Div]::new())
        $this.WrapProperty("Caption", "Title")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.NativeUI.AppendChild($element.NativeUI)
        }
    }

    [void] ShowDialog() {
    }

}

class OouiStackPanel : OouiElement {
    #Sample http://jsfiddle.net/tCnAN/

    OouiStackPanel() {
        $this.SetNativeUI([Ooui.List]::new())
        $this.NativeUI.Style.Margin    = 0
        $this.NativeUI.Style.Padding   = 0
        $this.AddProperty("Orientation")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $listItem = [Ooui.ListItem]::new()
            if ($this._Orientation -eq [Orientation]::Horizontal) {
                $listItem.Style.Display = "inline-block"
            } else {
                $listItem.Style.Display = ""
            }
            $this.NativeUI.AppendChild($listItem) | Out-Null
            $listItem.AppendChild($element.NativeUI) | Out-Null
        }
    }
}

class OouiLabel : OouiElement {

    OouiLabel() {
        $this.SetNativeUI([Ooui.Label]::new())
        $this.WrapProperty("Caption", "Text")
    }
}

class OouiButton : OouiElement {

    OouiButton() {
        $this.SetNativeUI([Ooui.Button]::new("NotSet"))
        $this.WrapProperty("Caption", "Text")
        $this.AddScriptBlockProperty("Action")
        Register-ObjectEvent -InputObject $this.NativeUI -EventName Click -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnAction()
        } | Out-Null
    }

    [void] OnAction() {
        Invoke-Command -ScriptBlock $this._Action -ArgumentList $this
    }
}

class OouiTextBox : OouiElement {

    OouiTextBox() {
        $this.SetNativeUI([Ooui.TextInput ]::new())
        $this.WrapProperty("Text", "Value")
        $this.AddScriptBlockProperty("Change")
        Register-ObjectEvent -InputObject $this.NativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnChange()
        } | Out-Null
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }
}

class OouiCheckBox : OouiElement {
    hidden [Ooui.List]  $ListNativeUI
    hidden [Ooui.Label] $LabelNativeUI
    hidden [Ooui.Input] $CheckBoxNativeUI

    OouiCheckBox() {
        $this.ListNativeUI      = [Ooui.List]::new()
        $this.LabelNativeUI     = [Ooui.Label]::new()
        $this.CheckBoxNativeUI  = [Ooui.Input]::new("CheckBox")
        $this.ListNativeUI.AppendChild($this.CheckBoxNativeUI)
        $this.ListNativeUI.AppendChild($this.LabelNativeUI)
        $this.SetNativeUI($this.ListNativeUI)
        $this.WrapProperty("Caption", "Text", "LabelNativeUI")
        $this.WrapProperty("IsChecked", "IsChecked", "CheckBoxNativeUI")
        $this.AddScriptBlockProperty("Click")
        Register-ObjectEvent -InputObject $this.CheckBoxNativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnClick()
        } | Out-Null
    }

    [void] OnClick() {
        Invoke-Command -ScriptBlock $this._Click -ArgumentList $this
    }

}

class OouiRadioButton : OouiElement {
    hidden [Ooui.List]          $ListNativeUI
    hidden [Ooui.Label]         $LabelNativeUI
    hidden [Ooui.Input]         $RadioButtonNativeUI

    OouiRadioButton() {
        $this.ListNativeUI            = [Ooui.List]::new()
        $this.LabelNativeUI           = [Ooui.Label]::new()
        $this.RadioButtonNativeUI     = [Ooui.Input]::new("Radio")
        $this.ListNativeUI.AppendChild($this.RadioButtonNativeUI)
        $this.ListNativeUI.AppendChild($this.LabelNativeUI)
        $this.SetNativeUI($this.ListNativeUI)
        $this.WrapProperty("Caption", "Text", "LabelNativeUI")
        $this.WrapProperty("IsChecked", "IsChecked", "RadioButtonNativeUI")
        $this.AddScriptBlockProperty("Click")
        Register-ObjectEvent -InputObject $this.RadioButtonNativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnClick()
        } | Out-Null
    }

    [void] OnClick() {
        Invoke-Command -ScriptBlock $this._Click -ArgumentList $this
    }

}

class OouiRadioGroup : OouiElement {
    hidden [String] $ChildName = ""

    OouiRadioGroup() {
        $this.SetNativeUI([Ooui.Div]::new())
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            if ($this.Control.ChildName -eq "") {
                if ($this.Control.Name -ne "") {
                    $this.Control.ChildName = $this.Control.Name
                } else {
                    $this.Control.ChildName = "A" + [Guid]::NewGuid().ToString()
                }
            }
            $element.RadioButtonNativeUI.Name = $this.Control.ChildName
            $this.NativeUI.AppendChild($element.NativeUI) | Out-Null
        }
    }
}
