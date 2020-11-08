using namespace System.Collections.Generic
using namespace System.Windows
using namespace System.Windows.Controls
using namespace MaterialDesignThemes.Wpf

class MaterialWPFHost : UIHost {
    [HashTable]  $SyncHash
                 $UIRunspace

    [void] ShowFrame([ScriptBlock] $frameScriptBlock) {
        $window = Invoke-Command -ScriptBlock $frameScriptBlock
        $window.ShowDialog()
    }
}

class MaterialWPFWindow : WindowBase {
    [Application]  $Application   = [System.Windows.Application]::new()

    MaterialWPFWindow() {
        $this.StyleApplication()
        $windowNativeUI = [Window]::new()
        $windowNativeUI.SizeToContent = 'WidthAndHeight'
        $windowNativeUI.Margin        = 10
        $windowNativeUI.FontFamily = "MaterialDesignFont"
        $windowNativeUI.SetResourceReference([Control]::BackgroundProperty, "MaterialDesignPaper")
        $this.Application.MainWindow = $windowNativeUI

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

    hidden [void] StyleApplication() {
        $uris =
        "/MaterialDesignThemes.Wpf;component/Themes/MaterialDesignTheme.Light.xaml",
        "/MaterialDesignThemes.Wpf;component/Themes/MaterialDesignTheme.Defaults.xaml",
        "/MaterialDesignColors;component/Themes/Recommended/Primary/MaterialDesignColor.DeepPurple.xaml",
        "/MaterialDesignColors;component/Themes/Recommended/Accent/MaterialDesignColor.Lime.xaml"

        $uris | ForEach-Object {
            $resourceDictionary = [System.Windows.ResourceDictionary] [System.Windows.Application]::LoadComponent([Uri]::new($_, [System.UriKind]::Relative))
            $this.Application.Resources.MergedDictionaries.Add($resourceDictionary)
        }
    }

    [void] ShowDialog() {
        $this.NativeUI.ShowDialog()
        #$this.Application.Run()
    }

    [void] OnLoaded() {
        Invoke-Command -ScriptBlock $this._Loaded -ArgumentList $this
    }

}

class MaterialWPFStackPanel : WPFStackPanel {
}

class MaterialWPFIcon : WPFElement {

    MaterialWPFIcon() {
        $this.NativeUI = [MaterialDesignThemes.Wpf.PackIcon]::new()
        Add-Member -InputObject $this -Name Kind -MemberType ScriptProperty -Value {
            $this.NativeUI.Kind
        } -SecondValue {
            $this.NativeUI.Kind = $args[0]
        }
    }
}

class MaterialWPFLabel : WPFLabel {
}

class MaterialWPFButton : WPFButton {

    MaterialWPFButton() {
        $this.NativeUI.SetResourceReference([Control]::StyleProperty, "MaterialDesignRaisedButton")
    }
}

class MaterialWPFTextBox : WPFTextBox {
}

class MaterialWPFCheckBox : WPFCheckBox {

    MaterialWPFCheckBox() {
        $this.NativeUI.SetResourceReference([Control]::StyleProperty, "MaterialDesignCheckBox")
    }
}

class MaterialWPFRadioButton : WPFRadioButton {

    MaterialWPFCheckBox() {
        $this.NativeUI.SetResourceReference([Control]::StyleProperty, "MaterialDesignRadioButton")
    }
}

class MaterialWPFRadioGroup : WPFRadioGroup {
}

class MaterialWPFList : WPFList {
}

class MaterialWPFListColumn : WPFListColumn {
}

class MaterialWPFTabItem : WPFTabItem {
}

class MaterialWPFTabControl : WPFTabControl {
}

class MaterialWPFModal : WPFElement {
    [StackPanel]   $Stack
    [Window]       $ModalWindow

    MaterialWPFModal() {
        $this.Stack = [StackPanel]::new()
        $this.SetNativeUI($this.Stack)

        $this.ModalWindow = [Window]::new()
        $this.ModalWindow.WindowStyle = [WindowStyle]::SingleBorderWindow
        $this.ModalWindow.SizeToContent = 'WidthAndHeight'
        $this.ModalWindow.Margin        = 10
        $this.ModalWindow.Content       = [StackPanel]::new()
        $this.WrapProperty("Title", "Title", "ModalWindow")

        $this.AddNativeUIChild = {
            param (
                [WPFElement] $element
            )
            $this.ModalWindow.Content.AddChild($element.NativeUI) | Out-Null
        }
    }

    [void] Show() {
        $this.ModalWindow.WindowStartupLocation = "CenterOwner"
        $this.ModalWindow.ShowDialog()
    }

    [void] Hide() {
        $this.ModalWindow.Hide()
    }
}

class MaterialWPFTimer : WPFTimer {
}

class MaterialWPFDatePicker : WPFElement {

    MaterialWPFDatePicker() {
        $datePicker = [DatePicker]::new()
        $datePicker.Width = 100
        $datePicker.SetResourceReference([Control]::StyleProperty, "MaterialDesignFloatingHintDatePicker")
        $datePicker.SetValue([HintAssist]::HintProperty, "Hola")
        $this.SetNativeUI($datePicker)

        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_SelectedDateChanged({ $this.Control.OnChange() })
        $this.AddScriptBlockProperty("LostFocus")
        $this.NativeUI.Add_LostFocus({ $this.Control.OnLostFocus() })
        
        $this.WrapProperty("Value", "SelectedDate")
    }

    [void] OnChange() {
        $this.InvokeTrappableCommand($this._Change, $this)
    }
    
    [void] OnLostFocus() {
        $this.InvokeTrappableCommand($this._LostFocus, $this)
    }
}

class MaterialWPFTimePicker : WPFElement {

    MaterialWPFTimePicker() {
        $timePicker = [TimePicker]::new()
        $timePicker.Width = 100
        $timePicker.SetResourceReference([Control]::StyleProperty, "MaterialDesignFloatingHintTimePicker")
        $timePicker.SetValue([HintAssist]::HintProperty, "Hola")
        $timePicker.Is24Hours = $true
        $this.SetNativeUI($timePicker)

        $this.AddScriptBlockProperty("Change")
        $this.NativeUI.Add_SelectedTimeChanged({ $this.Control.OnChange() })
        $this.AddScriptBlockProperty("LostFocus")
        $this.NativeUI.Add_LostFocus({ $this.Control.OnLostFocus() })
        
        $this.WrapProperty("Value", "SelectedTime")
    }

    [void] OnChange() {
        $this.InvokeTrappableCommand($this._Change, $this)
    }
    
    [void] OnLostFocus() {
        $this.InvokeTrappableCommand($this._LostFocus, $this)
    }
}

class MaterialWPFBrowser : WPFBrowser {

    [void] StyleComponents() {
        $this.StyleButton($this.FirstButton,     "ArrowCompressLeft",   "MaterialDesignIconButton")
        $this.StyleButton($this.PreviousButton,  "ArrowLeft",           "MaterialDesignIconButton")
        $this.StyleButton($this.NextButton,      "ArrowForward",        "MaterialDesignIconButton")
        $this.StyleButton($this.LastButton,      "ArrowCompressRight",  "MaterialDesignIconButton")

        $this.StyleButton($this.AddNewButton,    "Plus",                "MaterialDesignFloatingActionAccentButton")

        $this.FirstButton.Parent.NativeUI.Margin = "0 -10 0 10"
        $this.AddNewButton.NativeUI.Margin = "100 10 10 10"
    }

    [void] StyleButton($button, $iconKind, $styleName) {
        $button.NativeUI.Content = New-Object PackIcon -Property @{ Kind = $iconKind }
        $button.NativeUI.Margin       = 0
        $button.NativeUI.SetResourceReference([Control]::StyleProperty, $styleName)
    }

    [void] StyleEditionButtons([WPFButton] $editButton, [WPFButton] $deleteButton, [int] $rowIndex) {
        $editButton.Parent.NativeUI.Background  = $this.GetRowBackground($rowIndex)

        $this.StyleButton($editButton,      "ModeEdit",        "MaterialDesignIconMiniButton")
        $this.StyleButton($deleteButton,    "WindowClose",     "MaterialDesignIconMiniButton")

        $editButton.NativeUI.Background      = [System.Windows.Media.Brushes]::Transparent
        $deleteButton.NativeUI.Background    = [System.Windows.Media.Brushes]::Transparent
        
        $editButton.NativeUI.Foreground      = [System.Windows.Media.Brushes]::Green
        $deleteButton.NativeUI.Foreground    = [System.Windows.Media.Brushes]::Red
        
        $editButton.NativeUI.BorderThickness     = 0
        $deleteButton.NativeUI.BorderThickness   = 0
    }

}

class MaterialWPFMenuItem : WPFMenuItem {
}

class MaterialWPFDropDownMenu : WPFDropDownMenu {   
}

class MaterialWPFAutoComplete : WPFAutoComplete {
}
