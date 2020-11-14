using namespace System.Collections.Generic
using namespace Ooui

# Bootstrap Version: 3.3.7
#    Review styles in https://getbootstrap.com/docs/3.3/components
# Default Style Reference
#    UI.HeadHtml = "<link rel=""stylesheet"" href=""https://ajax.aspnetcdn.com/ajax/bootstrap/3.3.7/css/bootstrap.min.css"" />"

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

    OouiHost() {
        [UI]::HeadHtml = '
            <link rel="stylesheet" href="https://ajax.aspnetcdn.com/ajax/bootstrap/3.3.7/css/bootstrap.min.css" />
            <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700|Roboto+Slab:400,700|Material+Icons" rel="stylesheet" type="text/css" />
        '
    }

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

class Icon : Element {
    
    Icon() : base("i") {
    }
    
    Icon([String] $text) {
        $this.Text = $text
    }

}

class OouiIcon : OouiElement {

    OouiIcon() {
        $this.NativeUI = [Icon]::new()
        $this.NativeUI.ClassName = "material-icons"
        Add-Member -InputObject $this -Name Kind -MemberType ScriptProperty -Value {
            $this.NativeUI.Text
        } -SecondValue {
            $this.NativeUI.Text = $args[0]
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
    hidden  [OOuiIcon]    $CurrentIcon   = $null
    hidden  [span]        $CurrentSpan   = $null
    hidden  [String]      $CaptionText   = ""

    OouiButton() {
        $nativeUI = [Button]::new("")
        $nativeUI.ClassName = "btn btn-primary"
        $this.SetNativeUI($nativeUI)
        Add-Member -InputObject $this -Name Caption -MemberType ScriptProperty -Value {
            $this.CaptionText
        } -SecondValue {
            $this.RemoveChildren()
            $this.CaptionText = $args[0]
            $this.RefreshCaption()
        }
        Add-Member -InputObject $this -Name Icon -MemberType ScriptProperty -Value {
            $this.CurrentIcon
        } -SecondValue {
            $this.RemoveChildren()
            $this.CurrentIcon = $args[0]
            $this.RefreshCaption()
        }
        $this.AddScriptBlockProperty("Action")
        Register-ObjectEvent -InputObject $this.NativeUI -EventName Click -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnAction()
        } | Out-Null
    }

    [void] RemoveChildren() {
        if ($this.CurrentSpan -ne $null) {
            $this.NativeUI.RemoveChild($this.CurrentSpan)
        }
        if ($this.CurrentIcon -ne $null) {
            $this.NativeUI.RemoveChild($this.CurrentIcon.NativeUI)
        }
    }

    [void] RefreshCaption() {
        if ($this.CurrentIcon -ne $null) {
            $this.NativeUI.AppendChild($this.CurrentIcon.NativeUI)
        }
        if ($this.CaptionText -ne "") {
            $this.CurrentSpan = [Span]::new()
            $this.CurrentSpan.Text = $this.CaptionText
            $this.NativeUI.AppendChild($this.CurrentSpan)
        }
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
    hidden [Span]          $LabelNativeUI
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
    [List[ListItem]] $Items        = [List[ListItem]]::new()
    [String]         $LineHeight   = "30px"

    OouiList() {
        $this.Orientation          = [Orientation]::Horizontal
        $this.NativeUI.ClassName   = "UIList"
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
            $this.StyleCell($cell)
            $columnIndex++
        }
    }

    [void] StyleCell($cell) {
        $cell.NativeUI.Style.LineHeight   = $this.LineHeight
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
        $this.RefreshStyle()
    }

    RefreshStyle() {
        $this.List.ClassName = "nav nav-pills"
    }

    [OOuiTabItem[]] GetTabs() {
        return $this.Children
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
                $_.ClassName      = "nav-item active"
                $anchor.ClassName = "nav-link active"
            } else {
                $_.ClassName      = "nav-item"
                $anchor.ClassName = "nav-link"
            }
        }
    }

}

class OouiModal : OouiElement {
    [Div]     $DialogDiv      = [Div]::new()
    [Div]     $DocumentDiv    = [Div]::new()
    [Div]     $ContentDiv     = [Div]::new()
    [Div]     $HeaderDiv      = [Div]::new()
    [Heading] $TitleHeading   = [Heading]::new(5)
    [Div]     $BodyDiv        = [Div]::new()

    OouiModal() {
        $this.DialogDiv.ClassName = "modal"
        $this.DialogDiv.Style.display = "none"
        $this.DialogDiv.SetAttribute("role", "dialog")

        $this.DocumentDiv.ClassName = "modal-dialog"
        $this.DocumentDiv.SetAttribute("role", "document")
        $this.DialogDiv.AppendChild($this.DocumentDiv)

        $this.ContentDiv.ClassName = "modal-content"
        $this.DocumentDiv.AppendChild($this.ContentDiv)

        $this.HeaderDiv.ClassName = "modal-header"
        $this.ContentDiv.AppendChild($this.HeaderDiv)

        $this.TitleHeading.ClassName = "modal-title"
        $this.HeaderDiv.AppendChild($this.TitleHeading)

        $this.BodyDiv.ClassName = "modal-body"
        $this.ContentDiv.AppendChild($this.BodyDiv)

        $this.SetNativeUI($this.DialogDiv)
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.BodyDiv.AppendChild($element.NativeUI)
        }
        $this.WrapProperty("Title", "Text", "TitleHeading")
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

    [void] CreateList() {
        $this.List.Clear()
        $this.CreateEditable()
        0..($this.PageRows - 1) | ForEach-Object {
            $listItem = $this.GetInitialListItem($_)
            $this.List.AddItem($listItem)
        }
    }

    hidden [ListItem] GetInitialListItem([int] $rowIndex) {
        $hash = $this.GetInitialHash()
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

    hidden [HashTable] GetInitialHash() {
        $hash = @{}
        $this.Columns | ForEach-Object {
            $column = $_
            $hash += @{ "$($column.Name)" = "" }
        }
        return $hash
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

    hidden [void] AddCell([HashTable] $hash, [string] $columnName, [ListItem] $listItem, [int] $rowIndex) {
        $itemLabel = [OouiLabel]::new()
        $itemLabel.Caption = $hash."$columnName"
        $listItem.AddChild($itemLabel)
        $this.StyleCell($itemLabel, $rowIndex)
    }

    hidden [void] CreateEditable() {
        if ($this.EditionColumn -eq $null -and $this.IsEditable) {
            $this.CreateEditionColumn()
        }
        $this.AddNewButton.Visible = $this.IsEditable
    }

    hidden [void] CreateEditionColumn() {
        $this.EditionColumn = New-Object OouiListColumn -Property @{Name  = "_Edition"; Title = "_"}
        $this.AddColumn($this.EditionColumn)
    }

    #endregion

    #region Data show

    [void] Refresh() {
        # Fill Rows
        $rowIndex = 0
        $selectedData = $this.GetSelectedData()
        $selectedData | ForEach-Object {
            $hash = $_
            $columnIndex = 0
            $this.Columns | Select-Object -First ($this.Columns.Count) | ForEach-Object {
                $column = $_
                if ($this.EditionColumn -ne $column) {
                    $this.List.Children.Item($columnIndex).Children.Item($rowIndex + 1).Caption = $hash."$($column.Name)"
                } else {
                    $buttons = $this.List.Children.Item($columnIndex).Children.Item($rowIndex + 1).Children
                    $buttons.Item(0).CurrentRow = $hash
                    $buttons.Item(1).CurrentRow = $hash
                    $buttons.Item(0).Visible    = $true
                    $buttons.Item(1).Visible    = $true
                }
                $columnIndex++
            }
            $rowIndex++
        }
        # EmptyRows
        for ($rowIndex = $selectedData.Count + 1; $rowIndex -le $this.PageRows; $rowIndex++) {
            $columnIndex = 0
            $this.Columns | Select-Object -First ($this.Columns.Count) | ForEach-Object {
                $column = $_
                if ($this.EditionColumn -ne $column) {
                    $this.List.Children.Item($columnIndex).Children.Item($rowIndex).Caption = ""
                } else {
                    $buttons = $this.List.Children.Item($columnIndex).Children.Item($rowIndex).Children
                    $buttons.Item(0).Visible    = $false
                    $buttons.Item(1).Visible    = $false
                }
                $columnIndex++
            }
        }
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

    #endregion

    #region Style

    [void] StyleComponents() {
        $this.List.LineHeight = "32px"

        $this.FirstButton.Caption        = "|<"
        $this.PreviousButton.Caption     = "<<"
        $this.NextButton.Caption         = ">>"
        $this.LastButton.Caption         = ">|"
        $this.AddNewButton.Caption       = "+"

        $this.FirstButton.NativeUI.ClassName    = "btn btn-primary btn-link btn-lg"
        $this.PreviousButton.NativeUI.ClassName = "btn btn-primary btn-link btn-lg"
        $this.NextButton.NativeUI.ClassName     = "btn btn-primary btn-link btn-lg"
        $this.LastButton.NativeUI.ClassName     = "btn btn-primary btn-link btn-lg"
        $this.AddNewButton.NativeUI.ClassName   = "btn btn-warning btn-fab btn-round btn-lg"
        $this.AddNewButton.NativeUI.Style.BackgroundColor   = "lime"
    }

    [void] StyleCell($cell, [int] $rowIndex) {
        $cell.NativeUI.Style.FontSize     = 14
    }

    [void] StyleEditionButtons([OouiButton] $editButton, [OouiButton] $deleteButton, [int] $rowIndex) {
        $editButton.Caption     = "/"
        $deleteButton.Caption   = "X"

        $editButton.NativeUI.ClassName          = "btn btn-primary btn-link btn-sm"
        $deleteButton.NativeUI.ClassName        = "btn btn-danger  btn-link btn-sm"
        $deleteButton.NativeUI.Style.Color      = "red"
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

class OouiMenuItem : OouiButton {

    [void] OnAction() {
        ([OouiButton]$this).OnAction()
        $this.Parent.ToogleMenu()
    }

}

class OouiDropDownMenu : OouiStackPanel {

    [OOuiButton]    $DropDownToogle      = [OOuiButton]::new()
    [List]          $DropDownMenu        = [List]::new()
    
    OouiDropDownMenu() {
        $dropDown = [Div]::new()
        $dropDown.SetAttribute("class",          "dropdown")
        $this.NativeUI.AppendChild($dropDown)

        $this.DropDownToogle.NativeUI.SetAttribute("class",          "btn btn-primary dropdown-toggle")
        $this.DropDownToogle.NativeUI.SetAttribute("data-toggle",    "dropdown")
        $this.DropDownToogle.NativeUI.SetAttribute("aria-expanded",  "true")
        $this.DropDownToogle.NativeUI.SetAttribute("aria-haspopup",  "true")
        Add-Member -InputObject $this.DropDownToogle -MemberType NoteProperty -Name ParentControl -Value $this
        $this.DropDownToogle.Action = {
            param ($this)
            $this.Control.ParentControl.ToogleMenu()
        }
        $dropDown.AppendChild($this.DropDownToogle.NativeUI)
        
        $this.DropDownMenu.SetAttribute("class",          "dropdown-menu")
        $dropDown.AppendChild($this.DropDownMenu)

        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $menuItem = [Ooui.ListItem]::new()
            $element.NativeUI.SetAttribute("class",  "dropdown-item")
            $element.NativeUI.Style.Width = "100%"
            $element.NativeUI.Style.BorderColor = "transparent"
            $menuItem.AppendChild($element.NativeUI) | Out-Null
            $this.DropDownMenu.AppendChild($menuItem) | Out-Null
        }
        Add-Member -InputObject $this -Name "Caption" -MemberType ScriptProperty                `
                    -Value          { $this.DropDownToogle.NativeUI.Text }                      `
                    -SecondValue    { $this.DropDownToogle.NativeUI.Text = $args[0] }
    }

    [void] ToogleMenu() {
        if ($this.DropDownMenu.ClassName.Contains("show")) {
            $this.DropDownMenu.ClassName = $this.DropDownMenu.ClassName.Replace(" show", "")
        } else {
            $this.DropDownMenu.ClassName = $this.DropDownMenu.ClassName + " show"
        }
    }

}

class OouiAutoComplete : OouiStackPanel {

    [OouiTextBox]   $TextBox             = [OouiTextBox]::new()
    [List]          $DropDownMenu        = [List]::new()
    
    OouiAutoComplete() {
        $dropDown = [Div]::new()
        $dropDown.SetAttribute("class",          "dropdown")
        $this.NativeUI.AppendChild($dropDown)

        $this.TextBox.NativeUI.SetAttribute("class",          "dropdown-toggle")
        $this.TextBox.NativeUI.SetAttribute("data-toggle",    "dropdown")
        $this.TextBox.NativeUI.SetAttribute("aria-expanded",  "true")
        $this.TextBox.NativeUI.SetAttribute("aria-haspopup",  "true")
        Add-Member -InputObject $this.TextBox -MemberType NoteProperty -Name ParentControl -Value $this
        $this.TextBox.Change = {
            param ($this)
            $this.Control.ParentControl.ClearDropDown()
        }
        Register-ObjectEvent -InputObject $this.TextBox.NativeUI -EventName KeyDown -MessageData $this -Action {
            $this = $event.MessageData
            #$this.Control.TextBox.Text = $event.SourceArgs[1]
        } | Out-Null
        Register-ObjectEvent -InputObject $this.TextBox.NativeUI -EventName KeyUp -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.ShowDropDown()
        } | Out-Null
        $dropDown.AppendChild($this.TextBox.NativeUI)
        
        $this.DropDownMenu.SetAttribute("class",          "dropdown-menu")
        $dropDown.AppendChild($this.DropDownMenu)

        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $menuItem = [Ooui.ListItem]::new()
            #$element.NativeUI.SetAttribute("class",  "btn btn-default")
            $element.NativeUI.SetAttribute("class",  "dropdown-item")
            $element.NativeUI.Style.Width = "100%"
            $element.NativeUI.Style.BorderColor = "transparent"
            $menuItem.AppendChild($element.NativeUI) | Out-Null
            $this.DropDownMenu.AppendChild($menuItem) | Out-Null
        }
        Add-Member -InputObject $this -Name "Text" -MemberType ScriptProperty      `
                    -Value          { $this.TextBox.Text }                         `
                    -SecondValue    { $this.TextBox.Text = $args[0] }
        $this.AddScriptBlockProperty("ItemsRequested")
    }

    [void] ShowDropDown() {
        $this.ClearDropDown()
        $this.AddItems()
        if (-not $this.DropDownMenu.ClassName.Contains("show")) {
            $this.DropDownMenu.ClassName = $this.DropDownMenu.ClassName + " show"
        }
    }

    [void] ClearDropDown() {
        $this.DropDownMenu.Children | ForEach-Object {
            $this.DropDownMenu.RemoveChild($_)
        }
        if ($this.DropDownMenu.ClassName.Contains("show")) {
            $this.DropDownMenu.ClassName = $this.DropDownMenu.ClassName.Replace(" show", "")
        }
    }

    [void] AddItems() {
        $this.OnItemsRequested()
    }

    [void] OnItemsRequested() {
        [AutoCompleteItem[]] $items = Invoke-Command -ScriptBlock $this._ItemsRequested -ArgumentList $this
        $items | ForEach-Object {
            [OOuiButton] $button = [OOuiButton] @{ Caption = $_.Text }
            Add-Member -InputObject $button -MemberType NoteProperty -Name AutoCompleteTextBox -Value $this.TextBox
            Add-Member -InputObject $button -MemberType NoteProperty -Name AutoCompleteId      -Value $_.Id
            $button.Action = {
                param ($this)
                $this.Control.AutoCompleteTextBox.Text = $this.Control.AutoCompleteId
            }
            $this.AddChild($button)
        }
    }

}
