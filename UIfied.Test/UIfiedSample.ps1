
Import-Module "$PSScriptRoot\..\UIfied"

$wsb = {
    UIWindow -Caption "My Title" -Loaded {
            param ($this)
            $this.Form.Caption = $this.Form.Caption + " Loaded at " + (Get-Date).ToString() + " " + $PID
        } -Components {
        UIStackPanel -Orientation Vertical -Components {
            UITabControl -Components {
                UITabItem -Caption "Controls" -Components {
                    UIStackPanel -Orientation Horizontal -Components {
                        UIStackPanel -Orientation Vertical -Components {
                            UICard -Caption "Labels" -Components {
                                UILabel    -Caption "This is a Label"     -Name MyLabel
                            }
                            UICard -Caption Buttons -Components {
                                UILabel    -Caption "Button:"             -Name ButtonLabel
                                UIButton   -Caption "My Button"           -Name MyButton       -Action {
                                    param($this)
                                    $this.Form.ButtonLabel.Caption = Get-Date
                                    $this.Form.MyButton.Icon = (Get-UIIcon -Kind "add")
                                    $this.Form.MyCombo.Text = "1"
                                } -Icon (UIIcon -Kind "delete")
                            }
                            UICard -Caption TextBoxes -Components {
                                UILabel    -Caption "TextBox:"            -Name TextBoxLabel
                                UITextBox                                 -Name MyTextBox      -Change {
                                    param($this)
                                    $this.Form.TextBoxLabel.Caption = $this.Control.Text
                                }
                                UILabel    -Caption "TextAlignment"
                                UITextBox -TextAlignment Right
                                UILabel    -Caption "Pattern"
                                UITextBox -TextAlignment Right -Text "0" -DefaultText "0" -Pattern '^\d+$'
                                UILabel    -Caption "Integer"
                                UIInteger
                                UILabel    -Caption "Double"
                                UIDouble
                            }
                            UICard -Caption ComboBox -Components {
                                UIComboBox -Text 2 -Name MyCombo -Components {
                                    Get-UIComboBoxItem -Id 1 -Caption Hello
                                    Get-UIComboBoxItem -Id 2 -Caption GoodBy
                                } -Change {
                                    param($this)
                                    $this.Form.TextBoxLabel.Caption = $this.Control.Text
                                }
                            }
                        }
                        UIStackPanel -Orientation Vertical -Components {
                            UICard -Caption Pickers -Components {
                                UILabel    -Caption "DatePicker:"
                                UIDatePicker -Value ([DateTime]::Today)   -Name MyDatePicker
                                UILabel    -Caption "TimePicker:"
                                UITimePicker -Value "15:27"               -Name MyTimePicker
                            }
                            UICard -Caption Toogles -Components {
                                UILabel    -Caption "RadioButton:"
                                UIRadioButton -Caption "Fish"
                                UILabel    -Caption "CheckBox:"
                                UICheckBox -Caption "Ketchup"
                            }
                            UICard -Caption TextEditor -Components {
                                UILabel    -Caption "TextEditor:"
                                UITextEditor -Text "Change this text`nLine2" -Height 5 -Width 30
                            }
                            UICard -Caption Password -Components {
                                UIPassword -Change {
                                    param($this)
                                    $this.Form.TextBoxLabel.Caption = $this.Control.Text
                                }
                            }
                        }
                    }
                }
                UITabItem -Caption "Containers" -Components {
                    UIStackPanel -Orientation Horizontal -Components {
                        UICard -Caption "Lists" -Components {
                            UIList -Name Grid -Columns {
                                UIListColumn -Title "Column 1"
                                UIListColumn -Title "Column 2"
                            } -Items {
                                UIListItem -Components {
                                    UILabel -Caption "Cell 1,1"
                                    UICheckBox -Caption "Cell 1,2"
                                }
                                UIListItem -Components {
                                    UILabel -Caption "Cell 2,1"
                                    UICheckBox -Caption "Cell 2,2"
                                }
                                UIListItem -Components {
                                    UILabel -Caption "Cell 3,1"
                                    UICheckBox -Caption "Cell 3,2"
                                }
                            }
                        }
                        UICard -Caption "RadioGroups" -Components {
                            UIRadioGroup -Components {
                                UIRadioButton -Caption "Fish"
                                UIRadioButton -Caption "Meat"
                            }
                        }
                        UICard -Caption "DropDownMenus" -Components {
                            UIDropDownMenu -Caption "my dropdown" -Components {
                                UIMenuItem   -Caption "Menu 1" -Action {
                                    param($this)
                                    $this.Control.Caption = Get-Date
                                }
                                UIMenuItem   -Caption "Menu 2" -Action {
                                    param($this)
                                    $this.Control.Caption = Get-Date
                                }
                            }
                        }
                        #UICard -Caption "Expanders" -Components {
                        #    UIExpander -Caption "My expander" -Components {
                        #        UILabel -Caption "Expander content"
                        #    }
                        #}
                    }
                    UIStackPanel -Orientation Horizontal -Components {
                        UICard -Caption "Autocompletes" -Components {
                            UILabel    -Caption "Press down key to view options"
                            UIAutoComplete -Text "AB" -ItemsRequested {
                                param($this)
                                Get-UIAutoCompleteItem -Id "id1" -Text ($this.Text + " sample")
                                Get-UIAutoCompleteItem -Id "id2" -Text ([DateTime]::Now.ToString())
                                Get-UIAutoCompleteItem -Id "id3" -Text ($this.Text + " sample2")
                                Get-UIAutoCompleteItem -Id "id4" -Text ([DateTime]::Now.ToString())
                            }
                        }
                        UICard -Caption Cards -Name MyCard -Icon (UIIcon -Kind delete) -Components {
                            UILabel  -Caption "Card body content here"
                            UIButton -Caption "Change" -Action {
                                param($this)
                                $this.Form.MyCard.Caption = "Hello Card"
                                $this.Form.MyCard.Icon = (Get-UIIcon -Kind add)
                            }
                        }
                        UICard -Caption "Modals" -Components {
                            UILabel    -Caption "Click to show modal form"
                            UIButton   -Caption "Show"  -Action {
                                param($this)
                                $this.Form.MyModal.Show()
                            }
                            UIModal -Name MyModal -Title "MY TITLE" -Components {
                                UIStackPanel -Orientation Vertical -Components {
                                    UICheckBox -Caption "Ketchup"
                                    UICheckBox -Caption "Mayo"
                                    UIButton   -Caption "Hide" -Action {
                                        param($this)
                                        $this.Form.MyModal.Hide()
                                    }
                                }
                            }
                        }
                    }
                }
                UITabItem -Caption "Browser" -Components {
                    UIBrowser -Name Browser -Columns {
                        UIListColumn -Title "Id" -Name Id
                        UIListColumn -Title "Description" -Name Description
                    } -Edit {
                        param($this)
                        $this.Form.ButtonLabel.Caption = $this.Control.CurrentRow | ConvertTo-Json
                    } -AddNew {
                        param($this)
                        $this.Control.Data += @{Id = "dd"; Description = Get-Date }
                        $this.Control.Refresh()
                    } -Data @(
                        1..203 | ForEach-Object { @{Id = $_; Description = "Desc $_  jkdf kjafsd j fdas jfas jfas djaf sj "} }
                    ) -PageRows 10
                }
                UITabItem -Caption "Others" -Components {
                    UIStackPanel -Orientation Horizontal -Components {
                        UICard -Caption "Images" -Components {
                            UILabel    -Caption "Image samples"
                            UIDropDownMenu -Caption "Select Image" -Components {
                                UIMenuItem   -Caption "PowerShell Logo" -Action {
                                    param($this)
                                    $this.Form.ImageSource.Text = "https://deow9bq0xqvbj.cloudfront.net/image-logo/1769310/powershell.png"
                                }
                                UIMenuItem   -Caption "Android logo" -Action {
                                    param($this)
                                    $this.Form.ImageSource.Text = "https://logovector.net/wp-content/uploads/2010/06/291431-android-2-logo.png"
                                }
                                UIMenuItem   -Caption "Apple logo" -Action {
                                    param($this)
                                    $this.Form.ImageSource.Text = "http://cdn.wccftech.com/wp-content/uploads/2013/09/Apple-logo1.jpg"
                                }
                            }
                            UILabel    -Caption "Image source"
                            UITextBox  -Name ImageSource
                            UIButton -Caption "Show" -Action {
                                param($this)
                                $this.Form.MyImage.Source = $this.Form.ImageSource.Text
                            }
                            UIImage -Name MyImage -Width 300
                        }
                        UICard -Caption Timers -Components {
                            UILabel    -Caption "Timer:" -Name TimerLabel
                            UITimer  -Name Timer -Elapsed {
                                param ($this)
                                $this.Form.TimerLabel.Caption = Get-Date
                            }
                            UIButton   -Caption "Run" -Name TimerStart  -Action {
                                param($this)
                                $this.Form.Timer.Start()
                                $this.Control.Enable = $false
                                $this.Form.TimerStop.Enable = $true
                            }
                            UIButton   -Caption "Stop" -Name TimerStop -Action {
                                param($this)
                                $this.Form.Timer.Stop()
                                $this.Control.Enable = $false
                                $this.Form.TimerStart.Enable = $true
                            }
                        }
                        UICard -Caption "FileUpload" -Components {
                            UIFileUpload -Caption "File Upload"
                        }
                    }
                }
            }
        }
    }
}

Set-UIOoui

$h = Get-UIHost
#cls
$h.ShowFrame($wsb)

