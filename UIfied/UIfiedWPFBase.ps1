using namespace System.Collections.Generic
using namespace System.Windows
using namespace System.Windows.Controls

class WPFElement : UIElement {

    WPFElement() {
        $this.WrapProperty("Enable", "IsEnabled")
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
                [WPFElement] $element
            )
            $this.NativeUI.AddChild($element.NativeUI) | Out-Null
        }
        $this.RemoveNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.NativeUI.Children.Remove($element.NativeUI) | Out-Null
        }
        $this.ShowError = {
            param (
                [Object] $errorObject
            )
            [MessageBox]::Show($errorObject)
        }
    }

}

class WPFHost : UIHost {
    [HashTable]  $SyncHash
                 $UIRunspace

    [void] ShowFrame([ScriptBlock] $frameScriptBlock) {
        $this.SyncHash = [HashTable]::Synchronized(@{})
        $this.SyncHash.Errors = @()
        $this.UIRunspace =[RunspaceFactory]::CreateRunspace()
        $this.UIRunspace.Name = "UIRunspace"
        $this.UIRunspace.ApartmentState = "STA"
        $this.UIRunspace.ThreadOptions = "ReuseThread"         
        $this.UIRunspace.Open()
        $this.UIRunspace.SessionStateProxy.SetVariable("SyncHash", $this.SyncHash)
        $referenceScript = "
            Import-Module ""$PSScriptRoot\..\UIfied""
            Set-UIWpf
        "
        $ps = [PowerShell]::Create()
        $ps = $ps.AddScript($referenceScript)
        $script = [ScriptBlock]::Create("`$SyncHash.Window = " + $frameScriptBlock.ToString() + "; `$SyncHash.Window.ShowDialog()")
        $ps = $ps.AddScript($script)
        $ps.Runspace = $this.UIRunspace
        $ps.BeginInvoke() | Out-Null
    }

}

class WPFWindow : WindowBase {

    WPFWindow() {
        $windowNativeUI = [Window]::new()
        $windowNativeUI.SizeToContent = 'WidthAndHeight'
        $windowNativeUI.Margin        = 10
        $this.SetNativeUI($windowNativeUI)
        $this.WrapProperty("Caption", "Title")
        $this.AddScriptBlockProperty("Loaded")
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.NativeUI.Content = $element.NativeUI
        }
    }

    [void] ShowDialog() {
        $this.NativeUI.ShowDialog()
    }

    [void] OnLoaded() {
        Invoke-Command -ScriptBlock $this._Loaded -ArgumentList $this
    }

}

class WPFStackPanel : WPFElement {

    WPFStackPanel() {
        $this.SetNativeUI([StackPanel]::new())
        $this.WrapProperty("Orientation", "Orientation")
    }
}

class WPFLabel : WPFElement {

    WPFLabel() {
        $this.SetNativeUI([Label]::new())
        $this.WrapProperty("Caption", "Content")
    }
}

class WPFButton : WPFElement {

    WPFButton() {
        $this.SetNativeUI([Button]::new())
        $this.WrapProperty("Caption", "Content")
        $this.AddScriptBlockProperty("Action")
        $this.NativeUI.Add_Click({ $this.Control.OnAction() })
    }

    [void] OnAction() {
        $this.InvokeTrappableCommand($this._Action, $this)
    }
}

class WPFTextBox : WPFElement {

    WPFTextBox() {
        $this.SetNativeUI([TextBox]::new())
        $this.WrapProperty("Text", "Text")
        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_TextChanged({ $this.Control.OnChange() })
    }

    [void] OnChange() {
        $this.InvokeTrappableCommand($this._Change, $this)
    }

}

class WPFCheckBox : WPFElement {

    WPFCheckBox() {
        $this.SetNativeUI([CheckBox]::new())
        $this.WrapProperty("Caption", "Content")
        $this.WrapProperty("IsChecked", "IsChecked")
        $this.AddScriptBlockProperty("Click")
        $this.NativeUI.Add_Click({ $this.Control.OnClick() })
    }

    [void] OnClick() {
        $this.InvokeTrappableCommand($this._Click, $this)
    }

}

class WPFRadioButton : WPFElement {

    WPFRadioButton() {
        $this.SetNativeUI([RadioButton]::new())
        $this.WrapProperty("Caption", "Content")
        $this.WrapProperty("IsChecked", "IsChecked")
        $this.AddScriptBlockProperty("Click")
        $this.NativeUI.Add_Click({ $this.Control.OnClick() })
    }

    [void] OnClick() {
        $this.InvokeTrappableCommand($this._Click, $this)
    }

}

class WPFRadioGroup : WPFElement {
    hidden $StackPanel

    WPFRadioGroup() {
        $this.SetNativeUI([GroupBox]::new())
        $this.StackPanel = [StackPanel]::new()
        $this.NativeUI.Content = $this.StackPanel
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.StackPanel.AddChild($element.NativeUI)
        }
    }

}

class WPFList : WPFStackPanel {
    [List[ListItem]] $Items = [List[ListItem]]::new()

    WPFList() {
        $this.Orientation   = [Orientation]::Horizontal
    }

    [void] AddColumn([WPFListColumn] $listColumn) {
        $column = [WPFStackPanel]::new()
        $column.Orientation           = [Orientation]::Vertical
        $title = [WPFLabel]::new()
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
            $cell.NativeUI.Height = 25
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

class WPFListColumn {
    [String] $Name
    [String] $Title
}

class WPFTabItem : WPFElement {
    hidden $StackPanelNativeUI

    WPFTabItem() {
        $this.SetNativeUI([TabItem]::new())
        $this.StackPanelNativeUI = [StackPanel]::new()
        $this.NativeUI.Content = $this.StackPanelNativeUI
        $this.WrapProperty("Caption", "Header")
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.StackPanelNativeUI.AddChild($element.NativeUI) | Out-Null
        }
    }

}

class WPFTabControl : WPFElement {

    WPFTabControl() {
        $this.SetNativeUI([TabControl]::new())
    }

}
  
class WPFModal : WPFElement {

    WPFModal() {
        $windowNativeUI = [Window]::new()
        $windowNativeUI.WindowStyle = [WindowStyle]::None
        $windowNativeUI.SizeToContent = 'WidthAndHeight'
        $windowNativeUI.Margin        = 10
        $this.SetNativeUI($windowNativeUI)
        #$this.WrapProperty("Caption", "Title")
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.NativeUI.Content = $element.NativeUI
        }
    }

    [void] Show() {
        $this.NativeUI.WindowStartupLocation = "CenterOwner"
        $this.NativeUI.ShowDialog()
    }

    [void] Hide() {
        $this.NativeUI.Hide()
    }
}

class WPFTimer : WPFElement {
    [System.Windows.Threading.DispatcherTimer] $Timer
    [Double] $Interval = 1000
    
    WPFTimer () {
        $label = [Label]::new()
        $label.Visibility = [Visibility]::Collapsed
        $this.SetNativeUI($label)
        $this.AddScriptBlockProperty("Elapsed")
        $this.Timer = New-Object System.Windows.Threading.DispatcherTimer
        Add-Member -InputObject $this.Timer -MemberType NoteProperty -Name Control -Value $this
        $this.Timer.Add_Tick({
            $this.Control.OnElapsed()
            #[System.Windows.Input.CommandManager]::InvalidateRequerySuggested()
        })
    }

    [void] OnElapsed() {
        Invoke-Command -ScriptBlock $this._Elapsed -ArgumentList $this
    }
    
    [void] Start() {
        $this.Timer.Interval = [TimeSpan]::FromSeconds($this.Interval / 1000)
        $this.Timer.Start()
    }

    [void] Stop() {
        $this.Timer.Stop()
    }
}
