using namespace ConsoleFramework
using namespace ConsoleFramework.Controls

class CFElement : UIElement {

    CFElement() {
        $this.WrapProperty("Enable", "Focusable")
        Add-Member -InputObject $this -Name Visible -MemberType ScriptProperty -Value {
            $this.NativeUI.Visibility -eq [Visibility]::Visible
        } -SecondValue {
            if ($args[0]) {
                $this.NativeUI.Visibility = [Visibility]::Visible
            } else {
                $this.NativeUI.Visibility = [Visibility]::Collapsed
            }
        }
        $this.AddNativeUIChild = {
            param (
                [CFElement] $element
            )
            $this.NativeUI.xChildren.Add($element.NativeUI)
        }
    }
}

class CFHost : UIHost {

    [void] ShowFrame([WindowBase]$window) {
        $winhost = [WindowsHost]::new()
        $winhost.Show($window.NativeUI)
        [ConsoleFramework.ConsoleApplication]::Instance.run($winhost)
    }

}

class CFWindow : WindowBase {

    CFWindow() {
        $this.SetNativeUI([Window]::new())
        $this.WrapProperty("Caption", "Title")
        $this.AddNativeUIChild = {
            param (
                [CFElement] $element
            )
            $this.NativeUI.Content = $element.NativeUI
            $this.NativeUI.Created()
        }
    }
    
    [void] ShowDialog() {
    }

}

class CFStackPanel : CFElement {

    CFStackPanel() {
        $this.SetNativeUI([Panel]::new())
        $this.WrapProperty("Orientation", "Orientation")
    }
}

class CFLabel : CFElement {

    CFLabel() {
        $this.SetNativeUI([TextBlock]::new())
        $this.WrapProperty("Caption", "Text")
    }
}

class CFButton : CFElement {

    CFButton() {
        $this.SetNativeUI([Button]::new())
        $this.WrapProperty("Caption", "Caption")
        $this.AddScriptBlockProperty("Action")
        $this.NativeUI.Add_OnClick({ $this.Control.OnAction() })
    }

    [void] OnAction() {
        Invoke-Command -ScriptBlock $this._Action -ArgumentList $this
    }
}

class CFTextBox : CFElement {

    CFTextBox() {
        $this.SetNativeUI([TextBox]::new())
        $this.NativeUI.Size = 10
        $this.WrapProperty("Text", "Text")
        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_PropertyChanged({
            param (
                [System.Object] $sender, 
                [System.ComponentModel.PropertyChangedEventArgs] $eventArgs
            )
            if ($this.Control.NativeUI.HasFocus -and $eventArgs.PropertyName -eq "Text") {
                $this.Control.OnChange()
            }
        })
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }

}

class CFCheckBox : CFElement {

    CFCheckBox() {
        $this.SetNativeUI([CheckBox]::new())
        $this.WrapProperty("Caption", "Caption")
        $this.WrapProperty("IsChecked", "Checked")
        $this.AddScriptBlockProperty("Click")
        $this.NativeUI.Add_OnClick({ $this.Control.OnClick() })
    }

    [void] OnClick() {
        Invoke-Command -ScriptBlock $this._Click -ArgumentList $this
    }

}

class CFRadioButton : CFElement {

    CFRadioButton() {
        $this.SetNativeUI([RadioButton]::new())
        $this.WrapProperty("Caption", "Caption")
        $this.WrapProperty("IsChecked", "Checked")
        $this.AddScriptBlockProperty("Click")
        $this.NativeUI.Add_OnClick({ $this.Control.OnClick() })
    }

    [void] OnClick() {
        Invoke-Command -ScriptBlock $this._Click -ArgumentList $this
    }

}

class CFRadioGroup : CFElement {

    CFRadioGroup() {
        $this.SetNativeUI([RadioGroup]::new())
    }

}

class CFList : CFStackPanel {
    $Columns
    $Items

    CFList() {
        $this.Orientation   = [Orientation]::Horizontal
        $this.Columns       = @()
        $this.Items         = @()
    }

    [void] AddColumn([CFListColumn] $listColumn) {
        $this.Columns += $listColumn
    }

    [void] AddItem([ListItem] $listItem) {
        $this.Items += $listItem
    }

    [void] RemoveItem([ListItem] $listItem) {
        $this.Items -= $listItem
    }

    [void] Refresh() {
        $columnIndex = 0
        $this.Columns | ForEach-Object {
            $column = [CFStackPanel]::new()
            $column.Orientation           = [Orientation]::Vertical
            $column.NativeUI.Margin       = [Core.Thickness]::new(1, 1, 0, 1)
            $this.Items | ForEach-Object {
                $cell = $_.Children.Item($columnIndex)
                $column.AddChild($cell)
            }
            $this.AddChild($column)
            $columnIndex++
        }
    }
}

class CFListColumn {
    [String] $Name
    [String] $Title
    [Type]   $Type
}

