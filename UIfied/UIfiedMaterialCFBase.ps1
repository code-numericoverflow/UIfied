using namespace System.Collections.Generic
using namespace System.Reflection
using namespace ConsoleFramework
using namespace ConsoleFramework.Core
using namespace ConsoleFramework.Native
using namespace ConsoleFramework.Controls
using namespace ConsoleFramework.Events
using namespace ConsoleFramework.Rendering

# Font Creation https://www.calligraphr.com/

class MaterialCFHost : CFHost {
}

class MaterialCFWindow : CFWindow {

    MaterialCFWindow() {
        [CFCustomPanel]::DefaultBackgroundColor = [color]::White
    }
}

class MaterialCFStackPanel : CFStackPanel {
}

class MaterialCFLabel : CFLabel {

    MaterialCFLabel() {
        $this.NativeUI.Color  = [Color]::DarkGray
    }
}

class MaterialCFIcon : CFIcon {
}

class MaterialCFButton : CFButton {

    MaterialCFButton() {
        $this.NativeUI.Style = "Primary"
    }
}

class MaterialCFTextBox : CFTextBox {

    MaterialCFTextBox() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFPassword : CFTextBox {

    MaterialCFPassword() {
        $this.NativeUI.Style = "FlatPassword"
    }
}

class MaterialCFCheckBox : CFCheckBox {

    MaterialCFCheckBox() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFRadioButton : CFRadioButton {

    MaterialCFRadioButton() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFRadioGroup : CFRadioGroup {
}

class MaterialCFList : CFList {

    MaterialCFList() {
        $this.NativeUI.BackgroundColor = [color]::White
    }
}

class MaterialCFListColumn : CFListColumn {
}

class MaterialCFTabItem : CFTabItem {
}

class MaterialCFTabControl : CFTabControl {
    
    MaterialCFTabControl() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFModal : CFModal {
}

class MaterialCFTimer : CFTimer {
}

class MaterialCFDatePicker : CFDatePicker {

    MaterialCFDatePicker() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFTimePicker : CFTimePicker {

    MaterialCFTimePicker() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFBrowser : CFBrowser {

    [void] StyleEditionButtons([CFButton] $editButton, [CFButton] $deleteButton, [int] $rowIndex) {
        $editButton.Icon                         = [MaterialCFIcon] @{ Kind = "edit" }
        $editButton.NativeUI.Style               = "Flat"
        $editButton.NativeUI.ForegroundColor     = [Color]::DarkGreen

        $deleteButton.Icon                       = [MaterialCFIcon] @{ Kind = "delete" }
        $deleteButton.NativeUI.Style             = "Flat"
        $deleteButton.NativeUI.ForegroundColor   = [Color]::Red

        $editButton.NativeUI.MaxWidth     = 5
        $deleteButton.NativeUI.MaxWidth   = 5
    }

    [void] StyleComponents() {
        $this.FirstButton.Icon                         = [MaterialCFIcon] @{ Kind = "first_page" }
        $this.FirstButton.NativeUI.Style               = "Flat"
        $this.FirstButton.NativeUI.ForegroundColor     = [Color]::Magenta

        $this.PreviousButton.Icon                      = [MaterialCFIcon] @{ Kind = "chevron_left" }
        $this.PreviousButton.NativeUI.Style            = "Flat"
        $this.PreviousButton.NativeUI.ForegroundColor  = [Color]::Magenta

        $this.NextButton.Icon                          = [MaterialCFIcon] @{ Kind = "chevron_right" }
        $this.NextButton.NativeUI.Style                = "Flat"
        $this.NextButton.NativeUI.ForegroundColor      = [Color]::Magenta

        $this.LastButton.Icon                          = [MaterialCFIcon] @{ Kind = "last_page" }
        $this.LastButton.NativeUI.Style                = "Flat"
        $this.LastButton.NativeUI.ForegroundColor      = [Color]::Magenta

        $this.AddNewButton.Icon                        = [MaterialCFIcon] @{ Kind = "add" }
        $this.AddNewButton.NativeUI.Style              = "Pill"
        $this.AddNewButton.NativeUI.ForegroundColor    = [Color]::Black
        $this.AddNewButton.NativeUI.BackgroundColor    = [Color]::Green

        $this.FirstButton.NativeUI.MaxWidth     = 7
        $this.PreviousButton.NativeUI.MaxWidth  = 7
        $this.NextButton.NativeUI.MaxWidth      = 7
        $this.LastButton.NativeUI.MaxWidth      = 7
        $this.AddNewButton.NativeUI.MaxWidth    = 7

        $this.AddNewButton.NativeUI.MaxHeight   = 4
        $this.AddNewButton.NativeUI.Margin      = [Thickness]::new(6, 0, 0, 0)
    }
}

class MaterialCFMenuItem : CFMenuItem {

    MaterialCFMenuItem() {
        $this.NativeUI.BackgroundColor = [Color]::Magenta
    }
}

class MaterialCFDropDownMenu : CFDropDownMenu {

    MaterialCFDropDownMenu() {
        $this.NativeUI.Style = "Primary"
    }
}

class MaterialCFAutoComplete : CFAutoComplete {

    MaterialCFAutoComplete() {
        $this.NativeUI.Style = "Flat"
    }

    [void] StyleMenuItem($menuItem) {
        $menuItem.BackgroundColor = [Color]::Magenta
    }
}

class MaterialCFCard : CFCard {
}

class MaterialCFImage : CFImage {
}

class MaterialCFTextEditor : CFTextEditor {
}

class MaterialCFExpander : CFExpander {
}

class MaterialCFInteger : CFInteger {

    MaterialCFInteger() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFDouble : CFDouble {

    MaterialCFDouble() {
        $this.NativeUI.Style = "Flat"
    }
}

class MaterialCFComboBoxItem : CFComboBoxItem {

    MaterialCFComboBoxItem() {
        $this.NativeUI.BackgroundColor = [Color]::Magenta
    }
}

class MaterialCFComboBox : CFComboBox {

    MaterialCFComboBox() {
        $this.NativeUI.Style = "Primary"
    }
}
