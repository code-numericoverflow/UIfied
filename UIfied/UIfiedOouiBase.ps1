using namespace System.Collections.Generic
using namespace Ooui

#region Ooui missing elements

class Icon : Element {
    
    Icon() : base("i") {
    }
}

class Table : Element {

    Table() : base("table") {
    }
}

class TableHeader : Element {

    TableHeader() : base("thead") {
    }
}

class TableBody : Element {

    TableBody() : base("tbody") {
    }
}

class TableRow : Element {

    TableRow() : base("tr") {
    }
}

class TableHeaderCell : Element {

    TableHeaderCell() : base("th") {
    }
}

class TableDataCell : Element {

    TableDataCell() : base("td") {
    }
}

#endregion

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
    $Host           = [UI]::Host
    [ScriptBlock] $CreateElement

    OouiHost() {
        # Style documentation in https://getbootstrap.com/docs/5.0
        [UI]::HeadHtml = '
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-+0n0xVW2eSR5OomGNYDnhzAbDsOXxcvSN1TPprVMTNDbiYZCxYbOOl7+AMvyTG2x" crossorigin="anonymous">
            <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700|Roboto+Slab:400,700|Material+Icons" rel="stylesheet" type="text/css" />
            <style>
                .card {
                    margin: 20px;
                }
                .card-title {
                    white-space: nowrap;
                    margin-right: .75rem;
                }
                .card-icon {
                    float: left;
                }
                button {
                    width: 100%;
                }
                .nav {
                    padding-top: 10px;
                }
                .nav-pills .nav-link.active, .nav-pills .show > .nav-link {
                    color: #0d6efd;
                    background-color: white;
                    border-style: solid;
                    border-color: #0d6efd;
                    border-width: 2px;
                }
            </style>
        '
        [UI]::BodyFooterHtml = '
            <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.1/dist/js/bootstrap.bundle.min.js" integrity="sha384-gtEjrD/SeCtmISkJkNUaaKMoLD0//ElJ19smozuHV6z3Iehds+3Ulb9Bn9Plx0x4" crossorigin="anonymous"></script>
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
        $notSharedForm = [NotSharedForm]::new($this.Host, $this.Port, "/Form")
        $notSharedForm.CreateElement = $this.CreateElement
        $notSharedForm.Publish()
    }
}

class NotSharedForm : Div {
    [Anchor]       $Anchor
    [ScriptBlock]  $CreateElement
    [string]       $Host
    [int]          $Port
    [string]       $Path

    NotSharedForm([string]$host, [int]$port, [string]$path) {
        $this.Host = $host
        $this.Port = $port
        $this.Path = $path
    }

    Publish() {
        $hostWrapper = [OouiWrapper.OouiWrapper]::new($this.Port, $this.Path)
        $hostWrapper.Host = $this.Host
        $hostWrapper.Publish()
        $hostWrapper.PublishFileUpload($env:UploadPath, "/files/upload")
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

class OouiIcon : OouiElement {
    [String] $KindName = ""
    static   $IconTranslation = [PSCustomObject] @{
        document = "description"
    }

    OouiIcon() {
        $nativeUI = [Icon]::new()
        $nativeUI.ClassName = "material-icons"
        $this.SetNativeUI($nativeUI)
        Add-Member -InputObject $this -Name Kind -MemberType ScriptProperty -Value {
            $this.KindName
        } -SecondValue {
            $this.KindName = $args[0]
            if ([OouiIcon]::IconTranslation."$($this.KindName)" -ne $null) {
                $this.NativeUI.Text = [OouiIcon]::IconTranslation."$($this.KindName)"
            } else {
                $this.NativeUI.Text = $this.KindName
            }
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
    [String] $Pattern       = ""
    [String] $DefaultText   = ""

    OouiTextBox() {
        $this.SetNativeUIControl()
        $this.WrapProperty("Text", "Value")
        $this.AddScriptBlockProperty("Change")
        Register-ObjectEvent -InputObject $this.NativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            if ($this.Control.Pattern -ne "") {
                $regex = [Regex]::new($this.Control.Pattern)
                if (-not $regex.IsMatch($this.Control.Text)) {
                    $this.Control.Text = $this.Control.DefaultText
                }
            }
            $this.Control.OnChange()
        } | Out-Null
        Add-Member -InputObject $this -Name TextAlignment -MemberType ScriptProperty -Value {
            if ($this.NativeUI.Style.TextAlign -eq "left") {
                [TextAlignment]::Left
            } else {
                [TextAlignment]::Right
            }
        } -SecondValue {
            if ($args[0] -eq "Left") {
                $this.NativeUI.Style.TextAlign = "left"
            } else {
                $this.NativeUI.Style.TextAlign = "right"
            }

        }
    }

    [void] SetNativeUIControl() {
        $this.SetNativeUI([TextInput]::new())
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }
}

class OouiPassword : OouiTextBox {

    [void] SetNativeUIControl() {
        $this.SetNativeUI([Input]::new("password"))
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

class OouiList : OouiElement {
    [List[ListItem]]           $Items          = [List[ListItem]]::new()
    [List[OouiListColumn]]     $Columns        = [List[OouiListColumn]]::new()

    hidden   [Table]                    $Table          = [Table]::new()
    hidden   [TableHeader]              $TableHeader    = [TableHeader]::new()
    hidden   [TableRow]                 $HeaderRow      = [TableRow]::new()
    hidden   [List[TableHeaderCell]]    $HeaderCells    = [List[TableHeaderCell]]::new()
    hidden   [TableBody]                $TableBody      = [TableBody]::new()
    hidden   [List[TableRow]]           $BodyRows       = [List[TableRow]]::new()

    OouiList() {
        $this.SetNativeUI($this.Table)
        $this.NativeUI.ClassName   = "UIList"
        $this.Table.AppendChild($this.TableHeader)
        $this.TableHeader.AppendChild($this.HeaderRow)
        $this.Table.AppendChild($this.TableBody)
    }

    [void] AddColumn([OouiListColumn] $listColumn) {
        $this.Columns.Add($listColumn)
        $cell   = [TableHeaderCell]::new()
        $cell.Text = $listColumn.Title
        $this.HeaderRow.AppendChild($cell)
        $this.HeaderCells.Add($cell)
    }

    [void] AddItem([ListItem] $listItem) {
        $this.Items.Add($listItem)
        $row = [TableRow]::new()
        $this.BodyRows.Add($row)
        $listItem.Children | ForEach-Object {
            $cell = [TableDataCell]::new()
            Add-Member -InputObject $_.NativeUI -Name Form   -MemberType NoteProperty -Value $this.Form
            Add-Member -InputObject $_.NativeUI -Name Parent -MemberType NoteProperty -Value $this
            $cell.AppendChild($_.NativeUI)
            $row.AppendChild($cell)
        }
        $this.TableBody.AppendChild($row)
    }

    [void] StyleComponents() {
    }

    [void] StyleCell($cell) {
        #$cell.NativeUI.Style.LineHeight   = $this.LineHeight
    }

    [void] RemoveItem([ListItem] $listItem) {
        $itemIndex = $this.Items.IndexOf($listItem)
        $row = $this.BodyRows.Item($itemIndex)
        $this.BodyRows.Remove($row)
        $this.TableBody.RemoveChild($row)
        $this.Items.Remove($listItem)
    }

    [void] Clear() {
        $this.Items.ToArray() | ForEach-Object {
            $this.RemoveItem($_)
        }
    }

    [TableDataCell] GetCell([int] $RowIndex, [int] $ColumnIndex) {
        $row = $this.BodyRows.Item($RowIndex)
        $cell = $row.Children.Item($ColumnIndex)
        return $cell
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
    [Object[]]               $Data            = [Object[]] @()
    [int]                    $PageRows        = 10
    [int]                    $CurrentPage     = 0
    [Boolean]                $IsEditable      = $true
    [Object]                 $CurrentRow

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

    hidden [Object] GetInitialHash() {
        $hash = @{}
        $this.Columns | ForEach-Object {
            $column = $_
            $hash += @{ "$($column.Name)" = "" }
        }
        return $hash
    }

    hidden [void] AddEditionButtons([Object] $hash, [ListItem] $listItem, [int] $rowIndex) {
        $editionPanel = [OouiStackPanel]::new()
        $editionPanel.Orientation = "Horizontal"
        $listItem.AddChild($editionPanel)

        $editButton = [OouiButton]::new()
        Add-Member -InputObject $editButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        Add-Member -InputObject $editButton -MemberType NoteProperty -Name Container  -Value $this
        $editButton.Action = {
            $this.Container.CurrentRow = $this.Control.CurrentRow
            $this.Container.OnEdit()
        }
        $editionPanel.AddChild($editButton)

        $deleteButton = [OouiButton]::new()
        Add-Member -InputObject $deleteButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        Add-Member -InputObject $deleteButton -MemberType NoteProperty -Name Container  -Value $this
        $deleteButton.Action = {
            $this.Container.CurrentRow = $this.Control.CurrentRow
            $this.Container.OnDelete()
        }
        $editionPanel.AddChild($deleteButton)
        $this.StyleEditionButtons($editButton, $deleteButton, $rowIndex)
    }

    hidden [void] AddCell([Object] $hash, [string] $columnName, [ListItem] $listItem, [int] $rowIndex) {
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
                $cell = $this.List.GetCell($rowIndex, $columnIndex)
                if ($this.EditionColumn -ne $column) {
                    $cell.Children.Item(0).Text = $hash."$($column.Name)"
                } else {
                    $cell.IsHidden    = $false
                    #$buttons = $this.List.Children.Item($columnIndex).Children.Item($rowIndex + 1).Children
                    #$buttons.Item(0).CurrentRow = $hash
                    #$buttons.Item(1).CurrentRow = $hash
                    $stack = $cell.Children.Item(0)
                    $stack.Control.Children.Item(0).CurrentRow = $hash
                    $stack.Control.Children.Item(1).CurrentRow = $hash
                }
                $columnIndex++
            }
            $rowIndex++
        }
        # EmptyRows
        for ($rowIndex = $selectedData.Count + 1; $rowIndex -le $this.PageRows; $rowIndex++) {
            $columnIndex = 0
            $this.Columns | Select-Object -First ($this.Columns.Count) | ForEach-Object {
                $cell = $this.List.GetCell($rowIndex - 1, $columnIndex)
                $column = $_
                if ($this.EditionColumn -ne $column) {
                    $cell.Children.Item(0).Text = ""
                } else {
                    $cell.IsHidden    = $true
                }
                $columnIndex++
            }
        }
    }

    hidden [Object[]] GetSelectedData() {
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
        $this.List.NativeUI.ClassName   = "UIList table"

        $this.FirstButton.Icon        = [OouiIcon] @{ Kind = "first_page"    }
        $this.PreviousButton.Icon     = [OouiIcon] @{ Kind = "chevron_left"  }
        $this.NextButton.Icon         = [OouiIcon] @{ Kind = "chevron_right" }
        $this.LastButton.Icon         = [OouiIcon] @{ Kind = "last_page"     }
        $this.AddNewButton.Icon       = [OouiIcon] @{ Kind = "add"           }

        $this.FirstButton.NativeUI.ClassName        = "btn btn-link"
        $this.PreviousButton.NativeUI.ClassName     = "btn btn-link"
        $this.NextButton.NativeUI.ClassName         = "btn btn-link"
        $this.LastButton.NativeUI.ClassName         = "btn btn-link"
        $this.AddNewButton.NativeUI.ClassName       = "btn btn-link"
    }

    [void] StyleCell($cell, [int] $rowIndex) {
    }

    [void] StyleEditionButtons([OouiButton] $editButton, [OouiButton] $deleteButton, [int] $rowIndex) {
        $editButton.Icon     = [OouiIcon] @{ Kind = "edit"  }
        $deleteButton.Icon   = [OouiIcon] @{ Kind = "close" }
        
        $editButton.NativeUI.ClassName          = "btn btn-success td-actions btn-sm"
        $deleteButton.NativeUI.ClassName        = "btn btn-danger  td-actions btn-sm"
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
        $this.RemoveNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $this.DropDownMenu.Children | ForEach-Object {
                if ($_.Children.Item(0) -eq $element.NativeUI) { 
                    $this.DropDownMenu.RemoveChild($_) | Out-Null
                }
            }
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

class OouiCard : OouiElement {
    hidden  [div]               $CardContainerDiv   = [div]::new()
    hidden  [div]               $CardHeaderDiv      = [div]::new()
    hidden  [div]               $CardIconDiv        = [div]::new()
    hidden  [OouiStackPanel]    $CardBodyDiv        = [OouiStackPanel]::new()
    hidden  [icon]              $CardIcon           = [icon]::new()
    hidden  [Heading]           $Header             = [Heading]::new(4)
    
    hidden  [OOuiIcon]    $CurrentIcon        = $null

    OouiCard() {
        $this.SetNativeUI($this.CardContainerDiv)
        $this.CardContainerDiv.AppendChild($this.CardHeaderDiv)
        $this.CardContainerDiv.AppendChild($this.CardBodyDiv.NativeUI)
        $this.CardHeaderDiv.AppendChild($this.CardIconDiv)
        $this.CardHeaderDiv.AppendChild($this.Header)
        $this.CardIconDiv.AppendChild($this.CardIcon)
        
        $this.WrapProperty("Caption", "Text", "Header")
        Add-Member -InputObject $this -Name Icon -MemberType ScriptProperty -Value {
            $this.CurrentIcon
        } -SecondValue {
            $this.CurrentIcon = $args[0]
            if ($this.CurrentIcon -ne $null) {
                $this.CardIcon.Text = $this.CurrentIcon.NativeUI.Text
            } else {
                $this.CardIcon.Text = ""
            }
        }
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $listItem = [Div]::new()
            if ($this.CardBodyDiv.Orientation -eq [Orientation]::Horizontal) {
                $listItem.Style.float = "left"
            } else {
                $listItem.Style.clear = "both"
            }
            $this.CardBodyDiv.NativeUI.AppendChild($listItem) | Out-Null
            $listItem.AppendChild($element.NativeUI) | Out-Null
        }
        $this.StyleComponents()
    }

    [void] StyleComponents() {
        $this.CardContainerDiv.ClassName     = "card"
        $this.Header.ClassName               = "card-title"
        $this.Header.Style.display           = "inline"
        $this.CardHeaderDiv.ClassName        = "card-header card-header-icon "
        $this.CardIconDiv.ClassName          = "card-icon"
        $this.CardIcon.ClassName             = "material-icons"
        $this.CardBodyDiv.NativeUI.ClassName = "card-body"
        $this.CardBodyDiv.Orientation        = [Orientation]::Vertical
    }
}

class OouiImage : OouiElement {

    OouiImage() {
        $image = [Image]::new()
        $this.SetNativeUI($image)
        $this.WrapProperty("Source", "Source")
        Add-Member -InputObject $this -Name Width -MemberType ScriptProperty -Value {
            $this.NativeUI.Style.width
        } -SecondValue {
            $this.NativeUI.Style.width = $args[0]
        }
    }
}

class OouiTextEditor : OouiElement {

    OouiTextEditor() {
        $this.SetNativeUI([TextArea]::new())
        $this.WrapProperty("Text", "Value")
        $this.AddScriptBlockProperty("Change")
        Add-Member -InputObject $this -Name Height -MemberType ScriptProperty -Value {
            [int] $this.NativeUI.Rows
        } -SecondValue {
            $this.NativeUI.Rows  = $args[0]
        }
        Add-Member -InputObject $this -Name Width  -MemberType ScriptProperty -Value {
            [int] $this.NativeUI.Columns
        } -SecondValue {
            $this.NativeUI.Columns  = $args[0]
        }

        Register-ObjectEvent -InputObject $this.NativeUI -EventName Change -MessageData $this -Action {
            $this = $event.MessageData
            $this.Control.OnChange()
        } | Out-Null
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }
}

class OouiExpander : OouiElement {
    hidden  [div]             $AcordionDiv           = [div]    @{ ClassName = "accordion" }
    hidden  [div]             $AcodionItemDiv        = [div]    @{ ClassName = "accordion-item" }
    hidden  [Heading]         $AccordionHeader       = [Heading]::new(2)
    hidden  [Button]          $AccordionButton       = [Button] @{ ClassName = "accordion-button" }
    hidden  [div]             $AccordionCollapseDiv  = [div]    @{ ClassName = "accordion-collapse collapse show" }
    hidden  [OouiStackPanel]  $Body                  = [OouiStackPanel]::new()

    OouiExpander() {
        $this.SetNativeUI($this.AcordionDiv)
        $this.AcordionDiv.AppendChild($this.AcodionItemDiv)
        $this.AccordionHeader.ClassName = "accordion-header"
        $this.AcodionItemDiv.AppendChild($this.AccordionHeader)
        $this.AccordionButton.SetAttribute("data-bs-toggle", "collapse")
        $this.AccordionButton.SetAttribute("data-bs-target", "#$($this.AccordionCollapseDiv.Id)")
        $this.AccordionButton.SetAttribute("aria-expanded",  "true")
        $this.AccordionButton.SetAttribute("aria-controls",  $this.AccordionCollapseDiv.Id)
        $this.AccordionHeader.AppendChild($this.AccordionButton)
        #$this.AccordionCollapseDiv.SetAttribute("data-bs-parent",    "#$($this.AcordionDiv.Id)")
        $this.AcodionItemDiv.AppendChild($this.AccordionCollapseDiv)
        $this.Body.NativeUI.ClassName = "accordion-body"
        $this.AccordionCollapseDiv.AppendChild($this.Body.NativeUI)

        $this.WrapProperty("Caption", "Text", "AccordionButton")

        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $listItem = [Div]::new()
            if ($this.Body.Orientation -eq [Orientation]::Horizontal) {
                $listItem.Style.float = "left"
            } else {
                $listItem.Style.clear = "both"
            }
            $this.Body.NativeUI.AppendChild($listItem) | Out-Null
            $listItem.AppendChild($element.NativeUI)   | Out-Null
        }
    }

}

class OouiInteger : OouiTextBox {

    OouiInteger() {
        $this.TextAlignment   = [TextAlignment]::Right
        $this.Pattern         = '^[\d]+$'
        $this.DefaultText     = "0"
        $this.Text            = "0"
    }
}

class OouiDouble : OouiTextBox {

    OouiDouble() {
        $this.TextAlignment   = [TextAlignment]::Right
        $this.Pattern         = '^[\d\.]+$'
        $this.DefaultText     = "0.0"
        $this.Text            = "0.0"
    }
}

#region ComboBox with Select
#class OouiComboBoxItem : OouiElement {
#
#    OouiComboBoxItem() {
#        $this.SetNativeUI([Option]::new())
#        $this.WrapProperty("Id"     , "Value")
#        $this.WrapProperty("Caption", "Label")
#    }
#}
#
#class OouiComboBox : OouiElement {
#
#    OouiComboBox() {
#        $this.SetNativeUI([Select]::new())
#        Add-Member -InputObject $this -Name Text -MemberType ScriptProperty -Value {
#            $this.NativeUI.Value
#        } -SecondValue {
#            $id = [String] $Args[0]
#            $this.NativeUI.value = $id
#            #$selectedItem = $this.NativeUI.Children | Where-Object { $_.Value -eq $id }
#            #if ($selectedItem -ne $null) {
#            #    $this.NativeUI.Value = $id
#            #    $selectedItem.DefaultSelected = $true
#            #}
#        }
#        $this.AddScriptBlockProperty("Change")
#        Register-ObjectEvent -InputObject $this.NativeUI -EventName Change -MessageData $this -Action {
#            $this = $event.MessageData
#            $this.Control.OnChange()
#        } | Out-Null
#        $this.AddNativeUIChild = {
#            param (
#                [OouiElement] $element
#            )
#            $this.NativeUI.AppendChild($element.NativeUI)
#        }
#    }
#
#    [void] OnChange() {
#        $this.InvokeTrappableCommand($this._Change, $this)
#    }
#
#}
#endregion

class OouiComboBoxItem : OouiMenuItem {
    [String] $Id     

    OouiComboBoxItem() {
    }
}

class OouiCombobox : OouiDropDownMenu {
    [String]   $SelectedId
    [String]   $BackgroundColor = "transparent"
    [String]   $Color           = "black"

    OouiCombobox() {
        Add-Member -InputObject $this -Name Text -MemberType ScriptProperty -Value {
            $this.SelectedId
        } -SecondValue {
            $id = $args[0]
            if ($this.SelectedId -ne $id) {
                $selectedItem = $this.Children | Where-Object { $_.Id -eq $id }
                if ($selectedItem -ne $null) {
                    $this.DropDownToogle.Caption = $selectedItem.Caption
                    $this.SelectedId = $id
                    $this.Control.OnChange()
                }
            }
        }
        $this.AddScriptBlockProperty("Change")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $menuItem = [Ooui.ListItem]::new()
            $element.NativeUI.SetAttribute("class",  "dropdown-item")
            $element.NativeUI.Style.Width = "100%"
            $element.NativeUI.Style.BorderColor = "transparent"
            Add-Member -InputObject $element -MemberType NoteProperty -Name ComboBox          -Value $this
            $element.Action = {
                param ($this)
                $this.ComboBox.Text = $this.Id
            }
            $menuItem.AppendChild($element.NativeUI) | Out-Null
            $this.DropDownMenu.AppendChild($menuItem) | Out-Null
        }
        $this.StyleComponents()
    }

    [void] OnChange() {
        Invoke-Command -ScriptBlock $this._Change -ArgumentList $this
    }

    [void] StyleComponents () {
        $this.DropDownToogle.NativeUI.Style.BackgroundColor = $this.BackgroundColor
        $this.DropDownToogle.NativeUI.Style.Color           = $this.Color
    }

}

class OouiFileUpload : OouiElement {
           [Anchor]   $Anchor        = [Anchor] @{ Href = "/files"; Target = "_blank" }
    hidden [Span]     $LabelNativeUI = [Span]::new()

    OouiFileUpload() {
        $this.SetNativeUI($this.Anchor)
        $this.WrapProperty("Caption", "Text", "LabelNativeUI")
        $this.NativeUI.AppendChild($this.LabelNativeUI)
    }

}