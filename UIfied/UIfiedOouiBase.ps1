using namespace System.Collections.Generic
using namespace Ooui

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
        $this.RemoveNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.NativeUI.RemoveChild($element.NativeUI) | Out-Null
        }
    }
}

class OouiHost : UIHost {
    $Shared         = $true
    $Port           = 8185
    $CreateElement

    [void] ShowFrame([ScriptBlock] $frameScriptBlock) {
        #$Global:SyncHash = [HashTable]::Synchronized(@{
        #    Window = $null
        #    Errors = @()
        #})

        $this.CreateElement = $frameScriptBlock
        if ($this.Shared) {
            $this.ShowSharedFrame()
        } else {
            $this.ShowNotSharedFrame()
        }
    }

    [void] ShowSharedFrame() {
        $frame = Invoke-Command -ScriptBlock $this.CreateElement
        [UI]::Port = $this.Port
        [UI]::Publish("/Form", $frame.NativeUI)
    }

    [void] ShowNotSharedFrame() {
        $notSharedForm = [NotSharedForm]::new()
        $notSharedForm.CreateElement = $this.CreateElement
        [UI]::Port = $this.Port
        [UI]::Publish("/Form", $notSharedForm)
    }
}

class NotSharedForm : Div {
    [Anchor]    $Anchor
    $CreateElement

    NotSharedForm() {
        $this.Anchor = [Anchor]::new()
        $this.Anchor.Text = "Go to Not Shared Form"
        $this.AppendChild($this.Anchor) | Out-Null

        Register-ObjectEvent -InputObject $this.Anchor -EventName Click -MessageData $this -Action {
            $this = $event.MessageData

            $notSharedForm = [NotSharedForm]::new()
            $notSharedForm.CreateElement = $this.CreateElement
            [Ooui.UI]::Publish("/Form",  $notSharedForm)

            $frame = Invoke-Command -ScriptBlock $this.CreateElement
            $guid  = [Guid]::NewGuid().ToString()
            [Ooui.UI]::Publish("/$guid", $frame.NativeUI)
            $this.Document.Window.Location = "/$guid"
        } | Out-Null

    }

}

class OouiWindow : WindowBase {

    OouiWindow() {
        $this.SetNativeUI([Div]::new())
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
    #Divs   https://jsfiddle.net/rwe8hp6f/

    OouiStackPanel() {
        $this.SetNativeUI([Div]::new())
        $this.AddProperty("Orientation")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $listItem = [Div]::new()
            if ($this._Orientation -eq [Orientation]::Horizontal) {
                $listItem.Style.float = "left"
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
        $this.SetNativeUI([Span]::new())
        $this.WrapProperty("Caption", "Text")
    }
}

class OouiButton : OouiElement {

    OouiButton() {
        $nativeUI = [Button]::new("NotSet")
        $this.SetNativeUI($nativeUI)
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
        $this.SetNativeUI([TextInput ]::new())
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
    hidden [Div]   $ListNativeUI
    hidden [Span] $LabelNativeUI
    hidden [Input] $CheckBoxNativeUI

    OouiCheckBox() {
        $this.ListNativeUI      = [Div]::new()
        $this.LabelNativeUI     = [Span]::new()
        $this.CheckBoxNativeUI  = [Input]::new("CheckBox")
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
    hidden [Div]           $ListNativeUI
    hidden [Span]         $LabelNativeUI
    hidden [Input]         $RadioButtonNativeUI

    OouiRadioButton() {
        $this.ListNativeUI            = [Div]::new()
        $this.LabelNativeUI           = [Span]::new()
        $this.RadioButtonNativeUI     = [Input]::new("Radio")
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
        $this.SetNativeUI([Div]::new())
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

class OouiList : OouiStackPanel {
    [List[ListItem]] $Items = [List[ListItem]]::new()

    OouiList() {
        $this.Orientation   = [Orientation]::Horizontal
    }

    [void] AddColumn([OouiListColumn] $listColumn) {
        $column = [OouiStackPanel]::new()
        $column.Orientation           = [Orientation]::Vertical
        $title = [OouiLabel]::new()
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
        $itemIndex = $this.Items.IndexOf($listItem) + 1
        $this.Children | ForEach-Object {
            $column = $_
            $cell = $column.NativeUI.Children.Item($itemIndex)
            $column.NativeUI.RemoveChild($cell)
        }

        $columnIndex = 0
        $this.Children | ForEach-Object {
            $column = $_
            $cell = $listItem.Children.Item($columnIndex)
            $column.Children.Remove($cell)
            $columnIndex++
        }

        $this.Items.Remove($listItem)
    }

}

class OouiListColumn {
    [String] $Name
    [String] $Title
}

class OouiTabItem : OouiStackPanel {
    [String] $Caption   = ""
}

class OouiTabControl : OouiStackPanel {
    [Ooui.List]     $List     = [Ooui.List]::new()

    OouiTabControl() {
        $this.List.ClassName = "nav nav-tabs"
        $this.NativeUI.AppendChild($this.List)
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $item = [Ooui.ListItem]::new()
            $item.ClassName = "nav-item"
            $anchor = [Ooui.Anchor]::new()
            $anchor.ClassName = "nav-link"
            $anchor.Text = $element.Caption
            Register-ObjectEvent -InputObject $anchor -EventName Click -MessageData @($this, $anchor) -Action {
                $event.MessageData
                $Control = $event.MessageData[0]
                $anchor  = $event.MessageData[1]
                $Control.SelectTab($anchor.Text)
            } | Out-Null
            $item.AppendChild($anchor) | Out-Null
            $this.List.AppendChild($item) | Out-Null
            $this.NativeUI.AppendChild($element.NativeUI) | Out-Null

            $firstTab = $this.GetTabs() | Select-Object -First 1
            $this.SelectTab($firstTab.Caption)
        }
    }

    [OOuiTabItem[]] GetTabs() {
        return $this.Children | Where-Object { $_.GetType() -eq [OOuiTabItem] }
    }

    [void] SelectTab([String] $tabCaption) {
        $this.GetTabs() | ForEach-Object {
            if ($_.Caption -eq $tabCaption) {
                $_.Visible = $true
            } else {
                $_.Visible = $false
            }
        }
        $this.List.Children | ForEach-Object {
            $anchor = $_.FirstChild
            if ($anchor.Text -eq $tabCaption) {
                $_.ClassName = "nav-link active"
            } else {
                $_.ClassName = "nav-link"
            }
        }
    }

}

class OouiModal : OouiElement {
    [Div]   $DialogDiv      = [Div]::new()
    [Div]   $DocumentDiv    = [Div]::new()
    [Div]   $ContentDiv     = [Div]::new()


    OouiModal() {
        $this.DialogDiv.ClassName = "modal"
        $this.DialogDiv.Style.display = "none"
        $this.DialogDiv.SetAttribute("role", "dialog")

        $this.DocumentDiv.ClassName = "modal-dialog"
        $this.DocumentDiv.SetAttribute("role", "document")
        $this.DialogDiv.AppendChild($this.DocumentDiv)

        $this.ContentDiv.ClassName = "modal-content"
        $this.DocumentDiv.AppendChild($this.ContentDiv)

        $this.SetNativeUI($this.DialogDiv)
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.ContentDiv.AppendChild($element.NativeUI)
        }
    }

    [void] Show() {
        $this.DialogDiv.Style.display = "block"
    }

    [void] Hide() {
        $this.DialogDiv.Style.display = "none"
    }
}
