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

    hidden [void] CreateEditionColumn() {
        $this.EditionColumn = New-Object WPFListColumn -Property @{Name  = "_Edition"; Title = " "}
        $this.AddColumn($this.EditionColumn)
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
        $itemLabel = [WPFLabel]::new()
        $itemLabel.Caption = $hash."$columnName"
        $this.StyleCell($itemLabel, $rowIndex)
        $listItem.AddChild($itemLabel)
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