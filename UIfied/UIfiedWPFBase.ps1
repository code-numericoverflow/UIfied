using namespace System.Collections.Generic
using namespace System.Windows
using namespace System.Windows.Controls
using namespace System.Windows.Input

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

class WPFIcon : WPFLabel {
    hidden  [String] $KindName

    WPFIcon() {
        Add-Member -InputObject $this -Name Kind -MemberType ScriptProperty -Value {
            $this.KindName
        } -SecondValue {
            $this.KindName = $args[0]
            $this.RefreshCaption()
        }
    }

    [void] RefreshCaption() {
        $this.Caption = [IconStrinfy]::ToIconString($this.KindName)
    }
}

class WPFButton : WPFElement {
    hidden [String]  $CaptionText   = ""
    hidden [String]  $IconText      = ""
           [bool]    $RightIcon     = $false

    WPFButton() {
        $this.SetNativeUI([Button]::new())
        Add-Member -InputObject $this -Name Caption -MemberType ScriptProperty -Value {
            $this.CaptionText
        } -SecondValue {
            $this.CaptionText = $args[0]
            $this.RefreshCaption()
        }
        Add-Member -InputObject $this -Name Icon -MemberType ScriptProperty -Value {
            $this.IconText
        } -SecondValue {
            if ($args[0] -ne $null) {
                $this.IconText = [IconStrinfy]::ToIconString($args[0].Kind)
                $this.RefreshCaption()
            } else {
                $this.IconText = ""
                $this.RefreshCaption()
            }
        }
        $this.AddScriptBlockProperty("Action")
        $this.NativeUI.Add_Click({ $this.Control.OnAction() })
    }

    [void] RefreshCaption() {
        if ($this.RightIcon) {
            $this.NativeUI.Content = ($this.CaptionText + " " + $this.IconText).Trim()
        } else {
            $this.NativeUI.Content = ($this.IconText + " " + $this.CaptionText).Trim()
        }
    }

    [void] OnAction() {
        $this.InvokeTrappableCommand($this._Action, $this)
    }
}

class WPFTextBox : WPFElement {
    [String] $Pattern       = ""
    [String] $DefaultText   = ""

    WPFTextBox() {
        $this.SetNativeUI([TextBox]::new())
        $this.WrapProperty("Text", "Text")
        $this.WrapProperty("TextAlignment", "TextAlignment")
        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_TextChanged({ $this.Control.OnChange() })
        $this.NativeUI.Add_LostFocus({
            if ($this.Control.Pattern -ne "") {
                $regex = [Regex]::new($this.Control.Pattern)
                if (-not $regex.IsMatch($this.Control.Text)) {
                    $this.Control.Text = $this.Control.DefaultText
                }
            }
        })
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

    [void] Clear() {
        $this.Items.ToArray() | ForEach-Object {
            $this.RemoveItem($_)
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
        $windowNativeUI.WindowStyle = [WindowStyle]::SingleBorderWindow
        $windowNativeUI.SizeToContent = 'WidthAndHeight'
        $windowNativeUI.Margin        = 10
        $this.SetNativeUI($windowNativeUI)
        $this.WrapProperty("Title", "Title")
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

class WPFDatePicker : WPFElement {

    WPFDatePicker() {
        $this.SetNativeUI([DatePicker]::new())
        $this.WrapProperty("Value", "SelectedDate")
        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_SelectedDateChanged({ $this.Control.OnChange() })
    }

    [void] OnChange() {
        $this.InvokeTrappableCommand($this._Change, $this)
    }
}

class WPFTimePicker : WPFElement {

    WPFTimePicker() {
        $textBox = [TextBox]::new()
        $textBox.MaxLength = 5
        $this.SetNativeUI($textBox)
        Add-Member -InputObject $this -Name Value -MemberType ScriptProperty -Value {
            $this.GetTextTime()
        } -SecondValue {
            $this.NativeUI.Text = $args[0]
        }
        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_TextChanged({ $this.Control.OnChange() })
        $this.AddScriptBlockProperty("LostFocus")
        $this.NativeUI.Add_LostFocus({ $this.Control.OnLostFocus() })
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

class WPFBrowser : WPFStackPanel {
    [HashTable[]]            $Data            = [HashTable[]] @()
    [int]                    $PageRows        = 10
    [int]                    $CurrentPage     = 0
    [Boolean]                $IsEditable      = $true
    [HashTable]              $CurrentRow

    #region Components Declaration

    hidden [WPFListColumn[]] $Columns         = [WPFListColumn[]] @()
    hidden [WPFListColumn]   $EditionColumn
    hidden [WPFList]         $List            = [WPFList]::new()
    hidden [WPFStackPanel]   $ButtonPanel     = [WPFStackPanel]::new()
    hidden [WPFButton]       $FirstButton     = [WPFButton]::new()
    hidden [WPFButton]       $PreviousButton  = [WPFButton]::new()
    hidden [WPFButton]       $NextButton      = [WPFButton]::new()
    hidden [WPFButton]       $LastButton      = [WPFButton]::new()
    hidden [WPFButton]       $AddNewButton    = [WPFButton]::new()

    #endregion
    
    WPFBrowser() {
        $this.AddScriptBlockProperty("AddNew")
        $this.AddScriptBlockProperty("Edit")
        $this.AddScriptBlockProperty("Delete")
        $this.AddChild($this.List)
        $this.AddButtons()
    }

    #region Components Creation

    hidden [void] AddButtons() {
        $this.ButtonPanel = [WPFStackPanel]::new()
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

    [void] AddColumn([WPFListColumn] $listColumn) {
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
        $editionPanel = [WPFStackPanel]::new()
        $editionPanel.Orientation = "Horizontal"
        $listItem.AddChild($editionPanel)

        $editButton = [WPFButton]::new()
        Add-Member -InputObject $editButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        $editButton.Action = {
            $this.Parent.Parent.Parent.Parent.CurrentRow = $this.CurrentRow
            $this.Parent.Parent.Parent.Parent.OnEdit()
        }
        $editionPanel.AddChild($editButton)

        $deleteButton = [WPFButton]::new()
        Add-Member -InputObject $deleteButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        $deleteButton.Action = {
            $this.Parent.Parent.Parent.Parent.CurrentRow = $this.CurrentRow
            $this.Parent.Parent.Parent.Parent.OnDelete()
        }
        $editionPanel.AddChild($deleteButton)
        $this.StyleEditionButtons($editButton, $deleteButton, $rowIndex)
    }

    hidden [void] AddCell([HashTable] $hash, [string] $columnName, [ListItem] $listItem, [int] $rowIndex) {
        $itemLabel = [WPFLabel]::new()
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
        $this.EditionColumn = New-Object WPFListColumn -Property @{Name  = "_Edition"; Title = "_"}
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

    [Media.Brush]            $ShadowBrush     = ([Media.Brush] "#FFF3F3F3")

    [Media.Brush] GetRowBackground([int] $rowIndex) {
        if (($rowIndex % 2) -eq 0) {
            return $this.ShadowBrush
        } else {
            return [Media.Brushes]::Transparent
        }
    }

    [void] StyleComponents() {
        $this.ButtonPanel.NativeUI.HorizontalAlignment = "Right"

        $this.FirstButton.Caption        = "|<"
        $this.PreviousButton.Caption     = "<<"
        $this.NextButton.Caption         = ">>"
        $this.LastButton.Caption         = ">|"
        $this.AddNewButton.Caption       = "+"

        $this.FirstButton.NativeUI.Margin        = 10
        $this.PreviousButton.NativeUI.Margin     = 10
        $this.NextButton.NativeUI.Margin         = 10
        $this.LastButton.NativeUI.Margin         = 10
        $this.AddNewButton.NativeUI.Margin       = 10
    }

    [void] StyleCell($cell, [int] $rowIndex) {
        $cell.NativeUI.Background = $this.GetRowBackground($rowIndex)
    }

    [void] StyleEditionButtons([WPFButton] $editButton, [WPFButton] $deleteButton, [int] $rowIndex) {
        $editButton.Caption = "/"
        $deleteButton.Caption = "X"
        $editButton.Parent.NativeUI.Background  = $this.GetRowBackground($rowIndex)
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

class WPFMenuItem : WPFElement {

    WPFMenuItem() {
        $this.SetNativeUI([MenuItem]::new())
        $this.WrapProperty("Caption", "Header")
        $this.AddScriptBlockProperty("Action")
        $this.NativeUI.Add_Click({ $this.Control.OnAction() })
    }

    [void] OnAction() {
        $this.InvokeTrappableCommand($this._Action, $this)
    }
}

class WPFDropDownMenu : WPFButton {

    WPFDropDownMenu() {
        $this.RightIcon = $true
        $this.Icon = [WPFIcon] @{ Kind = "chevron_down" }

        $this.NativeUI.ContextMenu = [ContextMenu]::new()
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.NativeUI.ContextMenu.Items.Add($element.NativeUI)
        }
        
        $this.Action = {
            param($this)
            $this.NativeUI.ContextMenu.IsOpen = -not $this.NativeUI.ContextMenu.IsOpen
        }
    }
    
}

class WPFAutoComplete : WPFTextBox {

    WPFAutoComplete() {
        $this.NativeUI.ContextMenu = [ContextMenu]::new()
        $this.NativeUI.ContextMenu.PlacementTarget = $this.NativeUI
        $this.NativeUI.ContextMenu.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom

        $this.NativeUI.Add_KeyUp({
            if ($_.Key -eq [Key]::Down) {
                $this.Control.AddItems()
                $this.Control.NativeUI.ContextMenu.IsOpen = $true
                $this.Control.NativeUI.ContextMenu.Focus()
            }
        })

        $this.AddScriptBlockProperty("ItemsRequested")
    }
    
    [void] AddItems() {
        $this.OnItemsRequested()
    }
    
    [void] OnItemsRequested() {
        [AutoCompleteItem[]] $items = Invoke-Command -ScriptBlock $this._ItemsRequested -ArgumentList $this | Select-Object -First 20
        $this.NativeUI.ContextMenu.Items.Clear()
        0..($items.Count - 1) | ForEach-Object {
            $menuItem = [WPFMenuItem]::new()
            $menuItem.Caption = $items[$_].Text
            Add-Member -InputObject $menuItem -MemberType NoteProperty -Name AutoCompleteTextBox -Value $this
            Add-Member -InputObject $menuItem -MemberType NoteProperty -Name AutoCompleteId      -Value $items[$_].Id
            $menuItem.Action = {
                param ($this)
                $this.AutoCompleteTextBox.Text = $this.AutoCompleteId
                $this.AutoCompleteTextBox.NativeUI.ContextMenu.IsOpen = $false
            }
            $this.NativeUI.ContextMenu.Items.Add($menuItem.NativeUI)
        }
        #$this.NativeUI.ContextMenu.MinWidth = $this.NativeUI.Width
    }
}

class WPFCard : WPFElement {
    hidden  [GroupBox]          $CardGroupBox       = [GroupBox]::new()
    hidden  [StackPanel]        $HeaderStackPanel   = [StackPanel]::new()
    hidden  [TextBlock]         $HeaderTextBlock    = [TextBlock]::new()
    hidden  [StackPanel]        $BodyStackPanel     = [StackPanel]::new()
    hidden                      $CurrentIcon        = [WPFIcon]::new()

    WPFCard() {
        $this.SetNativeUI($this.CardGroupBox)
        $this.CardGroupBox.Header = $this.HeaderStackPanel
        $this.HeaderStackPanel.AddChild($this.CurrentIcon.NativeUI)
        $this.HeaderStackPanel.AddChild($this.HeaderTextBlock)
        $this.CardGroupBox.Content = $this.BodyStackPanel

        $this.WrapProperty("Caption", "Text", "HeaderTextBlock")
        Add-Member -InputObject $this -Name Icon -MemberType ScriptProperty -Value {
            $this.CurrentIcon
        } -SecondValue {
            $this.HeaderStackPanel.Children.Remove($this.CurrentIcon.NativeUI)
            $this.HeaderStackPanel.Children.Remove($this.HeaderTextBlock)
            $this.CurrentIcon = $args[0]
            $this.HeaderStackPanel.AddChild($this.CurrentIcon.NativeUI)
            $this.HeaderStackPanel.AddChild($this.HeaderTextBlock)
            $this.StyleComponents()
        }
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.BodyStackPanel.AddChild($element.NativeUI) | Out-Null
        }
        $this.StyleComponents()
    }

    [void] StyleComponents() {
        $this.CardGroupBox.Margin           = "16"
        $this.HeaderStackPanel.Orientation  = [Orientation]::Horizontal
        $this.BodyStackPanel.Orientation    = [Orientation]::Vertical
    }

}

class WPFImage : WPFElement {

    WPFImage() {
        $image = [Image]::new()
        $this.SetNativeUI($image)
        $this.WrapProperty("Source", "Source")
        $this.WrapProperty("Width", "Width")
    }
}

class WPFTextEditor : WPFTextBox {

    WPFTextEditor() {
        #$this.NativeUI.TextWrapping                    = "Wrap" 
        $this.NativeUI.AcceptsReturn                   = $true
        $this.NativeUI.VerticalScrollBarVisibility     = "Visible"
        $this.NativeUI.HorizontalScrollBarVisibility   = "Auto"
        Add-Member -InputObject $this -Name Height -MemberType ScriptProperty -Value {
            [int] $this.NativeUI.Height / 20
        } -SecondValue {
            $this.NativeUI.Height  = $args[0] * 20
        }
        Add-Member -InputObject $this -Name Width  -MemberType ScriptProperty -Value {
            [int] $this.NativeUI.Width / 20
        } -SecondValue {
            $this.NativeUI.Width  = $args[0] * 20
        }
    }

}

class WPFExpander : WPFElement {
    hidden $StackPanelNativeUI = [StackPanel]::new()

    WPFExpander() {
        $this.SetNativeUI([Expander]::new())
        $this.WrapProperty("Caption", "Header")
        $this.NativeUI.Content = $this.StackPanelNativeUI
        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.StackPanelNativeUI.AddChild($element.NativeUI) | Out-Null
        }
    }
}

class WPFInteger : WPFTextBox {

    WPFInteger() {
        $this.TextAlignment   = [TextAlignment]::Right
        $this.Pattern         = '^[\d]+$'
        $this.DefaultText     = "0"
        $this.Text            = "0"
    }
}

class WPFDouble : WPFTextBox {

    WPFDouble() {
        $this.TextAlignment   = [TextAlignment]::Right
        $this.Pattern         = '^[\d\.]+$'
        $this.DefaultText     = "0.0"
        $this.Text            = "0.0"
    }
}