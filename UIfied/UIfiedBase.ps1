using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

#region UI Type selection

enum UIType {
    WPF
    CF
    Ooui
    MaterialWPF
    MaterialOoui
    MaterialCF
}

class UIConfig {
    static [UIType] $UIType = [UIType]::MaterialWPF
}

function Set-UIType {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [UIType]   $Type
    )
    if ($PSCmdlet.ShouldProcess('TARGET')) {
        [UIConfig]::UIType = $Type
    }
}

function Set-UICF {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    Set-UIType -Type ([UIType]::CF)
}

function Set-UIWPF {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    Set-UIType -Type ([UIType]::WPF)
}

function Set-UIOoui {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    Set-UIType -Type ([UIType]::Ooui)
}

function Set-UIMaterialWPF {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    Set-UIType -Type ([UIType]::MaterialWPF)
}

function Set-UIMaterialOoui {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    Set-UIType -Type ([UIType]::MaterialOoui)
}

function Set-UIMaterialCF {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    Set-UIType -Type ([UIType]::MaterialCF)
}

#endregion

#region UI Constructs

class UIElement {
    hidden   [ScriptBlock]     $AddNativeUIChild    = { param ([UIElement] $element) }
    hidden   [ScriptBlock]     $RemoveNativeUIChild = { param ([UIElement] $element) }
    hidden   [ScriptBlock]     $ShowError           = { param ([Object]    $errorObject) }
    hidden   [int]             $MaxErrors           = 3
    hidden   [Object]          $NativeUI            = $null
             [List[UIElement]] $Children            = [List[UIElement]]::new()
             [WindowBase]      $Form                = $null
             [UIElement]       $Parent              = $null
             [String]          $Name                = ""

    UIElement() {
    }

    [void] AddChild([UIElement] $element) {
        $this.Children.Add($element)
        $element.SetForm($this.Form)
        $element.SetParent($this)
        Invoke-Command -ScriptBlock $this.AddNativeUIChild -ArgumentList $element
    }

    [void] RemoveChild([UIElement] $element) {
        Invoke-Command -ScriptBlock $this.RemoveNativeUIChild -ArgumentList $element
        $this.Children.Remove($element) | Out-Null
    }

    hidden [void] SetForm([WindowBase] $form) {
        if ($null -ne $form) {
            $this.Form = $form
            $this.Children | ForEach-Object {
                $_.SetForm($form)
                Add-Member -InputObject $_.NativeUI -Name Form -MemberType NoteProperty -Value $form
            }
            if ($this.Name -ne "") {
                $nameMember = Get-Member -InputObject $form -Name $this.Name -MemberType NoteProperty
                if ($null -eq $nameMember) {
                    Add-Member -InputObject $form -Name $this.Name -MemberType NoteProperty -Value $this
                }
            }
        }
    }

    hidden [void] SetParent([UIElement] $parent) {
        if ($null -ne $parent) {
            $this.Parent = $parent
        }
    }

    hidden [void] WrapProperty([String] $elementPropertyName, [String] $nativeUIProperty) {
        $this.WrapProperty($elementPropertyName, $nativeUIProperty, "NativeUI")
    }

    hidden [void] WrapProperty([String] $elementPropertyName, [String] $nativeUIProperty, [String] $nativeUIName) {
        if (-not $this.IsValidName($elementPropertyName) -or -not $this.IsValidName($nativeUIProperty) -or -not $this.IsValidName($nativeUIName)) {
            return
        }
        Add-Member -InputObject $this -Name $elementPropertyName -MemberType ScriptProperty                `
                    -Value          ([ScriptBlock]::Create("`$this.$nativeUIName.$nativeUIProperty"))           `
                    -SecondValue    ([ScriptBlock]::Create("`$this.$nativeUIName.$nativeUIProperty = `$args[0]"))
    }

    hidden [void] WrapNegatedProperty([String] $elementPropertyName, [String] $nativeUIProperty) {
        if (-not $this.IsValidName($elementPropertyName) -or -not $this.IsValidName($nativeUIProperty)) {
            return
        }
        Add-Member -InputObject $this -Name $elementPropertyName -MemberType ScriptProperty                `
                    -Value          ([ScriptBlock]::Create("-not `$this.NativeUI.$nativeUIProperty"))           `
                    -SecondValue    ([ScriptBlock]::Create("`$this.NativeUI.$nativeUIProperty = -not `$args[0]"))
    }

    hidden [void] SetNativeUI([Object] $nativeUI) {
        $this.NativeUI = $nativeUI
        Add-Member -InputObject $NativeUI -Name Control -MemberType NoteProperty -Value $this -Force
        Add-Member -InputObject $this     -Name Control -MemberType NoteProperty -Value $this -Force
    }

    hidden [bool] IsValidScript([ScriptBlock] $scriptBlock) {
        $isValid = $true
        $commands = $scriptBlock.Ast.FindAll({ param ($o) $o -is [CommandAst] }, $true)
        $commands | ForEach-Object {
            $commandName = $_.CommandElements[0].Value
            $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue
            if ($null -eq $command) {
                $isValid = $false
            }
        }
        return $isValid
    }

    hidden [void] AddProperty([String]$propertyName) {
        if (-not $this.IsValidName($propertyName)) {
            return
        }
        $memberName = "_$propertyName"
        Add-Member -InputObject $this -Name $memberName   -MemberType NoteProperty   -Value {}
        Add-Member -InputObject $this -Name $propertyName -MemberType ScriptProperty -Value (
            [ScriptBlock]::Create("`$this.$memberName")
        ) -SecondValue (
            [ScriptBlock]::Create("`$this.$memberName = `$args[0]")
        )
    }

    hidden [void] AddScriptBlockProperty([String]$propertyName) {
        if (-not $this.IsValidName($propertyName)) {
            return
        }
        $memberName = "_$propertyName"
        Add-Member -InputObject $this -Name $memberName   -MemberType NoteProperty   -Value {}
        Add-Member -InputObject $this -Name $propertyName -MemberType ScriptProperty -Value (
            [ScriptBlock]::Create("`$this.$memberName")
        ) -SecondValue (
            [ScriptBlock]::Create("
                    if (`$this.IsValidScript(`$args[0])) {
                       `$this.$memberName = `$args[0]
                    } else {
                        `$this.$memberName = {}
                        `$this.Visible = `$false
                    }
            ")
        )
    }

    hidden [bool] IsValidName([String]$name) {
        return ($name -match '(^[a-zA-Z_$][a-zA-Z_$0-9]*$)')
    }

    hidden [void] InvokeTrappableCommand([ScriptBlock] $ScriptBlock, [Object[]] $ArgumentList) {
        try {
            Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
        } catch {
            $Global:SyncHash.Errors += $_
            Invoke-Command -ScriptBlock $this.ShowError -ArgumentList $_
            if ($Global:SyncHash.Errors.Count -gt $this.MaxErrors) {
                $this.Form.Close()
            }
        }
    }

    [void] AddNoteProperty([String]$propertyName, $value) {
        if (-not $this.IsValidName($propertyName)) {
            return
        }
        Add-Member -InputObject $this -Name $propertyName   -MemberType NoteProperty -Value $value
    }
}

class WindowBase : UIElement {

    WindowBase() {
        $this.Form = $this
    }

    [void] Close() {
        $this.NativeUI.Close()
    }
}

class UIHost {

    [void] ShowFrame([WindowBase]$window) {
    }

}

enum Orientation {
    Horizontal
    Vertical
}

class ListItem {
    [List[UIElement]] $Children            = [List[UIElement]]::new()

    ListItem() {
    }

    [void] AddChild([UIElement] $element) {
        $this.Children.Add($element)
    }

    [void] RemoveChild([UIElement] $element) {
        $this.Children.Remove($element)
    }
}

class AutoCompleteItem {
    [String] $Id
    [String] $Text
}

#endregion

#region UI Icons

class IconStrinfy {
    static [bool]  $ShowIcon = $true
    
    hidden static $Icons = @{
        menu                       = [string] [char] 02261 # 62542
        add                        = [string] [char] 62541
        edit                       = [string] [char] 61504
        delete                     = [string] [char] 62606
        clear                      = [string] [char] 62567
        calendar_today             = [string] [char] 62957
        query_builder              = [string] [char] 63055
        left_semi_circle           = [string] [char] 57526
        right_semi_circle          = [string] [char] 57524
        first_page                 = [string] [char] 64255
        chevron_left               = [string] [char] 61523
        chevron_right              = [string] [char] 61524
        chevron_down               = [string] [char] 61560
        last_page                  = [string] [char] 64256
        radio_button_checked       = [string] [char] 64611
        radio_button_unchecked     = [string] [char] 64612
        check_box                  = [string] [char] 62510
        check_box_outlined_blank   = [string] [char] 64609
    }

    static [String] ToIconString([String] $kindName) {
        if ([IconStrinfy]::ShowIcon) {
            return [IconStrinfy]::Icons."$kindName"
        } else {
            return ""
        }
    }
}

enum IconPosition {
    Left
    Right
}

#endregion