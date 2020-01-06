using namespace System.Collections.Generic
using namespace ConsoleFramework
using namespace ConsoleFramework.Controls

class CFElement : UIElement {

    CFElement() {
        $this.WrapNegatedProperty("Enable", "Disabled")
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
        $this.RemoveNativeUIChild = {
            param (
                [CFElement] $element
            )
            $this.NativeUI.xChildren.Remove($element.NativeUI)
        }
        $this.ShowError = {
            param (
                [Object] $errorObject
            )
            [MessageBox]::Show("Error", $errorObject, $null)
        }
    }
}

class CFHost : UIHost {

    [void] ShowFrame([ScriptBlock] $frameScriptBlock) {
        $window = Invoke-Command $frameScriptBlock
        $Global:SyncHash = [HashTable]::Synchronized(@{
            Window = $window
            Errors = @()
        })
        $winhost = [WindowsHost]::new()
        $winhost.Show($window.NativeUI)
        [ConsoleFramework.ConsoleApplication]::Instance.run($winhost)
    }

}

class CFWindow : WindowBase {

    CFWindow() {
        $this.SetNativeUI([Window]::new())
        $this.WrapProperty("Caption", "Title")
        $this.AddScriptBlockProperty("Loaded")
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

    [void] OnLoaded() {
        Invoke-Command -ScriptBlock $this._Loaded -ArgumentList $this
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
        $this.InvokeTrappableCommand($this._Action, $this)
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
        $this.InvokeTrappableCommand($this._Change, $this)
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
        $this.InvokeTrappableCommand($this._Click, $this)
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
        $this.InvokeTrappableCommand($this._Click, $this)
    }

}

class CFRadioGroup : CFElement {

    CFRadioGroup() {
        $this.SetNativeUI([RadioGroup]::new())
    }

}

class CFList : CFStackPanel {
    [List[ListItem]] $Items = [List[ListItem]]::new()

    CFList() {
        $this.Orientation   = [Orientation]::Horizontal
    }

    [void] AddColumn([CFListColumn] $listColumn) {
        $column = [CFStackPanel]::new()
        $column.Orientation           = [Orientation]::Vertical
        $column.NativeUI.Margin       = [Core.Thickness]::new(1, 1, 0, 1)
        $title = [CFLabel]::new()
        $title.Caption = $listColumn.Title
        $column.AddChild($title)
        $this.AddChild($column)
    }

    [void] AddItem([ListItem] $listItem) {
        $this.Items.Add($listItem)
        $columnIndex = 0
        $this.Children | ForEach-Object {
            $column = $_
            $cell = $listItem.Children.Item($columnIndex)
            $column.AddChild($cell)
            $columnIndex++
        }
    }

    [void] RemoveItem([ListItem] $listItem) {
        $this.Items.Remove($listItem)
        $columnIndex = 0
        $this.Children | ForEach-Object {
            $column = $_
            $cell = $listItem.Children.Item($columnIndex)
            $column.RemoveChild($cell)
            $columnIndex++
        }
    }

}

class CFListColumn {
    [String] $Name
    [String] $Title
}

class CFTabItem : CFElement {
    [String] $Caption   = ""

    CFTabItem() {
        $this.SetNativeUI([Panel]::new())
    }

}

class CFTabControl : CFElement {

    CFTabControl() {
        $this.SetNativeUI([TabControl]::new())
        $this.AddNativeUIChild = {
            param (
                [CFElement] $element
            )
            $tabDefinition = [TabDefinition]::new()
            $tabDefinition.Title = $element.Caption
            $this.NativeUI.TabDefinitions.Add($tabDefinition)
            $this.NativeUI.Controls.Add($element.NativeUI)
        }
    }

}

class CFModal : CFElement {
    $Window

    CFModal() {
        $this.Window = [Window]::new()
        $this.SetNativeUI([Panel]::new())
        #$this.WrapProperty("Caption", "Title")
        $this.AddNativeUIChild = {
            param (
                [CFElement] $element
            )
            $this.Window.Content = $element.NativeUI
        }
    }

    [void] Show() {
        [WindowsHost] $windowsHost = [WindowsHost] [ConsoleFramework.ConsoleApplication]::Instance.RootControl
        $windowsHost.ShowModal($this.Window)
    }

    [void] Hide() {
        $this.Window.Close()
    }

}

class CFTimer : CFElement {
    [System.Timers.Timer] $Timer
    [Double] $Interval = 1000
    
    CFTimer() {
        $label = [TextBlock]::new()
        $label.Visibility = [Visibility]::Collapsed
        $this.SetNativeUI($label)
        $this.AddScriptBlockProperty("Elapsed")
        $this.Timer = New-Object System.Timers.Timer
        Register-ObjectEvent -InputObject $this.Timer -EventName Elapsed -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnElapsed()
        }
    }

    [void] OnElapsed() {
        Invoke-Command -ScriptBlock $this._Elapsed -ArgumentList $this
    }
    
    [void] Start() {
        $this.Timer.Interval = $this.Interval
        $this.Timer.Start()
    }

    [void] Stop() {
        $this.Timer.Stop()
    }
}

class CFDatePicker : CFElement {

    CFDatePicker() {
        $textBox = [TextBox]::new()
        $textBox.Size = 10
        $textBox.MaxLenght = 10
        $this.SetNativeUI($textBox)
        Add-Member -InputObject $this -Name Value -MemberType ScriptProperty -Value {
            $this.GetTextDateTime()
        } -SecondValue {
            $this.NativeUI.Text = $args[0].ToShortDateString()
        }
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
        $this.AddScriptBlockProperty("LostFocus")
        $this.NativeUI.Add_LostKeyboardFocus({
            param (
                $sender,
                $eventArgs
            )
            $this.Control.OnLostFocus()
        })
    }

    [void] OnChange() {
        $this.InvokeTrappableCommand($this._Change, $this)
    }

    [void] OnLostFocus() {
        $this.Value = $this.GetTextDateTime()
        $this.InvokeTrappableCommand($this._LostFocus, $this)
    }

    hidden [DateTime] GetTextDateTime() {
        [DateTime] $dateTime = [DateTime]::Today
        if (-not [DateTime]::TryParse($this.NativeUI.Text, [ref] $dateTime)) {
            return [DateTime]::Today
        } else {
            return $dateTime
        }
    }

}

class CFTimePicker : CFElement {

    CFTimePicker() {
        $textBox = [TextBox]::new()
        $textBox.Size = 5
        $textBox.MaxLenght = 5
        $this.SetNativeUI($textBox)
        Add-Member -InputObject $this -Name Value -MemberType ScriptProperty -Value {
            $this.GetTextTime()
        } -SecondValue {
            $this.NativeUI.Text = $args[0]
        }
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
        $this.AddScriptBlockProperty("LostFocus")
        $this.NativeUI.Add_LostKeyboardFocus({
            param (
                $sender,
                $eventArgs
            )
            $this.Control.OnLostFocus()
        })
    }

    [void] OnChange() {
        $this.InvokeTrappableCommand($this._Change, $this)
    }

    [void] OnLostFocus() {
        $this.Value = $this.GetTextTime()
        $this.InvokeTrappableCommand($this._LostFocus, $this)
    }

    hidden [String] GetTextTime() {
        [DateTime] $dateTime = [DateTime]::Today
        if (-not [DateTime]::TryParse("2000-01-01 " + $this.NativeUI.Text, [ref] $dateTime)) {
            return "00:00"
        } else {
            return $dateTime.ToShortTimeString()
        }
    }

}
