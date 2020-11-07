using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

function Get-UIHost {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType
    )
    New-Object ($UIType.ToString() + "Host")
}

function Get-UIWindow {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Loaded       = {},
        [ScriptBlock]  $Components   = {},
        [String]       $Caption      = ""
    )
    $window = New-Object ($UIType.ToString() + "Window")
    $window.Loaded = $Loaded
    $window.Caption = $Caption
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $window.AddChild($_)
    }
    $window.OnLoaded()
    $window
}

function Get-UIButton {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Action       = {},
        [String]       $Caption      = "",
        [String]       $Name         = ""
    )
    $button = New-Object ($UIType.ToString() + "Button")
    $button.Action     = $Action
    $button.Caption    = $Caption
    $button.Name       = $Name
    $button
}

function Get-UIStackPanel {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [Orientation]  $Orientation  = [Orientation]::Vertical,
        [ScriptBlock]  $Components   = {}
    )
    $stackPanel = New-Object ($UIType.ToString() + "StackPanel")
    $stackPanel.Orientation = $Orientation
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $stackPanel.AddChild($_)
    }
    $stackPanel
}

function Get-UILabel {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [String]       $Caption      = "",
        [String]       $Name         = ""
    )
    $label = New-Object ($UIType.ToString() + "Label")
    $label.Caption    = $Caption
    $label.Name       = $Name
    $label
}

function Get-UITextBox {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Change       = {},
        [String]       $Text         = "",
        [String]       $Name         = ""
    )
    $textBox = New-Object ($UIType.ToString() + "TextBox")
    $textBox.Change     = $Change
    $textBox.Text       = $Text
    $textBox.Name       = $Name
    $textBox
}

function Get-UICheckBox {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Click        = {},
        [Boolean]      $IsChecked    = $false,
        [String]       $Caption      = "",
        [String]       $Name         = ""
    )
    $checkBox = New-Object ($UIType.ToString() + "CheckBox")
    $checkBox.Click      = $Click
    $checkBox.IsChecked  = $IsChecked
    $checkBox.Caption    = $Caption
    $checkBox.Name       = $Name
    $checkBox
}

function Get-UIRadioButton {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Click        = {},
        [Boolean]      $IsChecked    = $false,
        [String]       $Caption      = "",
        [String]       $Name         = ""
    )
    $radioButton = New-Object ($UIType.ToString() + "RadioButton")
    $radioButton.Click      = $Click
    $radioButton.IsChecked  = $IsChecked
    $radioButton.Caption    = $Caption
    $radioButton.Name       = $Name
    $radioButton
}

function Get-UIRadioGroup {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Components   = {},
        [String]       $Name         = ""
    )
    $radioGroup = New-Object ($UIType.ToString() + "RadioGroup")
    $radioGroup.Name       = $Name
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $radioGroup.AddChild($_)
    }
    $radioGroup
}

function Get-UIList {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Columns      = {},
        [ScriptBlock]  $Items        = {},
        [String]       $Name         = ""
    )
    $list = New-Object ($UIType.ToString() + "List")
    $list.Name       = $Name
    $columnElements = Invoke-Command -ScriptBlock $Columns
    $columnElements | ForEach-Object {
        $list.AddColumn($_)
    }
    $itemElements = Invoke-Command -ScriptBlock $Items
    $itemElements | ForEach-Object {
        $list.AddItem($_)
    }
    $list
}

function Get-UIListColumn {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [String]       $Title        = "",
        [String]       $Name         = ""
    )
    $listColumn = New-Object ($UIType.ToString() + "ListColumn")
    $listColumn.Name       = $Name
    $listColumn.Title      = $Title
    $listColumn
}

function Get-UIListItem {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Components   = {},
        [String]       $Name         = ""
    )
    $listItem = New-Object ListItem
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $listItem.AddChild($_)
    }
    $listItem
}

function Get-UITabItem {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Components   = {},
        [String]       $Caption      = "",
        [String]       $Name         = ""
    )
    $tabItem = New-Object ($UIType.ToString() + "TabItem")
    $tabItem.Caption = $Caption
    $tabItem.Name    = $Name
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $tabItem.AddChild($_)
    }
    $tabItem
}

function Get-UITabControl {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Components   = {},
        [String]       $Name         = ""
    )
    $tabControl = New-Object ($UIType.ToString() + "TabControl")
    $tabControl.Name    = $Name
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $tabControl.AddChild($_)
    }
    $tabControl
}

function Get-UIModal {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [String]       $Title        = "",
        [ScriptBlock]  $Components   = {},
        [String]       $Name         = ""
    )
    $modal = New-Object ($UIType.ToString() + "Modal")
    $modal.Name       = $Name
    $modal.Title      = $Title
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $modal.AddChild($_)
    }
    $modal
}

function Get-UITimer {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Elapsed      = {},
        [double]       $Interval     = 1000,
        [String]       $Name         = ""
    )
    $timer = New-Object ($UIType.ToString() + "Timer")
    $timer.Elapsed    = $Elapsed
    $timer.Interval   = $Interval
    $timer.Name       = $Name
    $timer
}

function Get-UIDatePicker {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Change       = {},
        [DateTime]     $Value        = [DateTime]::Today,
        [String]       $Name         = ""
    )
    $datePicker = New-Object ($UIType.ToString() + "DatePicker")
    $datePicker.Change     = $Change
    $datePicker.Value      = $Value
    $datePicker.Name       = $Name
    $datePicker
}

function Get-UITimePicker {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Change       = {},
        [String]       $Value        = "00:00",
        [String]       $Name         = ""
    )
    $timePicker = New-Object ($UIType.ToString() + "TimePicker")
    $timePicker.Change     = $Change
    $timePicker.Value      = $Value
    $timePicker.Name       = $Name
    $timePicker
}

function Get-UIBrowser {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Columns      = {},
        [HashTable[]]  $Data         = [HashTable[]] @(),
        [int]          $PageRows     = 10,
        [ScriptBlock]  $AddNew       = {},
        [ScriptBlock]  $Edit         = {},
        [ScriptBlock]  $Delete       = {},
        [String]       $Name         = ""
    )
    $browser = New-Object ($UIType.ToString() + "Browser")
    $browser.Name       = $Name
    $columnElements = Invoke-Command -ScriptBlock $Columns
    $columnElements | ForEach-Object {
        $browser.AddColumn($_)
    }
    $browser.Data = $Data
    $browser.PageRows = $PageRows
    $browser.CreateList()
    $browser.Refresh()
    $browser.AddNew = $AddNew
    $browser.Edit   = $Edit
    $browser.Delete = $Delete
    $browser
}

function Get-UIMenuItem {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [ScriptBlock]  $Action       = {},
        [String]       $Caption      = "",
        [String]       $Name         = ""
    )
    $menuItem = New-Object ($UIType.ToString() + "MenuItem")
    $menuItem.Action     = $Action
    $menuItem.Caption    = $Caption
    $menuItem.Name       = $Name
    $menuItem
}

function Get-UIDropDownMenu {
    param (
        [UIType]       $UIType       = [UIConfig]::UIType,
        [String]       $Caption      = "",
        [ScriptBlock]  $Components   = {},
        [String]       $Name         = ""
    )
    $dropDownMenu = New-Object ($UIType.ToString() + "DropDownMenu")
    $dropDownMenu.Caption    = $Caption
    $dropDownMenu.Name       = $Name
    $childElements = Invoke-Command -ScriptBlock $Components
    $childElements | ForEach-Object {
        $dropDownMenu.AddChild($_)
    }
    $dropDownMenu
}

function Get-UIAutoComplete {
    param (
        [UIType]       $UIType         = [UIConfig]::UIType,
        [ScriptBlock]  $ItemsRequested = {param($this) "sample" },
        [String]       $Text           = "",
        [String]       $Name           = ""
    )
    $autoComplete = New-Object ($UIType.ToString() + "AutoComplete")
    #$autoComplete.Text                = $Text
    $autoComplete.Name                 = $Name
    $autoComplete.ItemsRequested       = $ItemsRequested
    $autoComplete
}

function Get-UIAutoCompleteItem {
    param (
        [String]  $Id,
        [String]  $Text
    )
    [AutoCompleteItem] @{ Id = $Id; Text = $Text }
}