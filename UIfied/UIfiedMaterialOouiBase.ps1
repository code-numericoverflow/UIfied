using namespace Ooui

class MaterialOouiHost : OouiHost {

    MaterialOouiHost() {
        [UI]::HeadHtml = '
            <link href="https://demos.creative-tim.com/material-dashboard/assets/css/material-dashboard.min.css?v=2.1.2" rel="stylesheet">
            <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500,700|Roboto+Slab:400,700|Material+Icons" rel="stylesheet" type="text/css" />
            <style>
                .nav-pills .nav-item .nav-link {
                    line-height: 24px;
                    text-transform: uppercase;
                    font-size: 12px;
                    font-weight: 500;
                    min-width: 100px;
                    text-align: center;
                    color: #555;
                    transition: all .3s;
                    border-radius: 30px;
                    padding: 10px 15px;
                }
                .nav-pills .nav-item .nav-link.active {
                    border-radius: unset;
                    background-color: transparent;
                    padding-bottom: 0px;
                    border-bottom-width: 4px;
                    border-bottom-style: solid;
                    border-bottom-color: lime;
                    margin-bottom: 7px;
                }
                .UIList .form-check {
                    margin-bottom: 0px;
                }
                .UIList .form-check .form-check-label {
                    white-space: nowrap;
                    position: relative;
                    vertical-align: top;
                }
                .card {
                    margin: 50px 20px;
                    width: auto !important;
                }
                .card-title {
                    white-space: nowrap;
                }
            </style>
        '
        [UI]::BodyFooterHtml = ''
    }
}

class MaterialOouiWindow : OouiWindow {
}

class MaterialOouiStackPanel : OouiStackPanel {
}

class MaterialOouiIcon : OouiIcon {
}

class MaterialOouiLabel : OouiLabel {
}

class MaterialOouiButton : OouiButton {
}

class MaterialOouiTextBox : OouiTextBox {

    MaterialOouiTextBox() {
        $this.NativeUI.ClassName = "form-control"
    }
    
}

class MaterialOouiCheckBox : OouiElement {

#  <div class="form-check">
#      <label class="form-check-label">
#          <input class="form-check-input" type="checkbox" value="">
#          Option one is this
#          <span class="form-check-sign">
#              <span class="check"></span>
#          </span>
#      </label>
#  </div>

    hidden [Div]   $ListNativeUI         = [Div]::new()
    hidden [Label] $CheckLabelNativeUI   = [Label]::new()
    hidden [Input] $CheckBoxNativeUI     = [Input]::new("CheckBox")
    hidden [Span]  $SignNativeUI         = [span]::new()
    hidden [Span]  $SpanNativeUI         = [span]::new()
    hidden [Span]  $LabelTextNativeUI    = [span]::new()

    MaterialOouiCheckBox() {
        $this.ListNativeUI.ClassName        = "form-check"
        $this.CheckLabelNativeUI.ClassName  = "form-check-label"
        $this.CheckBoxNativeUI.ClassName    = "form-check-input"
        $this.SignNativeUI.ClassName        = "form-check-sign"
        $this.SpanNativeUI.ClassName        = "check"

        $this.LabelTextNativeUI.Style.PaddingLeft = "25px"

        $this.ListNativeUI.AppendChild($this.CheckLabelNativeUI)
        $this.CheckLabelNativeUI.AppendChild($this.CheckBoxNativeUI)
        $this.CheckLabelNativeUI.AppendChild($this.SignNativeUI)
        $this.CheckLabelNativeUI.AppendChild($this.LabelTextNativeUI)
        $this.SignNativeUI.AppendChild($this.SpanNativeUI)
        $this.SetNativeUI($this.ListNativeUI)

        $this.WrapProperty("Caption", "Text", "LabelTextNativeUI")
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

class MaterialOouiRadioButton : OouiElement {

#<div class="form-check form-check-radio">
#    <label class="form-check-label">
#        <input class="form-check-input" type="radio" name="exampleRadios" id="exampleRadios1" value="option1" >
#        Radio is off
#        <span class="circle">
#            <span class="check"></span>
#        </span>
#    </label>
#</div>

    hidden [Div]   $ListNativeUI         = [Div]::new()
    hidden [Label] $CheckLabelNativeUI   = [Label]::new()
    hidden [Input] $RadioButtonNativeUI     = [Input]::new("Radio")
    hidden [Span]  $SignNativeUI         = [span]::new()
    hidden [Span]  $SpanNativeUI         = [span]::new()
    hidden [Span]  $LabelTextNativeUI    = [span]::new()

    MaterialOouiRadioButton() {
        $this.ListNativeUI.ClassName        = "form-check"
        $this.CheckLabelNativeUI.ClassName  = "form-check-label"
        $this.RadioButtonNativeUI.ClassName    = "form-check-input"
        $this.SignNativeUI.ClassName        = "circle"
        $this.SpanNativeUI.ClassName        = "check"

        $this.LabelTextNativeUI.Style.PaddingLeft = "25px"

        $this.ListNativeUI.AppendChild($this.CheckLabelNativeUI)
        $this.CheckLabelNativeUI.AppendChild($this.RadioButtonNativeUI)
        $this.CheckLabelNativeUI.AppendChild($this.SignNativeUI)
        $this.CheckLabelNativeUI.AppendChild($this.LabelTextNativeUI)
        $this.SignNativeUI.AppendChild($this.SpanNativeUI)
        $this.SetNativeUI($this.ListNativeUI)

        $this.WrapProperty("Caption", "Text", "LabelTextNativeUI")
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

class MaterialOouiRadioGroup : OouiRadioGroup {
}

class MaterialOouiList : OouiList {
}

class MaterialOouiListColumn : OouiListColumn {
}

class MaterialOouiTabItem : OouiTabItem {
}

class MaterialOouiTabControl : OouiTabControl {

    RefreshStyle() {
        $this.List.ClassName = "nav nav-pills nav-pills-primary"
    }

}

class MaterialOouiModal : OouiModal {
}

class MaterialOouiTimer : OouiTimer {
}

class MaterialOouiDatePicker : OouiDatePicker {
}

class MaterialOouiTimePicker : OouiTimePicker {
}

class MaterialOouiBrowser : OouiBrowser {

    [void] StyleComponents() {
        $this.List.NativeUI.ClassName   = "UIList table"

        $this.FirstButton.Icon        = [OouiIcon] @{ Kind = "first_page"    }
        $this.PreviousButton.Icon     = [OouiIcon] @{ Kind = "chevron_left"  }
        $this.NextButton.Icon         = [OouiIcon] @{ Kind = "chevron_right" }
        $this.LastButton.Icon         = [OouiIcon] @{ Kind = "last_page"     }
        $this.AddNewButton.Icon       = [OouiIcon] @{ Kind = "add"           }

        $this.FirstButton.NativeUI.ClassName        = "btn btn-primary btn-link"
        $this.PreviousButton.NativeUI.ClassName     = "btn btn-primary btn-link"
        $this.NextButton.NativeUI.ClassName         = "btn btn-primary btn-link"
        $this.LastButton.NativeUI.ClassName         = "btn btn-primary btn-link"
        $this.AddNewButton.NativeUI.ClassName       = "btn btn-fab btn-round btn-lg"

        $this.AddNewButton.NativeUI.Style.BackgroundColor = "lime"
    }

    [void] StyleEditionButtons([OouiButton] $editButton, [OouiButton] $deleteButton, [int] $rowIndex) {
        $editButton.Icon     = [MaterialOouiIcon] @{ Kind = "edit"  }
        $deleteButton.Icon   = [MaterialOouiIcon] @{ Kind = "close" }
        
        $editButton.NativeUI.ClassName          = "btn btn-success btn-link btn-sm"
        $deleteButton.NativeUI.ClassName        = "btn btn-danger  btn-link btn-sm"
        $editButton.Parent.NativeUI.ClassName   = "td-actions"
    }

}

class MaterialOouiMenuItem : OouiMenuItem {
}

class MaterialOouiDropDownMenu : OouiDropDownMenu {
}

class MaterialOouiAutoComplete : OouiAutoComplete {
}

class MaterialOouiCard : OouiCard {
}

class MaterialOouiImage : OouiImage {
}

class MaterialOouiTextEditor : OouiTextEditor {
}

class MaterialOouiExpander : OouiElement {
    hidden  [div]               $ExpanderContainerDiv     = [div]::new()
    hidden  [div]               $ExpanderHeaderDiv        = [div]::new()
    hidden  [div]               $ExpanderButtonDiv        = [div]::new()
    hidden  [OouiStackPanel]    $ExpanderBodyDiv          = [OouiStackPanel]::new()
    hidden  [Button]            $ExpanderButton           = [Button]::new()
    hidden  [Heading]           $Header                   = [Heading]::new(3)
    hidden  [Icon]              $ExpanderIcon             = [Icon]::new()

    MaterialOouiExpander() {
        $this.SetNativeUI($this.ExpanderContainerDiv)
        $this.ExpanderContainerDiv.AppendChild($this.ExpanderHeaderDiv)
        $this.ExpanderContainerDiv.AppendChild($this.ExpanderBodyDiv.NativeUI)
        $this.ExpanderHeaderDiv.AppendChild($this.ExpanderButtonDiv)
        $this.ExpanderHeaderDiv.AppendChild($this.Header)
        $this.ExpanderButtonDiv.AppendChild($this.ExpanderButton)
        $this.ExpanderButton.AppendChild($this.ExpanderIcon)
        
        $this.WrapProperty("Caption", "Text", "Header")
        $this.AddNativeUIChild = {
            param (
                [OouiElement] $element
            )
            $listItem = [Div]::new()
            if ($this.ExpanderBodyDiv.Orientation -eq [Orientation]::Horizontal) {
                $listItem.Style.float = "left"
            } else {
                $listItem.Style.clear = "both"
            }
            $this.ExpanderBodyDiv.NativeUI.AppendChild($listItem) | Out-Null
            $listItem.AppendChild($element.NativeUI) | Out-Null
        }
        Register-ObjectEvent -InputObject $this.ExpanderButton -EventName Click -MessageData $this -Action {
            $this = $event.MessageData
            $this.ToogleContent()
        } | Out-Null
        $this.StyleComponents()
    }

    [void] StyleComponents() {
        $this.ExpanderButton.ClassName                    = "btn btn-primary btn-link btn-sm"
        $this.ExpanderButton.Style.Padding                = "0"
        $this.ExpanderIcon.ClassName                      = "material-icons"
        $this.ExpanderIcon.Text                           = "expand_less"
        $this.ExpanderButtonDiv.Style.float               = "left"
        $this.Header.Style.display                        = "inline"
        $this.ExpanderIcon.Style.FontSize                 = "2rem"
        $this.ExpanderHeaderDiv.Style.BorderBottomStyle   = "solid"
        $this.ExpanderHeaderDiv.Style.BorderBottomColor   = "#ddd"
        $this.ExpanderHeaderDiv.Style.BorderBottomWidth   = "1px"
    }

    [void] ToogleContent() {
        $this.ExpanderBodyDiv.Visible = -not $this.ExpanderBodyDiv.Visible
        if ($this.ExpanderIcon.Text -eq "expand_more") {
            $this.ExpanderIcon.Text = "expand_less"
        } else {
            $this.ExpanderIcon.Text = "expand_more"
        }
    }
}

class MaterialOouiInteger : OouiInteger {

    MaterialOouiInteger() {
        $this.NativeUI.ClassName = "form-control"
    }
}

class MaterialOouiDouble : OouiDouble {

    MaterialOouiDouble() {
        $this.NativeUI.ClassName = "form-control"
    }
}

class MaterialOouiComboBoxItem : OouiComboBoxItem {
}

class MaterialOouiCombobox : OouiCombobox {
}
