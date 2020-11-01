using namespace Ooui

class MaterialOouiHost : OouiHost {

    MaterialOouiHost() {
        [UI]::HeadHtml = '
            <link href="https://maxcdn.bootstrapcdn.com/font-awesome/latest/css/font-awesome.min.css" rel="stylesheet">
            <link href="https://demos.creative-tim.com/material-dashboard/assets/css/material-dashboard.min.css?v=2.1.2" rel="stylesheet">
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
                    color: #fff;
                    background-color: #9c27b0;
                    box-shadow: 0px 4px 20px 0px rgba(0,0,0,0.14), 0px 7px 10px -5px rgba(156,39,176,0.4);
                }
            </style>
        '
    }
}

class MaterialOouiWindow : OouiWindow {
}

class MaterialOouiStackPanel : OouiStackPanel {
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
}

class MaterialOouiMenuItem : OouiMenuItem {
}

class MaterialOouiDropDownMenu : OouiDropDownMenu {
}

class MaterialOouiAutoComplete : OouiAutoComplete {
}
