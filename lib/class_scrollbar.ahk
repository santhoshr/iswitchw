; gdi+ ahk tutorial 9 written by tic (Tariq Porter)
; Requires Gdip.ahk either in your Lib folder as standard library or using #Include
;
; Example to create a progress bar in a standard gui

#SingleInstance, Force
#NoEnv
SetBatchLines, -1

; Uncomment if Gdip.ahk is not in your standard library
#Include, Gdip_All.ahk
#Include, Edit\_Functions\Edit.ahk

; Start gdi+
If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit


text=
(
Introduction
------------
AutoHotkey is a free, open-source utility for Windows. With it, you can:

    * Automate almost anything by sending keystrokes and mouse clicks. You can write macros by hand or use the macro recorder. 

    * Create hotkeys for keyboard, joystick, and mouse. Virtually any key, button, or combination can become a hotkey. 

    * Expand abbreviations as you type them. For example, typing "btw" can automatically produce "by the way". 

    * Create custom data-entry forms, user interfaces, and menu bars. See GUI for details.

    * Remap keys and buttons on your keyboard, joystick, and mouse. 

    * Respond to signals from hand-held remote controls via the WinLIRC client script.

    * Run existing AutoIt v2 scripts and enhance them with new capabilities. 

    * Convert any script into an EXE file that can be run on computers that don't have AutoHotkey installed.

Getting started might be easier than you think. Check out the quick-start tutorial.

More about Hotkeys
------------------
AutoHotkey unleashes the full potential of your keyboard, joystick, and mouse. For example, in addition to the typical Control, Alt, and Shift modifiers, you can use the Windows key and the Capslock key as modifiers. In fact, you can make any key or mouse button act as a modifier. For these and other capabilities, see Advanced Hotkeys.


Other Features
--------------
    * Change the volume, mute, and other settings of any soundcard.

    * Make any window transparent, always-on-top, or alter its shape.

    * Use a joystick or keyboard as a mouse.

    * Monitor your system. For example, close unwanted windows the moment they appear.

    * Retrieve and change the clipboard's contents, including file names copied from an Explorer window.

    * Disable or override Windows' own shortcut keys such as Win+E and Win+R.

    * Alleviate RSI with substitutes for Alt-Tab (using keys, mouse wheel, or buttons).

    * Customize the tray icon menu with your own icon, tooltip, menu items, and submenus.

    * Display dialog boxes, tooltips, balloon tips, and popup menus to interact with the user.

    * Perform scripted actions in response to system shutdown or logoff.

    * Detect how long the user has been idle. For example, run CPU intensive tasks only when the user is away.

    * Automate game actions by detecting images and pixel colors (this is intended for legitimate uses such as the alleviation of RSI).

    * Read, write, and parse text files more easily than in other languages.

    * Perform operation(s) upon a set of files that match a wildcard pattern.

    * Work with the registry and INI files.

Acknowledgements
----------------
A special thanks to Jonathan Bennett, whose generosity in releasing AutoIt v2 as free software in 1999 served as an inspiration and time-saver for myself and many others worldwide. In addition, many of AutoHotkey's enhancements to the AutoIt v2 command set, as well as the Window Spy and the script compiler, were adapted directly from the AutoIt v3 source code. So thanks to Jon and the other AutoIt authors for those as well.

Finally, AutoHotkey would not be what it is today without these other individuals.

Creating a script
-----------------
Each script is a plain text file containing commands to be executed by the program (AutoHotkey.exe). A script may also contain hotkeys and hotstrings, or even consist entirely of them. However, in the absence of hotkeys and hotstrings, a script will perform its commands sequentially from top to bottom the moment it is launched.

To create a new script:

    1. Download and install AutoHotkey. 

    2. Right-click an empty spot on your desktop or in a folder of your choice. 

    3. In the menu that appears, select New -> AutoHotkey Script. 

    4. Type a name for the file, ensuring that it ends in .ahk. For example: Test.ahk 

    5. Right-click the file and choose Edit Script. 

    6. On a new blank line, type the following:
       
       #space::Run www.google.com 

In the line above, the first character "#" stands for the Windows key; so #space means holding down the Windows key then pressing the spacebar to activate the hotkey. The :: means that the subsequent command should be executed whenever this hotkey is pressed, in this case to go to the Google web site. To try out this script, continue as follows:

    1. Save and close the file. 

    2. Double-click the file to launch it. A new icon appears in the taskbar notification area. 

    3. Hold down the Windows key and press the spacebar. A web page opens in the default browser. 

    4. To exit or edit the script, right-click the green "H" icon in the taskbar notification area. 

Notes:

    * Multiple scripts can be running simultaneously, each with its own icon in the taskbar notification area.

    * Each script can have multiple hotkeys and hotstrings. 

    * To have a script launch automatically when you start your computer, create a shortcut in the Start Menu's Startup folder. 
)

; Before we start there are some design elements we must consider.
; We can either make the script faster. Creating the bitmap 1st and just write the new progress bar onto it every time and updating it on the gui
; and dispose it all at the end/ This will use more RAM
; Or we can create the entire bitmap and write the information to it, display it and then delete it after every occurence
; This will be slower, but will use less RAM and will be modular (can all be put into a function)
; I will go with the 2nd option, but if more speed is a requirement then choose the 1st

;h200 > 17
;h300 > 24
;h400 > 33

Gui, -DPIScale +hwndgui_id
; I airst creating a slider, just as a way to change the percentage on the progress bar
Gui, Add, Edit, hwndhEdit vvEdit gEdit w500 h750, % text
scroll1:= new ScrollBar(hEdit)
scroll1.Update()
; Gui, Add, ListView, xm hwndhLV vvLV w500 h300 +LVS_NOSCROLL, Index|Name|Size (KB)
; Gui, 1: Add, Picture, x+5 yp w10 h100 0xE hwndhScrollBar vvScrollBar
; Gui, 1: Add, Slider, x10 y10 w400 Range0-100 vPercentage gSlider Tooltip, 50

; The progress bar needs to be added as a picture, as all we are doing is creating a gdi+ bitmap and setting it to this control
; Note we have set the 0xE style for it to accept an hBitmap later and also set a variable in order to reference it (could also use hwnd)
; We will set the initial image on the control before showing the gui
; GoSub, Slider
; GoSub, Edit
; Loop, C:\Users\dmcleod\Documents\!LaunchPadProject\*.*
;     LV_Add("", A_Index,A_LoopFileName, A_LoopFileSizeKB)

; LV_ModifyCol()  ; Auto-size each column to fit its contents.
; LV_ModifyCol(2, "Integer")  ; For sorting purposes, indicate that column 2 is an integer.
; scroll2 := new ScrollBar(hLV,"listview")

Gui, Show, AutoSize,  ;Example 9 - gdi+ progress bar
Return

Edit:
scroll1.Update()
Return

class ScrollBar {

    __New(hEdit, type := "edit", xPos := 2, width := 10, gui := 1) {
        local func, height := 45
        ; local func, ctrlX, ctrlY, ctrlH, ctrlW, height := 45
        this.hEdit := hEdit
        this.barWidth := width
        this.type := type
        this.fn := this["timer"].bind(this)
        If (type = "edit") {
            Edit_HideAllScrollBars(hEdit)
        } else if (type = "listview") {
            LVM_ShowScrollBar(hEdit,SB_BOTH,false)
        }
        GuiControlGet, ctrl, Pos, % this.hEdit
        ctrlW -= width
        GuiControl, MoveDraw, % this.hEdit, % "w" ctrlW
        Gui, %gui%: Add, Picture, % "x" ctrlX + ctrlW + xPos " yp w" width " h" height " 0xE hwndhScrollBar" hEdit " vvScrollBar" hEdit
        this.hwnd := hScrollBar%hEdit%
        this.ParentHwnd := DllCall("user32\GetAncestor", Ptr,this.hwnd, UInt,1, Ptr) ;GA_PARENT := 1
        this.StopScrolling := ObjBindMethod(this, "WM_LBUTTONUP")
        this.StartScrolling := ObjBindMethod(this, "WM_LBUTTONDOWN")
        this.Scroll := ObjBindMethod(this, "WM_MOUSEMOVE")
        OnMessage(0x200, this.Scroll)
        OnMessage(0x201, this.StartScrolling)
        OnMessage(0x202, this.StopScrolling)
        this.BindKeys()
    }

    BindKeys() {
        hotkeys := ["~Up","~Down","~PgDn","~PgUp","~^Home","~^End","~WheelUp","~WheelDown"]
        hasFocus := ObjBindMethod(this, "HasFocus")
        Hotkey, If, % hasFocus
        hotkeyHandler := ObjBindMethod(this, "Update")
        for i, e in hotkeys
            Hotkey, % e, % hotkeyHandler
    }

    HasFocus() {
        hEdit := this.hEdit
        GuiControlGet, focusedControl, Focus
        GuiControlGet, focusedHwnd, Hwnd, % focusedControl
        Return focusedHwnd = hEdit ? 1 : 0
    }

    Update() {
        Sleep 10
        hEdit := this.hEdit
        GuiControlGet, ctrl, Pos, % this.hEdit
        this.ctrlHeight := ctrlH
        this.ctrlY := ctrlY
        If (this.type = "edit") {
            this.lineCount := Edit_GetLineCount(this.hEdit)
            ; if (this.lineCount = 1)
            ;     this.lineCount := 0
            this.visibleLines := Edit_GetLastVisibleLine(hEdit) - Edit_GetFirstVisibleLine(hEdit) ;+ 1
            lineHeight := ctrlH / this.visibleLines
            contentHeight := lineHeight * this.lineCount
            viewableRatio := ctrlH / contentHeight
            ; newY := 
            ; newY := Edit_GetFirstVisibleLine(hEdit) ()
            ;//////////newY := Floor(((Edit_GetFirstVisibleLine(hEdit) * lineHeight) * viewableRatio) + ctrlY)
            ; line := Edit_GetFirstVisibleLine(hEdit)
            ; If (line > this.lineCount // 2)
                ; line := Edit_GetLastVisibleLine(hEdit) ;- this.visibleLines
            ; range := this.ctrlHeight - this.barHeight
            ; newY := (line / this.lineCount) * range
            ; newY += this.ctrlY
            ; newY := (Round((line / ctrlH) * 100) + ctrlY)
            ; If Mod(newY, this.lineCount)
            ;     newY += 1
            ; scrollPos := ((barY - this.ctrlY) / (this.barMax - this.ctrlY))
            ; scrollPos := this.lineCount * scrollPos
            ; charPos   := Edit_LineIndex(hEdit,scrollPos)
            
        } Else If (this.type = "listview") {
            this.lineCount := LV_GetCount()
            SendMessage, 4136, 0, 0, , % "ahk_id" this.hEdit
            this.visibleLines := ErrorLevel
            SendMessage, 4135, 0, 0, , % "ahk_id" this.hEdit
            topRow := ErrorLevel + 1
            newY := topRow + ctrlY
        }
        If (this.lineCount <= this.visibleLines) {
            if (this.hidden <> 1) {
                GuiControl, Hide, % this.hwnd
                GuiControl, MoveDraw, % this.hEdit, % "w" ctrlW + this.barWidth
            }
            this.hidden := 1
        } else {
            if (this.hidden = 1) {
                GuiControl, Show, % this.hwnd
                GuiControl, MoveDraw, % this.hEdit, % "w" ctrlW - this.barWidth
                this.hidden := 0
            }
            barHeight := ctrlH * viewableRatio ;ctrlH * (this.visibleLines / ctrlH )
            If (barHeight < 15) {
                ; if (newY > (ctrlH + ctrlY) // 2)
                ; newY := newY - (15 - barheight)
                ; If 
                ;     newY--
                ; remainingLines := this.lineCount - Edit_GetFirstVisibleLine(hEdit)
                ; test := Floor(((lineHeight * viewableRatio) * remainingLines) + ctrlY - 15)
                ; If (test > this.barMax)
                ;     newY -= test - this.barMax
                ; ; tooltip % remainingLines ; (this.lineCount * lineHeight) / (15 - barheight + newY)
                barHeight := 15
            }
            ; Else If (barHeight > (ctrlH * 0.75 ))
            ;     barHeight := ctrlH * 0.75
            this.barMax := ctrlY + ctrlH - barHeight
            ; if (newY > this.barMax)
            ;     newY := this.barMax
            this.barHeight := barHeight
            this.trackRange := ctrlH - barHeight
            jump := this.trackRange / (this.lineCount - this.visibleLines)
            newY := (Edit_GetFirstVisibleLine(hEdit) * jump) + ctrlY
            GuiControl, MoveDraw, % this.hwnd, h%barheight% y%newY%
        }
        this.RedrawScrollBar()
        OnMessage(0x200, "")
        Tooltip, % newY - ctrlY
        fn := this.fn
        settimer, % fn, -2000        
    }

    timer() {
        Tooltip
        OnMessage(0x200, "WM_MOUSEMOVE")
    }

    RedrawScrollBar() {
        global
        hEdit := this.hEdit
        this.Gdip_ScrollBar(vScrollBar%hEdit%,0xff2e2d2d)
        if (this.type = "listview")
            LVM_ShowScrollBar(hEdit,3,false)
    }

    WM_LBUTTONDOWN() {
        hEdit := this.hEdit
        CoordMode, Mouse, Client
        MouseGetPos, , y, , vControl, 2
        If (vControl = this.hwnd) {
            this.scrolling := 1
            DllCall("SetCapture", "UInt", this.ParentHwnd)
            GuiControlGet, bar, Pos, % this.hwnd
            this.diff := y - barY
        }
    }

    WM_LBUTTONUP() {
        If (this.scrolling = 1) {
            this.scrolling := 0
            DllCall("ReleaseCapture")
        }
    }

    WM_MOUSEMOVE() {
        hEdit := this.hEdit
        GuiControlGet, ctrl, Pos, % hEdit
        If (this.scrolling = 1 && GetKeyState("LButton")) {
            CoordMode, Mouse, Client
            GuiControlGet, bar, Pos, % this.hwnd
            MouseGetPos, , y
            y -= this.diff
            If (y > this.barMax)
                y := this.barMax
            Else If (y < ctrlY)
                y := ctrlY
            GuiControl, Move, % this.hwnd , y%y%

            
            jump := this.trackRange / (this.lineCount - this.visibleLines)

            If (this.type = "edit") {
                    ; If (Mod(y - ctrlY, jump) = 0) {
                        topLine := Edit_GetFirstVisibleLine(hEdit)
                        lastLine := Edit_GetLastVisibleLine(hEdit)
                        scrollPos := (y - ctrlY) / jump
                    	lineSet := scrollPos - topLine ;get difference between current line and zeroth line, subtract one
                        ; scrollPos := scrollPos - topLine                        
                        ; scrollTo(hEdit, scrollPos + 1)
                    	; SendMessage, 0xCE, 0, 0, , % "ahk_id" hEdit ; EM_GETFIRSTVISIBLELINE to get first line shown (results stored in ErrorLevel)
                    	PostMessage, 0xB6, 0, % lineSet, , % "ahk_id" hEdit ; EM_LINESCROLL to scroll target to top
                    	GuiControl, Focus, % "ahk_id" hEdit ; ;%editCNN%	;set focus to the edit ctrl
                    	scrollPos--	;EM_LINEINDEX is 0-based, so sub one
                    	SendMessage, 0xBB, % scrollPos, 0, , % "ahk_id" hEdit ; EM_LINEINDEX to get first char from line (results stored in ErrorLevel)
                    	PostMessage, 0xB1, % topLine, % topLine, , % "ahk_id" hEdit ; EM_SETSEL to change caret to first character position of line 'lineSel'
                        ; RC := Edit_Scroll(this.hEdit,,scrollPos)
                    ; scrollPos := y - barY ;* lineJump
                    ; RC := Edit_LineScroll(this.hEdit,0,scrollPos)
                    ; scrollPos *= this.lineCount // this.barMax
                    
                        ; scrollPos := ((barY - this.ctrlY) / (this.barMax - this.ctrlY))
                        ; scrollPos := this.lineCount * scrollPos
                        ; charPos   := Edit_LineIndex(hEdit,scrollPos)
                        ; Edit_SetSel(hEdit,charPos,charPos)
                        ; Edit_ScrollCaret(hEdit)
                        ; If (scrollPos = this.lineCount) {
                        ;     RC := Edit_Scroll(this.hEdit,1)
                        ; }
                    ; }
            } else if (this.type = "listview") {

                scrollPos := ((barY - this.ctrlY) / (this.barMax - this.ctrlY))
                scrollPos := this.lineCount * scrollPos
                if (scrollPos = 0)
                    scrollPos := 1
                LV_Modify(Format("{:d}",scrollPos), "Vis")
                LVM_ShowScrollBar(hEdit,3,false)
            }
        }
    }

    Gdip_ScrollBar(ByRef Variable, Color, Background=0x00000000)
    {
    	GuiControlGet, Pos, Pos, Variable
    	GuiControlGet, hwnd, hwnd, Variable
    	pBrushFront := Gdip_BrushCreateSolid(Color) ;, pBrushBack := Gdip_BrushCreateSolid(Background)
    	pBitmap := Gdip_CreateBitmap(Posw, Posh), G := Gdip_GraphicsFromImage(pBitmap), Gdip_SetSmoothingMode(G, 4)
        Gdip_FillRectangle(G, pBrushFront, 0, 0, Posw, Posh)
        ; Gdip_FillRoundedRectangle(G, pBrushFront, 0, 0, Posw, Posh, 5)
    	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
    	SetImage(hwnd, hBitmap)
    	Gdip_DeleteBrush(pBrushFront) ;, Gdip_DeleteBrush(pBrushBack)
    	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
    	Return, 0
    }

}

scrollTo(hEdit, scrollPos)	;window ID, Control class name+number, line to scroll to
{	
    topLine := Edit_GetFirstVisibleLine(hEdit)
	; SendMessage, 0xCE, 0, 0, , % "ahk_id" hEdit ; EM_GETFIRSTVISIBLELINE to get first line shown (results stored in ErrorLevel)
	lineSet := scrollPos - topLine - 1	;get difference between current line and zeroth line, subtract one
	PostMessage, 0xB6, 0, % lineSet, , % "ahk_id" hEdit ; EM_LINESCROLL to scroll target to top
	GuiControl, Focus, % "ahk_id" hEdit ; ;%editCNN%	;set focus to the edit ctrl
	; scrollPos--	;EM_LINEINDEX is 0-based, so sub one
	SendMessage, 0xBB, % scrollPos, 0, , % "ahk_id" hEdit ; EM_LINEINDEX to get first char from line (results stored in ErrorLevel)
	PostMessage, 0xB1, % topLine, % topLine, , % "ahk_id" hEdit ; EM_SETSEL to change caret to first character position of line 'lineSel'
}



; Edit_GetFirstVisibleLine(hEdit)
;     {
;     Static EM_GETFIRSTVISIBLELINE:=0xCE
;     SendMessage EM_GETFIRSTVISIBLELINE,0,0,,ahk_id %hEdit%
;     Return ErrorLevel
;     }

/*
max lines := Edit control height - bar height

*/
/* 
class ScrollBar {

    __New(hEdit, width := 10, height := 100, type := "edit", gui := 1) {
        local func
        this.hEdit := hEdit
        If (type = "edit") {
            Edit_HideAllScrollBars(hEdit)
        } else if (type = "listview") {
            LVM_ShowScrollBar(hEdit,SB_BOTH,false)
            ; GuiControl, +LVS_NOSCROLL, % this.hEdit
        }
        Gui, %gui%: Add, Picture, x+2 yp w%width% h%height% 0xE hwndhScrollBar%hEdit% vvScrollBar%hEdit%
        this.type := type
        this.hScrollBar := hScrollBar%hEdit%
        this.StopScrolling := ObjBindMethod(this, "WM_LBUTTONUP")
        this.StartScrolling := ObjBindMethod(this, "WM_LBUTTONDOWN")
        this.Scroll := ObjBindMethod(this, "WM_MOUSEMOVE")
        this.ParentHwnd := DllCall("user32\GetAncestor", Ptr,this.hScrollBar, UInt,1, Ptr) ;GA_PARENT := 1
        ControlGet, hCtl, Hwnd,, Edit1, A
        OnMessage(0x200, this.Scroll)
        OnMessage(0x201, this.StartScrolling)
        OnMessage(0x202, this.StopScrolling)
        func := ObjBindMethod(this, "Update")
        GuiControl +g, % this.hEdit, % func
        this.Update()
    }

    Update(callbackFunc := "", funcParams := "") {
        hEdit := this.hEdit
        GuiControlGet, ctrl, Pos, % this.hEdit
        this.ctrlHeight := ctrlH
        this.ctrlY := ctrlY
        If (this.type = "edit") {
            this.lineCount := Edit_GetLineCount(this.hEdit)
            this.visibleLines := Edit_GetLastVisibleLine(hEdit) - Edit_GetFirstVisibleLine(hEdit)
            newY := Edit_GetFirstVisibleLine(hEdit) + ctrlY
        } Else If (this.type = "listview") {
            this.lineCount := LV_GetCount()
            LVM_GETTOPINDEX = 4135		; gets the first visible row
            LVM_GETCOUNTPERPAGE = 4136	; gets number of visible rows
            SendMessage, LVM_GETCOUNTPERPAGE, 0, 0, , % "ahk_id" this.hEdit
            LV_NumOfRows := ErrorLevel	; get number of visible rows
            SendMessage, LVM_GETTOPINDEX, 0, 0, , % "ahk_id" this.hEdit
            LV_topIndex := ErrorLevel	; get first visible row
            this.visibleLines := LV_topIndex + LV_NumOfRows
            newY := LV_topIndex + ctrlY
            ; msgbox % "So last visible row is " (LV_topIndex + LV_NumOfRows)
        }
        barHeight := ctrlH - this.lineCount + this.visibleLines
        barHeight := barHeight > 35 ? barHeight : 35 - this.visibleLines
        this.barMax := ctrlY + ctrlH - barHeight
        if (newY > this.barMax)
            newY := this.barMax
        this.barHeight := barHeight
        GuiControl, MoveDraw, % this.hScrollbar, h%barheight% y%newY%
        this.RedrawScrollBar()
        if (callbackFunc)
            %callbackFunc%(funcParams)
    }

    RedrawScrollBar() {
        global
        hEdit := this.hEdit
        this.Gdip_ScrollBar(vScrollBar%hEdit%,0xff0993ea)
        if (this.type = "listview")
            LVM_ShowScrollBar(hEdit,3,false)
    }

    WM_LBUTTONDOWN() {
        hEdit := this.hEdit
        CoordMode, Mouse, Client
        MouseGetPos, , y, , vControl, 2
        If (vControl = this.hScrollBar) {
            this.scrolling := 1
            DllCall("SetCapture", "UInt", this.ParentHwnd)
            GuiControlGet, bar, Pos, % this.hScrollBar
            this.diff := y - barY
        }
    }

    WM_LBUTTONUP() {
        If (this.scrolling = 1) {
            this.scrolling := 0
            DllCall("ReleaseCapture")
        }
    }

    WM_MOUSEMOVE() {
        hEdit := this.hEdit
        GuiControlGet, ctrl, Pos, % hEdit
        If (this.scrolling = 1 && GetKeyState("LButton")) {
            CoordMode, Mouse, Client
            GuiControlGet, bar, Pos, % this.hScrollBar
            MouseGetPos, , y
            y -= this.diff
            If (y > this.barMax)
                y := this.barMax
            Else If (y < ctrlY)
                y := ctrlY
            GuiControl, Move, % this.hScrollBar , y%y%

            If (this.type = "edit") {
                if (this.lineCount > this.ctrlHeight) {
                    scrollPos := ((barY - this.ctrlY) / (this.barMax - this.ctrlY))
                    scrollPos := Format("{:d}",this.lineCount * scrollPos)
                    ; If (scrollPos > this.lineCount // 2)
                    ;     scrollPos++
                    ; if 
                    ; scrollPos *= this.lineCount // this.barMax
                    charPos:=Edit_LineIndex(hEdit,Ceil(scrollPos))
                    Edit_SetSel(hEdit,charPos,charPos)
                    Edit_ScrollCaret(hEdit)
                    If (Format("{:d}",scrollPos) = this.lineCount) {
                        RC := Edit_Scroll(this.hEdit,1)
                    }
                } Else {
                    scrollPos := y - barY ;* lineJump
                    ; scrollPos *= this.lineCount // this.barMax
                    RC := Edit_LineScroll(this.hEdit,0,scrollPos)
                }
            } else if (this.type = "listview") {

                scrollPos := ((barY - this.ctrlY) / (this.barMax - this.ctrlY))
                scrollPos := this.lineCount * scrollPos
                if (scrollPos = 0)
                    scrollPos := 1
                ; RC := Edit_LineScroll(this.hEdit,0,scrollPos)
                ; If (scrollPos <> 0)
                ; sendmessage, 0x115, % scrollPos > 0 ? 1 : 0, 0,, % "ahk_id" this.hEdit
                LV_Modify(Format("{:d}",scrollPos), "Vis")
                LVM_ShowScrollBar(hEdit,3,false)
            }
            tooltip, % Format("LineCount:`t{}`nBarmax:`t`t{}`nScrollPos:`t`t{}",this.lineCount,this.barmax,scrollPos)
        }
    }

    Gdip_ScrollBar(ByRef Variable, Color, Background=0x00000000)
    {
    	GuiControlGet, Pos, Pos, Variable
    	GuiControlGet, hwnd, hwnd, Variable
    	pBrushFront := Gdip_BrushCreateSolid(Color) ;, pBrushBack := Gdip_BrushCreateSolid(Background)
    	pBitmap := Gdip_CreateBitmap(Posw, Posh), G := Gdip_GraphicsFromImage(pBitmap), Gdip_SetSmoothingMode(G, 4)
        Gdip_FillRoundedRectangle(G, pBrushFront, 0, 0, Posw, Posh, 5)
    	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
    	SetImage(hwnd, hBitmap)
    	Gdip_DeleteBrush(pBrushFront) ;, Gdip_DeleteBrush(pBrushBack)
    	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
    	Return, 0
    }    

}
 */

/* 
#If WinActive("ahk_id" gui_id)

WheelUp::
RC :=Edit_LineScroll(hEdit,0,-3)
SB_SetText("Return code from request: " . RC)
Return

+WheelUp::
RC :=Edit_LineScroll(hEdit,-3)
SB_SetText("Return code from request: " . RC)
Return

WheelDown::
RC :=Edit_LineScroll(hEdit,0,3)
SB_SetText("Return code from request: " . RC)
Return

+WheelDown::
RC :=Edit_LineScroll(hEdit,3)
SB_SetText("Return code from request: " . RC)
Return
 */
;#######################################################################

GuiClose:
Exit:
; gdi+ may now be shutdown
Gdip_Shutdown(pToken)
ExitApp
Return

/* 

; Create the ListView with two columns, Name and Size:
Gui, Add, ListView, r20 w700 hwndLV_LView, Name|Size (KB)

; Gather a list of file names from a folder and put them into the ListView:
Loop, %A_MyDocuments%\*.*
    LV_Add("", A_LoopFileName, A_LoopFileSizeKB)

LV_ModifyCol()  ; Auto-size each column to fit its contents.
LV_ModifyCol(2, "Integer")  ; For sorting purposes, indicate that column 2 is an integer.

; Display the window and return. The script will be notified whenever the user double clicks a row.
Gui, Show
return


f3::
LVM_GETTOPINDEX = 4135		; gets the first visible row
LVM_GETCOUNTPERPAGE = 4136	; gets number of visible rows

SendMessage, LVM_GETCOUNTPERPAGE, 0, 0, , ahk_id %LV_LView%
LV_NumOfRows := ErrorLevel	; get number of visible rows
SendMessage, LVM_GETTOPINDEX, 0, 0, , ahk_id %LV_LView%
LV_topIndex := ErrorLevel	; get first visible row

msgbox % "So last visible row is " (LV_topIndex + LV_NumOfRows)
return



GuiClose:  ; Indicate that the script should exit automatically when the window is closed.
ExitApp
 */

 ;------------------------------
;
; Function: LVM_EnableScrollBar
;
; Description:
;
;   Enables or disables one or both scroll bar arrows.
;
; Parameters:
;
;   wSBflags - Specifies the scroll bar type.  See the function's static
;       variables for a list of possible values.
;
;   wArrows - Specifies whether the scroll bar arrows are enabled or disabled
;       and indicates which arrows are enabled or disabled.  See the function's
;       static variables for a list of possible values.
;
; Returns:
;
;   TRUE if successful, otherwise FALSE.
;
; Remarks:
;
; * The function will return FALSE (not successful) if the scroll bar(s) are
;   already in the requested state (enabled/disabled).
;
;-------------------------------------------------------------------------------
LVM_EnableScrollBar(hLV,wSBflags,wArrows)
    {
    Static Dummy5401

          ;-- Scrollbar Type
          ,SB_HORZ:=0
                ;-- Enables or disables the arrows on the horizontal scroll bar
                ;   associated with the specified window.

          ,SB_VERT:=1
                ;-- Enables or disables the arrows on the vertical scroll bar
                ;   associated with the specified window.

          ,SB_CTL:=2
                ;-- Indicates that the scroll bar is a scroll bar control.  The
                ;   hWnd  must be the handle to the scroll bar control.

          ,SB_BOTH:=3
                ;-- Enables or disables the arrows on the horizontal and
                ;   vertical scroll bars associated with the specified window.

          ;-- Scrollbar Arrows
          ,ESB_ENABLE_BOTH:=0x0
                ;-- Enables both arrows on a scroll bar.

          ,ESB_DISABLE_LEFT:=0x1
                ;-- Disables the left arrow on a horizontal scroll bar.

          ,ESB_DISABLE_BOTH:=0x3
                ;-- Disables both arrows on a scroll bar.

          ,ESB_DISABLE_DOWN:=0x2
                ;-- Disables the down arrow on a vertical scroll bar.

          ,ESB_DISABLE_UP:=0x1
                ;-- Disables the up arrow on a vertical scroll bar.

          ,ESB_DISABLE_LTUP:=0x1  ;-- Same as ESB_DISABLE_LEFT
                ;-- Disables the left arrow on a horizontal scroll bar or the up
                ;   arrow of a vertical scroll bar.

          ,ESB_DISABLE_RIGHT:=0x2
                ;-- Disables the right arrow on a horizontal scroll bar.

          ,ESB_DISABLE_RTDN:=0x2  ;-- Same as ESB_DISABLE_RIGHT
                ;-- Disables the right arrow on a horizontal scroll bar or the
                ;   down arrow of a vertical scroll bar.


    RC:=DllCall("EnableScrollBar"
        ,(A_PtrSize=8) ? "Ptr":"UInt",hLV               ;-- hWnd
        ,"UInt",wSBflags                                ;-- wSBflags
        ,"UInt",wArrows)                                ;-- wArrows

    Return RC ? True:False
    }

;------------------------------
;
; Function: LVM_ShowScrollBar
;
; Description:
;
;   Shows or hides the specified scroll bar.
;
; Parameters:
;
;   wBar - Specifies the scroll bar(s) to be shown or hidden.  See the
;       function's static variables for a list of possible values.
;
;   p_Show - Determines whether the scroll bar is shown or hidden. If set to
;       TRUE (the default), the scroll bar is shown; otherwise, it is hidden.
;
; Returns:
;
;   TRUE if successful, otherwise FALSE.
;
; Remarks:
;
; * You should not call this function to hide a scroll bar while processing a
;   scroll bar message.
;
; * Under most circumstances, showing/hiding a scroll bar is only a temporary
;   effect.  Many changes to the ListView control (selecting, scrolling,
;   resizing, etc.) will re-show or re-hide a scroll bar.
;
; Observations:
;
; * Unlike <LVM_EnableScrollBar>, this function returns TRUE (successful) even
;   if the scroll bar(s) are already in the requested state (showing/hidden).
;
;-------------------------------------------------------------------------------
LVM_ShowScrollBar(hLV,wBar,p_Show=True)
    {
    Static Dummy6622

          ;-- Scroll bar flags
          ,SB_HORZ:=0
            ;-- Shows or hides a window's standard horizontal scroll bars.

          ,SB_VERT:=1
            ;-- Shows or hides a window's standard vertical scroll bar.

          ,SB_CTL:=2
            ;-- Shows or hides a scroll bar control. The hLV parameter must be
            ;   the handle to the scroll bar control.

          ,SB_BOTH:=3
            ;-- Shows or hides a window's standard horizontal and vertical
            ;   scroll bars.

    RC:=DllCall("ShowScrollBar"
        ,(A_PtrSize=8) ? "Ptr":"UInt",hLV               ;-- hWnd
        ,"UInt",wBar                                    ;-- wbar
        ,"UInt",p_Show)                                 ;-- bShow

    Return RC ? True:False
    }