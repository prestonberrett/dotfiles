#Requires AutoHotkey v2.0
#SingleInstance Force

;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_InitialWorkingDir  ; Ensures a consistent starting directory.

;#INCLUDE colemak_dh_ansi.ahk
#INCLUDE AutoCorrect.ahk
#INCLUDE AutoCorrectPersonal.ahk


F10:: ; 20-20-20 every 20 minutes look 20 feet away for 20 seconds (F10)
{
    global EyeStrainOn
    EyeStrainOn := !EyeStrainOn
    if (EyeStrainOn) {
        SetTimer(EyeStrainReminder, -1) ; first reminder right away, off the hotkey thread
    } else {
        SetTimer(EyeStrainReminder, 0)
        ToolTip("20-20-20 reminders off")
        SetTimer(() => ToolTip(), -2000)
    }
}

EyeStrainOn := false

EyeStrainReminder() {
    global EyeStrainOn
    SoundPlay("*16", 1)
    MsgBox("Look 20 feet away for 20 seconds!", "", "T5")
    Sleep(20 * 1000)
    SoundPlay("*64", 1)
    answer := InputBox("Minutes until the next reminder (0 or Cancel to stop)", "All Done!", "", "20")
    minutes := (answer.Result = "OK" && IsNumber(answer.Value)) ? Number(answer.Value) : 0
    if (!EyeStrainOn) ; turned off with F10 while the prompt was open
        return
    if (minutes <= 0) {
        EyeStrainOn := false
        SetTimer(EyeStrainReminder, 0)
        MsgBox("20-20-20 reminders stopped.", "", "T5")
        return
    }
    ; One-shot timer, re-armed after each prompt so a new interval takes effect.
    SetTimer(EyeStrainReminder, -minutes * 60000)
}

^!l:: ; Lock Computer when windows key doesn't work (Ctrl + Alt + L)
{
    DllCall("LockWorkStation")
    return
}

^+d:: ; Open Downloads Folder (Ctrl + Shift + D)
{
    Run A_UserProfile "\Downloads" ; ctrl+shift+d
    return
}

#+d:: ; Open Desktop Folder (Win + shift + d)
{
    Run A_UserProfile "\Desktop" ; Win+shift+d
    return
}

^!s::  ; Start main apps (Ctrl + Alt + S)
{
    Run "olk.exe"
    Sleep 1000
    ; Run "C:\Program Files\Zen Browser\zen.exe"
    Run EnvGet("LOCALAPPDATA") "\BraveSoftware\Brave-Browser\Application\brave.exe"
    Sleep 1000
    Run "C:\Program Files\Cisco Spark\CiscoCollabHost.exe"
    Sleep 1000
    ; Run EnvGet("LOCALAPPDATA") "\Programs\Microsoft VS Code\Code.exe"
    ; Sleep 1000
    ; Run EnvGet("LOCALAPPDATA") "\Programs\Bitwarden\Bitwarden.exe"
    ; Sleep 1000
    Run "C:\Program Files\WezTerm\wezterm-gui.exe"
    ;Run EnvGet("LOCALAPPDATA") "\Microsoft\WindowsApps\wt.exe"
    Sleep 1000
    Run EnvGet("LOCALAPPDATA") "\Programs\obsidian\Obsidian.exe"
    ; Sleep 1000
    ; Run "C:\Program Files\WindowsApps\Microsoft.Todos_2.148.3611.0_x64__8wekyb3d8bbwe\Todo.exe"
    ;Run "Todo.exe"
    return
}

;C:\WINDOWS\system32\cmd.exe
;ahk_class org.wezfurlong.wezterm
;ahk_exe wezterm-gui.exe
SwitchToWindowsTerminal() {
    windowHandleId := WinExist("ahk_exe wezterm-gui.exe")
    windowExistsAlready := windowHandleId > 0

    ; If the Windows Terminal is already open, determine if we should put it in focus or minimize it.
    if (windowExistsAlready = true) {
        activeWindowHandleId := WinExist("A")
        windowIsAlreadyActive := activeWindowHandleId == windowHandleId
        windowTitle := WinGetTitle(windowHandleId)

        if (windowIsAlreadyActive) {
            ; Minimize the window.
            WinMinimize windowTitle
        } else {
            ; Put the window in focus.
            WinActivate windowTitle
            WinShow windowTitle
        }
    }
    ; Else it's not already open, so launch it.
    else {
        Run "C:\Program Files\WezTerm\wezterm-gui.exe"
    }
}

; Hotkey to launch/restore/minimize WezTerm (Ctrl + Alt + W).
; Not Ctrl+Shift+C: that's terminal copy, and MiddleClickPaste.ahk sends it.
^!w:: SwitchToWindowsTerminal() ; Toggle WezTerm (Ctrl + Alt + W)

^!d:: ;Open local 4D project (Ctrl + Alt + D)
{
    ; Set FOURD_PROJECT to the full path of your .4DProject file.
    project := EnvGet("FOURD_PROJECT")
    if (project = "") {
        MsgBox("Set the FOURD_PROJECT environment variable to your .4DProject path.", "Open 4D project", "T5")
        return
    }
    Run '"C:\Program Files\4D\4D v20.1\4D\4D.exe" "' project '"'
    return
}

#c:: ;Open Calculator (Windows + C)
{
    Run "C:\Windows\System32\calc.exe" ; Win+c
    return
}

!+c:: ;Open PowerShell (Alt + Shift + C)
{
    Run "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    return
}

+F3:: ; Close all windows (Shift+F3)
{
    Send "!+q" ; exit GlazeWM first (wm-exit)
    idList := WinGetList(, , "Citrix Workspace")
    for thisId in idList {
        thisTitle := WinGetTitle(thisId)
        switch thisTitle {
            case "", "Program Manager", "Citrix Workspace", "AutoHotKeyScripts", "GlazeWM", "Zebar": ; do nothing
            default:
                WinActivate thisTitle
                WinClose thisTitle
                Sleep 1000
        }
    }
}

#!.:: ; Open folder in vscode (Windows + Alt + .)
{
    ; Is the current window an Explorer window?
    if (WinGetClass("A") == "CabinetWClass") {
        ; Cache the current clipboard contents.
        clipboard := A_Clipboard

        ; Clear the clipboard & copy selected files.
        A_Clipboard := ""
        Send "^c"
        ClipWait(0.5)

        ; If no files are selected...
        if (A_Clipboard == "") {
            ; Get the current window's ID.
            hwnd := WinGetID("A")

            ; Find the current window's COM object.
            for window in ComObject("Shell.Application").Windows {
                if (window && window.hwnd && window.hwnd == hwnd)
                ; Get the current folder's path.
                    path := window.Document.Folder.Self.Path
            }
        }
        else {
            ; Quote & space-concatenate selected files.
            path := '"' . StrReplace(A_Clipboard, "`n", '" "') . '"'
        }

        ; Restore the clipboard.
        A_Clipboard := clipboard

        ; Run user installation.
        exe := '"' . StrReplace(A_AppData, "Roaming", "Local\Programs\Microsoft VS Code\code") . '"'

        Run(exe . " " . path)
    }
}

;^!t:: ; mail to things via email (Ctrl + Alt + T)
;{
;    olMailItem := 0 ; olMailItem of 0 is a new email message
;    MailItem := ComObjActive("Outlook.Application").CreateItem(olMailItem)
;    MailItem.To := "add-to-things-k52esrgcm42sl7x8x33@things.email"
;    MailItem.Display
;    return
;}

^!h:: ;Autohotkey ShortcutGuide (Ctrl + Alt + H)
{
    HotKeyText := readHotkeys("MyScript.ahk")
    myGui := Gui()
    myGui.SetFont("s25", "Verdana")
    ;myGui.SetFont(,"Verdana")
    myGui.Add("Text", , HotKeyText)
    myGui.Show("AutoSize Center")
    sleep 1000 * 20
    myGui.Destroy()
    return
}

/* Written by Masonjar13
	Create a list of all static hotkeys in an AHK script file (not perfect).
	Includes #if directives.
	Parameters:


---------------
	filepath: path to AHK file

	retObj (optional): 1 - return an object, 0 - return a string

	return: list of hotkeys in the form of '{line number} {hotkey or #if}'
---------------
	Example:
------------
msgbox % readHotkeys(a_scriptFullPath)
~F1::
~F2::
return
------------
*/

readHotkeys(filepath, retObj := 0) {
    comment := 0, hlObj := {}
    static regExN := { singleComment: "^\s{0,};", blockComment: "^\s{0,}/\*", blockCommentEnd: "^\s{0,}\*/",
        directive: "i)^\s{0,}#if",
        hotskey: "::"
    }
    rFile := fileOpen(filepath, "r")

    while (!rFile.atEOF) {
        cLine := rFile.readLine()
        if (comment || cLine ~= regExN.singleComment) { ; inside block comment/single-line comment
            if (cLine ~= regExN.blockCommentEnd) { ; check for end block comment
                comment := 0
            }
            continue
        } else if (cLine ~= regExN.blockComment) { ; check for block comment
            comment := 1
            continue
        } else if (cLine ~= regExN.directive || cLine ~= regExN.hotskey) { ; get if-directive/get hotstring/hotkey (literal)
            if (retObj)
                hlObj[a_index] := cLine
            strOut .= a_index "`n" a_tab cLine
        }
    }
    rFile.close()
    if (retObj) {
        hlObj.str := strOut
        return hlObj
    }
    return strOut
}
