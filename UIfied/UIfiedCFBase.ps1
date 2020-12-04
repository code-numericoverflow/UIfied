using namespace System.Collections.Generic
using namespace System.Reflection
using namespace ConsoleFramework
using namespace ConsoleFramework.Core
using namespace ConsoleFramework.Native
using namespace ConsoleFramework.Controls
using namespace ConsoleFramework.Events
using namespace ConsoleFramework.Rendering

# Font Creation https://www.calligraphr.com/

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

class CFCustomPanel : Panel {
    [color] $ForegroundColor = [color]::Black
    [color] $BackgroundColor = [color]::Gray
    [char]  $Pattern         = ' '

    
    [void] Render([RenderingBuffer] $buffer) {
        $buffer.FillRectangle( 0, 0, $this.ActualWidth, $this.ActualHeight, $this.Pattern, [colors]::Blend($this.ForegroundColor, $this.BackgroundColor));
        #for ([int] $x = 0; $x -lt $this.ActualWidth; $x++) {
        #    for ([int] $y = 0; $y -lt $this.ActualHeight; $y++) {
        #        $buffer.SetPixel($x, $y, $this.Pattern, [colors]::Blend($this.ForegroundColor, $this.BackgroundColor));
        #        $buffer.SetOpacity( $x, $y, 4 );
        #    }
        #}
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
        $textBlock = [TextBlock]::new()
        $this.SetNativeUI($textBlock)
        $this.WrapProperty("Caption", "Text")
    }
}

class CFIcon : CFLabel {
    hidden  [String] $KindName

    CFIcon() {
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

class CFCustomButton : Button {

    [Size] MeasureOverride([Size] $availableSize) {
        if (-not [System.string]::IsNullOrEmpty($this.Caption)) {
            if ($this.MaxWidth -ge 20) {
                $currentWidth = $this.Caption.Length + 5
            } else {
                $currentWidth = $this.MaxWidth
            }
            if ($this.MaxHeight -ge 20) {
                $currentHeight = 2
            } else {
                $currentHeight = $this.MaxHeight
            }
            [Size] $minButtonSize = [Size]::new($currentWidth, $currentHeight)
            return $minButtonSize;
        } else {
            return [Size]::(8, 2);
        }
    }
}

class CFButton : CFElement {
    hidden [String]  $CaptionText   = ""
    hidden [String]  $IconText      = ""

    CFButton() {
        $this.SetNativeUI([CFCustomButton]::new())
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
        $this.NativeUI.Add_OnClick({ $this.Control.OnAction() })
    }

    [void] RefreshCaption() {
        $this.NativeUI.Caption = ($this.IconText + " " + $this.CaptionText).Trim()
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
        $column.NativeUI.Margin       = [Thickness]::new(0, 0, 1, 0)
        $title = [CFLabel]::new()
        $title.NativeUI.Color = [Color]::DarkGray
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

    [void] Clear() {
        $this.Items.ToArray() | ForEach-Object {
            $this.RemoveItem($_)
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
        $this.WrapProperty("Title", "Title", "Window")
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

class CFBrowser : CFStackPanel {
    [HashTable[]]            $Data            = [HashTable[]] @()
    [int]                    $PageRows        = 10
    [int]                    $CurrentPage     = 0
    [Boolean]                $IsEditable      = $true
    [HashTable]              $CurrentRow

    #region Components Declaration

    hidden [CFListColumn[]] $Columns         = [CFListColumn[]] @()
    hidden [CFListColumn]   $EditionColumn
    hidden [CFList]         $List            = [CFList]::new()
    hidden [CFStackPanel]   $ButtonPanel     = [CFStackPanel]::new()
    hidden [CFButton]       $FirstButton     = [CFButton]::new()
    hidden [CFButton]       $PreviousButton  = [CFButton]::new()
    hidden [CFButton]       $NextButton      = [CFButton]::new()
    hidden [CFButton]       $LastButton      = [CFButton]::new()
    hidden [CFButton]       $AddNewButton    = [CFButton]::new()

    #endregion
    
    CFBrowser() {
        $this.AddScriptBlockProperty("AddNew")
        $this.AddScriptBlockProperty("Edit")
        $this.AddScriptBlockProperty("Delete")
        $this.AddChild($this.List)
        $this.AddButtons()
    }

    #region Components Creation

    hidden [void] AddButtons() {
        $this.ButtonPanel = [CFStackPanel]::new()
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

    [void] AddColumn([CFListColumn] $listColumn) {
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
        $editionPanel = [CFStackPanel]::new()
        $editionPanel.Orientation = "Horizontal"
        $listItem.AddChild($editionPanel)

        $editButton = [CFButton]::new()
        Add-Member -InputObject $editButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        $editButton.Action = {
            $this.Parent.Parent.Parent.Parent.CurrentRow = $this.CurrentRow
            $this.Parent.Parent.Parent.Parent.OnEdit()
        }
        $editionPanel.AddChild($editButton)

        $deleteButton = [CFButton]::new()
        Add-Member -InputObject $deleteButton -MemberType NoteProperty -Name CurrentRow -Value $hash
        $deleteButton.Action = {
            $this.Parent.Parent.Parent.Parent.CurrentRow = $this.CurrentRow
            $this.Parent.Parent.Parent.Parent.OnDelete()
        }
        $editionPanel.AddChild($deleteButton)
        $this.StyleEditionButtons($editButton, $deleteButton, $rowIndex)
    }

    hidden [void] AddCell([HashTable] $hash, [string] $columnName, [ListItem] $listItem, [int] $rowIndex) {
        $itemLabel = [CFLabel]::new()
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
        $this.EditionColumn = New-Object CFListColumn -Property @{Name  = "_Edition"; Title = "_"}
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
        $this.FirstButton.Caption        = "|<"
        $this.PreviousButton.Caption     = "<"
        $this.NextButton.Caption         = ">"
        $this.LastButton.Caption         = ">|"
        $this.AddNewButton.Caption       = "+"

        $this.FirstButton.NativeUI.MaxWidth     = 7
        $this.PreviousButton.NativeUI.MaxWidth  = 7
        $this.NextButton.NativeUI.MaxWidth      = 7
        $this.LastButton.NativeUI.MaxWidth      = 7
        $this.AddNewButton.NativeUI.MaxWidth    = 7

        $this.AddNewButton.NativeUI.MaxHeight   = 4
        $this.AddNewButton.NativeUI.Margin      = [Thickness]::new(6, 0, 0, 0)
    }

    [void] StyleCell($cell, [int] $rowIndex) {
        if ($this.IsEditable) {
            $cell.NativeUI.Margin       = [Thickness]::new(0, 0, 0, 1)
        }
    }

    [void] StyleEditionButtons([CFButton] $editButton, [CFButton] $deleteButton, [int] $rowIndex) {
        $editButton.Caption       = "*"
        $deleteButton.Caption     = "-"

        $editButton.NativeUI.MaxWidth     = 5
        $deleteButton.NativeUI.MaxWidth   = 5
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

class CFMenuItem : CFElement {

    CFMenuItem() {
        $this.SetNativeUI([MenuItem]::new())
        $this.WrapProperty("Caption", "Title")
        $this.AddScriptBlockProperty("Action")
        $this.NativeUI.Add_Click({ $this.Control.OnAction() })
    }

    [void] OnAction() {
        $this.InvokeTrappableCommand($this._Action, $this)
    }
}

class CFDropDownMenu : CFButton {

    CFDropDownMenu() {
        $this.NativeUI.ContextMenu = [ContextMenu]::new()
        $this.AddNativeUIChild = {
            param (
                [CFElement] $element
            )
            $this.NativeUI.ContextMenu.Items.Add($element.NativeUI)
        }
        
        $this.Action = {
            param($this)
            [WindowsHost] $windowsHost = [WindowsHost] [ConsoleFramework.ConsoleApplication]::Instance.RootControl
            $point = [Control]::TranslatePoint($this.NativeUI, [Point]::new(0, 0), $windowsHost)
            $this.NativeUI.ContextMenu.OpenMenu($windowsHost, $point)
        }
    }
    
}

class CFAutoComplete : CFTextBox {

    CFAutoComplete() {
        $this.NativeUI.ContextMenu = [ContextMenu]::new()

        $this.NativeUI.Add_KeyDown({
            if ($_.wVirtualScanCode -eq 80) {
                $this.Control.ShowDropDown()
            }
        })

        $this.AddScriptBlockProperty("ItemsRequested")

        $this.CreateMenuItems()
    }

    [void] CreateMenuItems() {
        0..19 | ForEach-Object {
            [MenuItem] $menuItem = [MenuItem] @{ Title = $_ }
            Add-Member -InputObject $menuItem -MemberType NoteProperty -Name AutoCompleteTextBox -Value $this
            Add-Member -InputObject $menuItem -MemberType NoteProperty -Name AutoCompleteId      -Value $_
            $menuItem.Add_Click({
                $this.AutoCompleteTextBox.Text = $this.AutoCompleteId
                $this.AutoCompleteTextBox.SetCursor()
            })
            $this.NativeUI.ContextMenu.Items.Add($menuItem)
        }
    }

    [void] SetCursor() {
        $position = $this.Text.Length
        $prop = $this.NativeUI.GetType().GetProperty("CursorPosition", [BindingFlags]::NonPublic -bor [BindingFlags]::Instance)
        $prop.SetValue($this.NativeUI, [Point]::new($position, 0), $null)
        $prop = $this.NativeUI.GetType().GetField("cursorPosition", [BindingFlags]::NonPublic -bor [BindingFlags]::Instance)
        $prop.SetValue($this.NativeUI, $position)
        $this.NativeUI.Invalidate()
    }

    [void] ShowDropDown() {
        $this.ClearDropDown()
        $this.AddItems()
        [WindowsHost] $windowsHost = [WindowsHost] [ConsoleFramework.ConsoleApplication]::Instance.RootControl
        $point = [Control]::TranslatePoint($this.NativeUI, [Point]::new(0, 0), $windowsHost)
        $this.NativeUI.ContextMenu.OpenMenu($windowsHost, $point)
    }
    
    [void] ClearDropDown() {
        $this.NativeUI.ContextMenu.Items | ForEach-Object {
            $_.Visibility = [Visibility]::Collapsed
        }
    }
    
    [void] AddItems() {
        $this.OnItemsRequested()
    }
    
    [void] OnItemsRequested() {
        [AutoCompleteItem[]] $items = Invoke-Command -ScriptBlock $this._ItemsRequested -ArgumentList $this | Select-Object -First 20
        0..($items.Count - 1) | ForEach-Object {
            $this.NativeUI.ContextMenu.Items.Item($_).Title            = $items[$_].Text
            $this.NativeUI.ContextMenu.Items.Item($_).AutoCompleteId   = $items[$_].Id
            $this.NativeUI.ContextMenu.Items.Item($_).Visibility       = [Visibility]::Visible
        }
    }

}

class CFCard : CFElement {
    hidden  [GroupBox]          $CardGroupBox       = [GroupBox]::new()
    hidden  [CFCustomPanel]     $BodyPanel          = [CFCustomPanel]::new()
    hidden                      $CurrentIcon        = [CFIcon]::new()
    hidden  [String]            $Title              = ""

    CFCard() {
        $this.SetNativeUI($this.CardGroupBox)
        $this.CardGroupBox.Content = $this.BodyPanel

        Add-Member -InputObject $this -Name Caption -MemberType ScriptProperty -Value {
            $this.Title
        } -SecondValue {
            $this.Title = $args[0]
            $this.Render()
        }
        Add-Member -InputObject $this -Name Icon -MemberType ScriptProperty -Value {
            $this.CurrentIcon
        } -SecondValue {
            $this.CurrentIcon = $args[0]
            $this.Render()
        }
        $this.AddNativeUIChild = {
            param (
                [CFElement] $element
            )
            $this.BodyPanel.xChildren.Add($element.NativeUI) | Out-Null
        }
        $this.Render()
    }

    [void] Render() {
        if ($this.CurrentIcon -ne $null) {
            $this.CardGroupBox.Title = $this.CurrentIcon.Caption + " " + $this.Title
        } else {
            $this.CardGroupBox.Title = $this.Title
        }
        $this.StyleComponents()
    }

    [void] StyleComponents() {
        $this.BodyPanel.Margin          = [Thickness]::new(1, 1, 1, 0)
    }
}