using namespace System.Collections.Generic

class WPFElement : UIElement {

    WPFElement() {
        $this.WrapProperty("Enable", "IsEnabled")
        Add-Member -InputObject $this -Name Visible -MemberType ScriptProperty -Value {
            $this.NativeUI.Visibility -eq [System.Windows.Visibility]::Visible
        } -SecondValue {
            if ($args[0]) {
                $this.NativeUI.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $this.NativeUI.Visibility = [System.Windows.Visibility]::Collapsed
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
    }
}

class WPFHost : UIHost {

    [void] ShowFrame([WindowBase]$window) {
        $window.ShowDialog()
    }

}

class WPFWindow : WindowBase {

    WPFWindow() {
        $windowNativeUI = [system.windows.window]::new()
        $windowNativeUI.SizeToContent = 'WidthAndHeight'
        $windowNativeUI.Margin        = 10
        $this.SetNativeUI($windowNativeUI)
        $this.WrapProperty("Caption", "Title")
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

}

class WPFStackPanel : WPFElement {

    WPFStackPanel() {
        $this.SetNativeUI([System.Windows.Controls.StackPanel]::new())
        $this.WrapProperty("Orientation", "Orientation")
    }
}

class WPFLabel : WPFElement {

    WPFLabel() {
        $this.SetNativeUI([System.Windows.Controls.Label]::new())
        $this.WrapProperty("Caption", "Content")
    }
}

class WPFButton : WPFElement {

    WPFButton() {
        $this.SetNativeUI([System.Windows.Controls.Button]::new())
        $this.WrapProperty("Caption", "Content")
        $this.AddScriptBlockProperty("Action")
        $this.NativeUI.Add_Click({ $this.Control.OnAction() })
    }

    [void] OnAction() {
        Invoke-Command -ScriptBlock $this._Action -ArgumentList $this
    }
}

class WPFTextBox : WPFElement {

    WPFTextBox() {
        $this.SetNativeUI([System.Windows.Controls.TextBox]::new())
        $this.WrapProperty("Text", "Text")
        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_TextChanged({ $this.Control.OnChange() })
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }

}

class WPFCheckBox : WPFElement {

    WPFCheckBox() {
        $this.SetNativeUI([System.Windows.Controls.CheckBox]::new())
        $this.WrapProperty("Caption", "Content")
        $this.WrapProperty("IsChecked", "IsChecked")
        $this.AddScriptBlockProperty("Click")
        $this.NativeUI.Add_Click({ $this.Control.OnClick() })
    }

    [void] OnClick() {
        Invoke-Command -ScriptBlock $this._Click -ArgumentList $this
    }

}

class WPFRadioButton : WPFElement {

    WPFRadioButton() {
        $this.SetNativeUI([System.Windows.Controls.RadioButton]::new())
        $this.WrapProperty("Caption", "Content")
        $this.WrapProperty("IsChecked", "IsChecked")
        $this.AddScriptBlockProperty("Click")
        $this.NativeUI.Add_Click({ $this.Control.OnClick() })
    }

    [void] OnClick() {
        Invoke-Command -ScriptBlock $this._Click -ArgumentList $this
    }

}

class WPFRadioGroup : WPFElement {
    hidden $StackPanel

    WPFRadioGroup() {
        $this.SetNativeUI([System.Windows.Controls.GroupBox]::new())
        $this.StackPanel = [System.Windows.Controls.StackPanel]::new()
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
        $this.SetNativeUI([System.Windows.Controls.TabItem]::new())
        $this.StackPanelNativeUI = [System.Windows.Controls.StackPanel]::new()
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
        $this.SetNativeUI([System.Windows.Controls.TabControl]::new())
    }

}
