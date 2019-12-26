# UIfied

A unified PowerShell DSL for multiple UIs.

## Simple DSL

Write complex UIs leveraging the easy way with the UIfied DSL

    $wsb = {
        Get-Window -Caption "Title" -Components {
            Get-StackPannel -Orientation Vertical -Components {
                Get-Label    -Caption "Hello"
                Get-Button   -Caption "Button" -Action {
                    param($this)
                    $this.Control.Caption = Get-Date
                }
            }
        }
    }
    $h = Get-Host
    $h.ShowFrame($wsb)

## Three UI types supported

UIFied supports tree UI types

- Windows: UIfied creates WPF UIs.
- Console: UIfied uses [ConsoleFramework](https://github.com/elw00d/consoleframework) for console UIs.
- Web: UIfied web support is based on [Ooui](https://github.com/praeclarum/Ooui).

![A simple sample running on different UIs](UIfied.Test/SimpleTest.gif)

## Achieve more with less code

Write once and use it accross differents UIs. You can switch the target UI framework by simply using a command.

    Set-UICF     # Switch to console UI
    Set-UIWPF    # Switch to Windows Presentation Framework UI
    Set-UIOoui   # Switch to Web UI

