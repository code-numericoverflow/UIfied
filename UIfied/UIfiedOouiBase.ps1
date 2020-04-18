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
    $Shared         = $false
    $Port           = 8185
    [ScriptBlock] $CreateElement

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
        $notSharedForm = [NotSharedForm]::new($this.Port, "/Form")
        $notSharedForm.CreateElement = $this.CreateElement
        $notSharedForm.Publish()
    }
}

class NotSharedForm : Div {
    [Anchor]       $Anchor
    [ScriptBlock]  $CreateElement
    [int]          $Port
    [string]       $Path

    NotSharedForm([int]$port, [string]$path) {
        $this.Port = $port
        $this.Path = $path
    }

    Publish() {
        $hostWrapper = [OouiWrapper.OouiWrapper]::new($this.Port, $this.Path)
        $hostWrapper.Publish()
        Add-Member -InputObject $hostWrapper -MemberType NoteProperty -Name sb -Value $this.CreateElement | Out-Null
        Register-ObjectEvent -InputObject $hostWrapper -EventName OnPublish -MessageData $hostWrapper -Action {
            param ($hostWrapper)
            $window = Invoke-Command -ScriptBlock $event.MessageData.sb
            $event.MessageData.Frame = $window.NativeUI
        } | Out-Null
    }
}

class OouiWindow : WindowBase {

    OouiWindow() {
        $this.SetNativeUI([Div]::new())
        $this.WrapProperty("Caption", "Title")
        $this.AddScriptBlockProperty("Loaded")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.NativeUI.AppendChild($element.NativeUI)
        }
    }

    [void] ShowDialog() {
    }

    [void] OnLoaded() {
        Invoke-Command -ScriptBlock $this._Loaded -ArgumentList $this
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
                $listItem.Style.clear = "both"
                #$listItem.Style.Display = ""
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
        $this.SetNativeUI([TextInput]::new())
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
    hidden [Span]  $LabelNativeUI
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

    [void] Clear() {
        $this.Items.ToArray() | ForEach-Object {
            $this.RemoveItem($_)
        }
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

class OouiTimer : OouiElement {
    [System.Timers.Timer] $Timer
    [Double] $Interval = 1000
    
    OouiTimer() {
        $label = [Span]::new()
        $label.IsHidden = $true
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

class OouiDatePicker : OouiElement {

    OouiDatePicker() {
        $this.SetNativeUI([Input]::new("Date"))
        $this.AddScriptBlockProperty("Change")
        Register-ObjectEvent -InputObject $this.NativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnChange()
        } | Out-Null
        Add-Member -InputObject $this -Name Value -MemberType ScriptProperty -Value {
            [DateTime]::Parse($this.NativeUI.Value)
        } -SecondValue {
            $this.NativeUI.Value = $args[0].ToString("yyyy-MM-dd")
        }
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }

}

class OouiTimePicker : OouiElement {

    OouiTimePicker() {
        $this.SetNativeUI([Input]::new("Time"))
        $this.AddScriptBlockProperty("Change")
        Register-ObjectEvent -InputObject $this.NativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnChange()
        } | Out-Null
        Add-Member -InputObject $this -Name Value -MemberType ScriptProperty -Value {
            if ($this.IsTime($this.NativeUI.Value)) {
                $this.NativeUI.Value
            } else {
                "00:00"
            }
        } -SecondValue {
            if ($this.IsTime($args[0])) {
                $this.NativeUI.Value = $args[0]
            } else {
                "00:00"
            }
        }
    }

    hidden [Boolean] IsTime([String] $timeText) {
        [DateTime] $dateTime = [DateTime]::Today
        return [DateTime]::TryParse( "2000-01-01 " + $timeText, [ref] $dateTime)
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }

}

class OouiBrowser : OouiStackPanel {
    [HashTable[]]            $Data            = [HashTable[]] @()
    [int]                    $PageRows        = 10
    [int]                    $CurrentPage     = 0
    [Boolean]                $IsEditable      = $true
    [HashTable]              $CurrentRow

    #region Components Declaration

    hidden [OouiListColumn[]] $Columns         = [OouiListColumn[]] @()
    hidden [OouiListColumn]   $EditionColumn
    hidden [OouiList]         $List            = [OouiList]::new()
    hidden [OouiStackPanel]   $ButtonPanel     = [OouiStackPanel]::new()
    hidden [OouiButton]       $FirstButton     = [OouiButton]::new()
    hidden [OouiButton]       $PreviousButton  = [OouiButton]::new()
    hidden [OouiButton]       $NextButton      = [OouiButton]::new()
    hidden [OouiButton]       $LastButton      = [OouiButton]::new()
    hidden [OouiButton]       $AddNewButton    = [OouiButton]::new()

    #endregion
    
    OouiBrowser() {
        $this.AddScriptBlockProperty("AddNew")
        $this.AddScriptBlockProperty("Edit")
        $this.AddScriptBlockProperty("Delete")
        $this.AddChild($this.List)
        $this.AddButtons()
    }

    #region Components Creation

    hidden [void] AddButtons() {
        $this.ButtonPanel = [OouiStackPanel]::new()
        $this.ButtonPanel.Orientation = "Horizontal"

        $this.FirstButton.Action                 = { $this.Parent.Parent.OnMoveFirst()     }
        $this.PreviousButton.Action              = { $this.Parent.Parent.OnMovePrevious()  }
        $this.NextButton.Action                  = { $this.Parent.Parent.OnMoveNext()      }
        $this.LastButton.Action                  = { $this.Parent.Parent.OnMoveLast()      }
        $this.AddNewButton.Action                = { $this.Parent.Parent.OnAddNew()        }

        $this.ButtonPanel.AddChild($this.FirstButton)
        $this.ButtonPanel.AddChild($this.PreviousButton)
        $this.ButtonPanel.AddChild($this.NextButton)
        $this.ButtonPanel.AddChild($this.LastButton)
        $this.ButtonPanel.AddChild($this.AddNewButton)

        $this.StyleComponents()

        $this.AddChild($this.ButtonPanel)
    }

    [void] AddColumn([OouiListColumn] $listColumn) {
        $this.Columns += $listColumn
        $this.List.AddColumn($listColumn)
    }

    hidden [void] CreateEditionColumn() {
        $this.EditionColumn = New-Object OouiListColumn -Property @{Name  = "_Edition"; Title = "_"}
        $this.AddColumn($this.EditionColumn)
    }

    hidden [void] AddEditionButtons([HashTable] $hash, [ListItem] $listItem, [int] $rowIndex) {
        $editionPanel = [OouiStackPanel]::new()
        $editionPanel.Orientation = "Horizontal"
        $listItem.AddChild($editionPanel)

        $editButton = [OouiButton]::new()
        Add-Member -InputObject $editButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        $editButton.Action = {
            $this.Parent.Parent.Parent.Parent.CurrentRow = $this.CurrentRow
            $this.Parent.Parent.Parent.Parent.OnEdit()
        }
        $editionPanel.AddChild($editButton)

        $deleteButton = [OouiButton]::new()
        Add-Member -InputObject $deleteButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        $deleteButton.Action = {
            $this.Parent.Parent.Parent.Parent.CurrentRow = $this.CurrentRow
            $this.Parent.Parent.Parent.Parent.OnDelete()
        }
        $editionPanel.AddChild($deleteButton)
        $this.StyleEditionButtons($editButton, $deleteButton, $rowIndex)
    }

    #endregion

    #region Data show

    [void] Refresh() {
        $this.RefreshEditable()
        $rowIndex = 0
        $this.List.Clear()
        $this.GetSelectedData() | ForEach-Object {
            $hash = $_
            $listItem = $this.GetDataListItem($hash, $rowIndex)
            $this.List.AddItem($listItem)
            $rowIndex++
        }
    }

    hidden [void] RefreshEditable() {
        if ($this.EditionColumn -eq $null -and $this.IsEditable) {
            $this.CreateEditionColumn()
        }
        $this.AddNewButton.Visible = $this.IsEditable
    }

    hidden [HashTable[]] GetSelectedData() {
        return $this.Data | Select-Object -Skip ($this.CurrentPage * $this.PageRows) -First $this.PageRows
    }

    hidden [int] GetLastPage() {
        $lastPage =  [Math]::Truncate($this.Data.Count / $this.PageRows)
        if (($this.Data.Count % $this.PageRows) -eq 0) {
            $lastPage--
        }
        return $lastPage
    }

    hidden [ListItem] GetDataListItem([HashTable] $hash, [int] $rowIndex) {
        $listItem = [ListItem]::new()
        $this.Columns | ForEach-Object {
            $column = $_
            if ($column -eq $this.EditionColumn -and $this.IsEditable) {
                $this.AddEditionButtons($hash, $listItem, $rowIndex)
            } else {
                $this.AddCell($hash, $column.Name, $listItem, $rowIndex)
            }
        }
        return $listItem
    }

    [void] AddCell([HashTable] $hash, [string] $columnName, [ListItem] $listItem, [int] $rowIndex) {
        $itemLabel = [OouiLabel]::new()
        $itemLabel.Caption = $hash."$columnName"
        $this.StyleCell($itemLabel, $rowIndex)
        $listItem.AddChild($itemLabel)
    }

    #endregion

    #region Style

    [void] StyleComponents() {
        $this.FirstButton.Caption        = "|<"
        $this.PreviousButton.Caption     = "<<"
        $this.NextButton.Caption         = ">>"
        $this.LastButton.Caption         = ">|"
        $this.AddNewButton.Caption       = "+"
    }

    [void] StyleCell($cell, [int] $rowIndex) {
        $cell.NativeUI.Style.FontSize     = 14
    }

    [void] StyleEditionButtons([OouiButton] $editButton, [OouiButton] $deleteButton, [int] $rowIndex) {
        $editButton.Caption     = "/"
        $deleteButton.Caption   = "X"

        $editButton.NativeUI.Style.FontSize     = 7
        $deleteButton.NativeUI.Style.FontSize   = 7
    }

    #endregion

    #region Move Events
    
    hidden [void] OnMoveFirst() {
        $this.CurrentPage = 0
        $this.Refresh()
    }
    
    hidden [void] OnMovePrevious() {
        if ($this.CurrentPage -gt 0) {
            $this.CurrentPage--
        }
        $this.Refresh()
    }
    
    hidden [void] OnMoveNext() {
        if ($this.CurrentPage -lt $this.GetLastPage()) {
            $this.CurrentPage++
        }
        $this.Refresh()
    }
    
    hidden [void] OnMoveLast() {
        $this.CurrentPage = $this.GetLastPage()
        $this.Refresh()
    }

    #endregion
    
    #region CRUD Events

    hidden [void] OnAddNew() {
        $this.InvokeTrappableCommand($this._AddNew, $this)
    }
    
    hidden [void] OnEdit() {
        $this.InvokeTrappableCommand($this._Edit, $this)
    }
    
    hidden [void] OnDelete() {
        $this.InvokeTrappableCommand($this._Delete, $this)
    }

    #endregion

}
