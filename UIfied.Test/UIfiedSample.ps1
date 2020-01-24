
Import-Module "$PSScriptRoot\..\UIfied"

$wsb = {
    Window -Caption "My Title" -Loaded {
            param ($this)
            $this.Form.Caption = $this.Form.Caption + " Loaded => " + (Get-Date).ToString()
        } -Components {
        StackPannel -Orientation Vertical -Components {
            Get-Timer  -Name Timer -Elapsed {
                param ($this)
                $this.Form.TimerLabel.Caption = Get-Date
            }
            Get-Label    -Caption "Label Sample"
            TabControl -Components {
                TabItem -Caption "Buttons" -Components {
                    Get-Label    -Caption "Button" -Name ButtonLabel
                    Button   -Caption "Change"  -Action {
                        param($this)
                        $this.Form.ButtonLabel.Caption = Get-Date
                    }
                }
                TabItem -Caption "TextBoxes" -Components {
                    Get-Label    -Caption "TextBox Sample" -Name TextBoxLabel
                    TextBox  -Change {
                        param($this)
                        $this.Form.TextBoxLabel.Caption = $this.Control.Text
                    }
                }
                TabItem -Caption "Lists" -Components {
                    List -Name Grid -Columns {
                        ListColumn -Title "Column 1"
                        ListColumn -Title "Column 2"
                    } -Items {
                        ListItem -Components {
                            Get-Label -Caption "Cell 1,1"
                            CheckBox -Caption "Cell 1,2"
                        }
                        ListItem -Components {
                            Get-Label -Caption "Cell 2,1"
                            CheckBox -Caption "Cell 2,2"
                        }
                        ListItem -Components {
                            Get-Label -Caption "Cell 3,1"
                            CheckBox -Caption "Cell 3,2"
                        }
                    }
                }
                TabItem -Caption "Radios" -Components {
                    RadioGroup -Components {
                        RadioButton -Caption "Fish"
                        RadioButton -Caption "Meat"
                    }
                }
                TabItem -Caption "CheckBoxes" -Components {
                    CheckBox -Caption "Ketchup"
                    CheckBox -Caption "Mayo"
                }
                TabItem -Caption "Modal" -Components {
                    Button   -Caption "Show"  -Action {
                        param($this)
                        $this.Form.MyModal.Show()
                    }
                    Modal -Name MyModal -Components {
                        StackPannel -Orientation Vertical -Components {
                            CheckBox -Caption "Ketchup"
                            CheckBox -Caption "Mayo"
                            Button   -Caption "Hide" -Action {
                                param($this)
                                $this.Form.MyModal.Hide()
                            }
                        }
                    }
                }
                TabItem -Caption "Timer" -Components {
                    Get-Label    -Caption "TimerLabel" -Name "TimerLabel"
                    Button   -Caption "Run" -Name TimerStart  -Action {
                        param($this)
                        $this.Form.Timer.Start()
                        $this.Control.Enable = $false
                        $this.Form.TimerStop.Enable = $true
                    }
                    Button   -Caption "Stop" -Name TimerStop -Action {
                        param($this)
                        $this.Form.Timer.Stop()
                        $this.Control.Enable = $false
                        $this.Form.TimerStart.Enable = $true
                    }
                }
                TabItem -Caption "Pikcers" -Components {
                    Get-Label    -Caption "DatePicker"
                    DatePicker -Value ([DateTime]::Today.AddDays(5)) -Name DatePicker
                    Get-Label    -Caption "TimePicker"
                    TimePicker -Value "15:27" -Name TimePicker
                    Button   -Caption "Time" -Action {
                        param($this)
                        $this.Control.Caption = $this.Form.TimePicker.Value
                    }
                }
            }
        }
    }
}

Set-UICF
$h = Get-UIHost
cls
$h.ShowFrame($wsb)

