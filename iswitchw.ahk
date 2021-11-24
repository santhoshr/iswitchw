;----------------------------------------------------------------------
; ENSURE YOU'RE RUNNING WITH THE x64 VERSION OF AHK
; FOR PROPER BROWSER TAB SUPPORT
;
; Vivaldi support is presently broken
;
;

/* 
class Options {

  static defaults := {"compact":}

  __New() {

  }
}
 */
;----------------------------------------------------------------------
;
; User configuration
;

; Use small icons in the listview
Global compact := true

; A bit of a hack, but this 'hides' the scorlls bars, rather the listview is    
; sized out of bounds, you'll still be able to use the scroll wheel or arrows
; but when resizing the window you can't use the left edge of the window, just
; the top and bottom right.
Global hideScrollBars := false ;true

; Uses tcmatch.dll included with QuickSearch eXtended by Samuel Plentz
; https://www.ghisler.ch/board/viewtopic.php?t=22592
; Supports Regex, Simularity, Srch & PinYin
; Included in lib folder, no license info that I could find
; see readme in lib folder for details, use the included tcmatch.ahk to change settings
; By default, for different search modes, start the string with:
;   ? - for regex
;   * - for srch    
;   < - for simularity
; recommended '*' for fast fuzzy searching; you can set one of the other search modes as default here instead if destired
DefaultTCSearch := "" 

; Activate the window if it's the only match
activateOnlyMatch := false

; Hides the UI when focus is lost!
hideWhenFocusLost := true

; Window titles containing any of the listed substrings are filtered out from results
; useful for things like  hiding improperly configured tool windows or screen
; capture software during demos.
filters := []
; "NVIDIA GeForce Overlay","HPSystemEventUtilityHost"

; Add folders containing files or shortcuts you'd like to show in the list.
; Enter new paths as an array
; todo: show file extensions/path in the list, etc.
; shortcutFolders := []
shortcutFolders := ["C:\Users\" A_UserName "\OneDrive\Desktop"
,"C:\Users\" A_UserName "\OneDrive\Documents"]

; Set this to true to update the list of windows every time the search is
; updated. This is usually not necessary and creates additional overhead, so
; it is disabled by default. 
refreshEveryKeystroke := false

;----------------------------------------------------------------------
;s
; Global variables
;
;     allwindows  - windows on desktop
;     windows     - windows in listbox
;     search      - the current search string
;     lastSearch  - previous search string
;     switcher_id - the window ID of the switcher window
;     compact     - true when compact listview is enabled (small icons)
;
;----------------------------------------------------------------------
global vivaldiTabObj, chromeTabObj, switcher_id, hlv

#SingleInstance force
#WinActivateForce
#NoEnv
#MaxHotkeysPerInterval, 9999
; #NoTrayIcon
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
SaveTimer := Func("SaveTimer")
OnExit("Quit")

; Load saved position from settings.ini
IniRead, gui_pos, settings.ini, position, gui_pos, 0

OnMessage(0x20, "WM_SETCURSOR")
OnMessage(0x200, "WM_MOUSEMOVE")
OnMessage(0x201, "WM_LBUTTONDOWN")

fileList := []
if IsObject(shortcutFolders) {
  for i, e in shortcutFolders
    Loop, Files, % e "\*"	
    fileList.Push({"fileName":RegExReplace(A_LoopFileName,"\.\w{3}$"),"path":A_LoopFileFullPath})
}

Menu, Context, Add, Options, MenuHandler
Menu, Context, Add, Exit, MenuHandler

; Gui, +Hwndgui_id -Caption -MaximizeBox -Resize -DpiScale +E0x02000000 +E0x00080000 
Gui, +LastFound +AlwaysOnTop -Caption -Resize -DPIScale +Hwndswitcher_id
Gui, Color, black, 191919
WinSet, Transparent, 225
Gui, Margin, 8, 10
Gui, Font, s14 cEEE8D5, Segoe MDL2 Assets
Gui, Add, Text, xm+5 ym+3, % Chr(0xE721)
Gui, Font, s10 cEEE8D5, Segoe UI
Gui, Add, Edit, w420 h25 x+10 ym gSearchChange vsearch -E0x200,
Gui, Add, ListView, % (hideScrollbars ? "x0" : "x9") " y+8 w490 h500 -VScroll -HScroll -Hdr -Multi Count10 AltSubmit vlist hwndhLV gListViewClick 0x2000 +LV0x10000 -E0x200", index|title|proc|tab
Gui, Show, , Window Switcher
WinWaitActive, ahk_id %switcher_id%, , 1
if gui_pos
  SetWindowPosition(switcher_id, StrSplit(gui_pos, A_Space)*)
LV_ModifyCol(4,0)
Resize()
WinHide, ahk_id %switcher_id%

; Add hotkeys for number row and pad, to focus corresponding item number in the list 
numkey := [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0"]
for i, e in numkey {
  num := StrReplace(e, "Numpad")
  KeyFunc := Func("ActivateWindow").Bind(num = 0 ? 10 : num)
  Hotkey, IfWinActive, % "ahk_id" switcher_id
    Hotkey, % "#" e, % KeyFunc
}

; Define hotstrings for selecting rows, by typing the number with a space after
Loop 300 {
  KeyFunc := Func("ActivateWindow").Bind(A_Index)
  Hotkey, IfWinActive, % "ahk_id" switcher_id
    Hotstring(":X:" A_Index , KeyFunc)
}

chromeTabObj := Object(), vivaldiTabObj := Object()

SetTimer, RefreshTimer, 3000
Settimer, CheckIfVisible, 20

Return

#Include lib\Accv2.ahk

GuiContextMenu() {
  global
  Menu, Context, Show
}

MenuHandler() {
  Switch A_ThisMenuItem {
    Case "Options"  : return
    Case "Exit"     : ExitApp 
  }
}

CheckIfVisible:
  DetectHiddenWindows, Off
  pauseRefresh := WinExist("ahk_id" switcher_id) != "0x0" ? 1 : 0
return

;----------------------------------------------------------------------
;
; Win+space to activate.
;
; #space::  
CapsLock:: ; Use Shift+Capslock to toggle while in use by the hotkey
  LV_Modify(LV_GetNext(),"-Select -Focus")
  allwindowobj := GetAllWindows()
  If WinActive("ahk_class Windows.UI.Core.CoreWindow") ; clear the search/start menu if it's open, otherwise it keeps stealing focus
    Send, {esc}
  search := lastSearch := ""
  allwindows := Object()
  GuiControl, , Edit1
  FadeShow()
  ; WinShow, ahk_id %switcher_id%
  WinActivate, ahk_id %switcher_id%
  WinGetPos, , , w, h, ahk_id %switcher_id%
  WinSet, Region , 0-0 w%w% h%h% R15-15, ahk_id %switcher_id%
  WinSet, AlwaysOnTop, On, ahk_id %switcher_id%
  ControlFocus, Edit1, ahk_id %switcher_id%
  If hideWhenFocusLost
    SetTimer, HideTimer, 10

Return

tooltipOff:
  ToolTip
Return

#If WinActive("ahk_id" switcher_id)
Enter::       ; Activate window
Escape::      ; Close window
^Backspace::  ; Clear text
^w::          ; ''
^h::          ; Backspace
Down::        ; Next row
Tab::         ; ''
^k::          ; ''
Up::          ; Previous row
+Tab::        ; ''
^j::          ; ''
PgUp::        ; Jump up 4 rows
PgDn::        ; Jump down 4 rows
^Home::       ; Jump to top
^End::        ; Jump to bottom
!F4::         ; Quit
~Delete::
~Backspace::
  SetKeyDelay, -1
  Switch A_ThisHotkey {
    Case "Enter": ActivateWindow()
    Case "Escape": FadeHide() ;WinHide, ahk_id %switcher_id%
    Case "^Home": LV_ScrollTop()
    Case "^End": LV_ScrollBottom()
    Case "!F4": ExitApp 
    Case "^h": ControlSend, Edit1, {Backspace}, ahk_id %switcher_id%
  Case "~Delete", "~Backspace", "^Backspace", "^w":
    If (SubStr(search, 1, 1) != "?"
        && DefaultTCSearch != "?"
    && ((windows.MaxIndex() < 1 && LV_GetCount() > 1) || LV_GetCount() = 1))
    GuiControl, , Edit1,
    Else If (A_ThisHotkey = "^Backspace" || A_ThisHotkey = "^w")
      ControlSend, Edit1, ^+{left}{Backspace}, ahk_id %switcher_id%
  Case "Tab", "+Tab", "Up", "Down", "PgUp", "PgDn", "^k", "^j":
    page := InStr(A_ThisHotkey,"Pg")
    row := LV_GetNext()
    jump := page ? 4 : 1
    If (row = 0)
      row := 1
    row := GetKeyState("Shift") || InStr(A_ThisHotkey,"Up") || InStr(A_ThisHotkey,"^k") ? row - jump : row + jump
    If (row > LV_GetCount())
      row := page ? LV_GetCount() : 1
    Else If (row < 1)
      row := page ? 1 : LV_GetCount()
    LV_Modify(row, "Select Focus Vis")
    if (row > LV_VisibleRows().2) {
      LV_ScrollBottom(row)
    } else if (row <= LV_VisibleRows().1) {
      LV_ScrollTop(row)
    }
  }
  Return

#If WinActive("ahk_id" switcher_id)
WheelDown::
LV_ScrollDown() {
  if (LV_VisibleRows().2 < LV_GetCount())
    sendmessage, 0x115, 1, 0,, ahk_id %hlv%
}
return

WheelUp::
LV_ScrollUp() {
  if (LV_VisibleRows().1 > 0)
    sendmessage, 0x115, 0, 0,, ahk_id %hlv%
}
return  
#if

LV_ScrollBottom(row := "") {
  totalRows := LV_GetCount()
  if !row
    row := totalRows
  loop {
    lastVisibleRow := LV_VisibleRows().2
    if (lastVisibleRow >= row || A_Index > totalRows)
      break
    sendmessage, 0x115, 1, 0,, ahk_id %hlv%
  } ;Until (lastVisibleRow >= row || lastVisibleRow >= totalRows)
  LV_Modify(row, "Select Focus")
}

LV_ScrollTop(row := "") {
  totalRows := LV_GetCount()
  if !row
    row := 1
  loop {
    firstVisibleRow := LV_VisibleRows().1
    if (firstVisibleRow <= row - 1 || A_Index > totalRows)
      break
    sendmessage, 0x115, 0, 0,, ahk_id %hlv%
  } ;Until (firstVisibleRow <= row - 1 || firstVisibleRow <= 0)
  LV_Modify(row, "Select Focus")
}

LV_VisibleRows() {
  global hlv
  static LVM_GETTOPINDEX = 4135		; gets the first visible row
  , LVM_GETCOUNTPERPAGE = 4136	; gets number of visible rows
    SendMessage, LVM_GETCOUNTPERPAGE, 0, 0, , ahk_id %hLV%
    LV_NumOfRows := ErrorLevel	; get number of visible rows
    SendMessage, LVM_GETTOPINDEX, 0, 0, , ahk_id %hLV%
    LV_topIndex := ErrorLevel	; get first visible row
  return [LV_topIndex, LV_topIndex + LV_NumOfRows, LV_NumOfRows] ; [Top row, last row, total visible]
}

SaveTimer() {
  global switcher_id, gui_pos
  CoordMode, Pixel, Screen
  WinGetPos, x, y, w, h, % "ahk_id" switcher_id
  IniWrite, % Format("{} {} {} {}",x,y,w,h) , settings.ini, position, gui_pos
}

; Hides the UI if it loses focus
HideTimer:
  If !WinActive("ahk_id" switcher_id) {
    FadeHide()
    SetTimer, HideTimer, Off
  }
Return

Quit() {
  WinShow, ahk_id %switcher_id%
  SaveTimer()
}

;----------------------------------------------------------------------
;
; Runs whenever Edit control is updated
SearchChange() {
  global
  Gui, Submit, NoHide
  if ((search ~= "^\d+") || (StrLen(search) = 1 && SubStr(search, 1, 1) ~= "[?*<]"))
    return 
  Settimer, Refresh, -1
}

Refresh:
  if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  StartTime := A_TickCount
  RefreshWindowList()
  ElapsedTime := A_TickCount - StartTime
  If (LV_GetCount() > 1) {
    Gui, Font, % LV_GetCount() > 1 && windows.MaxIndex() < 1 ? "cff2626" : "cEEE8D5"
    GuiControl, Font, Edit1
  } Else if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  ; For i, e in windows {
  ;   str .= Format("{:-4} {:-15} {:-55}`n",A_Index ":",SubStr(e.procName,1,14),StrLen(e.title) > 50 ? SubStr(e.title,1,50) "..." : e.title)
  ; }
  ; if search
  ; OutputDebug, % "lvcount: " LV_GetCount() " - windows: " windows.MaxIndex()
  ; . "`n------------------------------------------------------------------------------------------------" 
  ; . Format("`nNew filter: {} | Result count: {:-4} | Time: {:-4} | Search string: {} ",toggleMethod ? "On " : "Off",LV_GetCount(),ElapsedTime,search)
  ; . "`n------------------------------------------------------------------------------------------------`n" . str
  ; str := ""
return

;----------------------------------------------------------------------
;
; Handle mouse click events on the listview
;
ListViewClick:
  if (A_GuiControlEvent = "Normal") {
    ActivateWindow()
  }
return

IncludedIn(needle,haystack) {
  for i, e in needle {
    if InStr(haystack,e)
      return i
  }
  return -1
}

GetAllWindows() {
  allWindowObj := []
  top := DllCall("GetTopWindow", "Ptr","")
  Loop {
    next :=	DllCall("GetWindow", "Ptr", (A_Index = 1 ? top : next),"uint",2)
    allWindowObj.Push(next)
  } Until (!next)
  return allWindowObj
}
;----------------------------------------------------------------------
;
; Fetch info on all active windows
;
ParseAllWindows() {
  global switcher_id, filters, allwindowObj, vivaldiTabObj, chromeTabObj
  windows := Object()
  top := DllCall("GetTopWindow", "Ptr","")
  Loop {
    next :=	DllCall("GetWindow", "Ptr", (A_Index = 1 ? top : next),"uint",2)
    ; for _, next in allwindowObj {
    WinGetTitle, title, % "ahk_id" next
    if IncludedIn(filters, title) > -1
      continue
    if title {
      procName := GetProcessName(next)
      if (procName = "chrome") {
        for i, e in chromeTabObj[next] {
          if (!e || e ~= "i)group.*and \d+ other tabs") ; remove blank titles that appears when there are grouped tabs
            continue
          if RegExMatch(e, "i)(.*) - Part of.*group\s?(.*)", match) ; appends group name to grouped tabs
            e := (match2 ? match2 : "Group") . " " . Chr(0x2022) . " " . match1
          windows.Push({"id":next, "title": e, "procName": "Chrome tab", "num": i,"hwnd":next})
        }
      } else if (procName = "firefox") {
        tabs := StrSplit(JEE_FirefoxGetTabNames(next),"`n")
        for i, e in tabs
          windows.Push({"id":next, "title": e, "procName": "Firefox tab", "num": i})
      } else if (procName = "vivaldi") {
        for i, e in vivaldiTabObj[next]
          windows.Push({"id":next, "title": e.title, "procName": "Vivaldi tab", "accpath":e.accpath,"hwnd":next})
      } Else {
        windows.Push({ "id": next, "title": title, "procName": procName })
      }
    }
  } Until (!next)

return windows
}

RefreshWindowList() {
  global allwindows, windows, scoreMatches, fileList
  global search, lastSearch, refreshEveryKeystroke
  windows := []
  toRemove := ""
  If (DefaultTCSearch = "?" || SubStr(search, 1, 1) = "?" || !search || refreshEveryKeystroke || StrLen(search) < StrLen(lastSearch)) {
    allwindows := ParseAllWindows()
    for _, e in fileList {
      path := e.path 
      SplitPath, path, OutFileName, OutDir, OutExt, OutNameNoExt, OutDrive
      RegExMatch(OutDir, "\\(\w+)$", folder)
      allwindows.Push({"procname":folder1,"title":e.fileName . (!RegExMatch(OutExt,"txt|lnk") ? "." OutExt : "" ),"path":e.path})
    }
  }
  lastSearch := search
  for i, e in allwindows {
    str := e.procName " " e.title
    if !search || TCMatch(str,search) {
      windows.Push(e)
    } else {
      toRemove .= i ","
    }
  }
  ; OutputDebug, % "Allwindows count: " allwindows.MaxIndex() " | windows count: " windows.MaxIndex() "`n"
  DrawListView(windows)
  for i, e in StrSplit(toRemove,",")
    allwindows.Delete(e)
}

ActivateWindow(rowNum := "") {

  global windows, ChromeInst
  If !rowNum 
    rowNum:= LV_GetNext("F")
  If (rowNum > LV_GetCount())
    return
  LV_GetText(procName, rowNum, 2)
  LV_GetText(title, rowNum, 3)
  LV_GetText(wid, rowNum, 4)
  Gui Submit
  window := windows[rowNum]
  num := window.num
  path := window.path
  If window.HasKey("path") {
    Run, % """" path """" 
  } Else {
    If (procName = "Chrome tab")
      JEE_ChromeFocusTabByNum(wid,num)
    Else If (procName = "Firefox tab")
      JEE_FirefoxFocusTabByNum(wid,num)
    Else If (procName = "Vivaldi tab")
      VivaldiFocusTab(wid,title,window.accPath)
    If WinActive("ahk_id" wid) {
      WinGet, state, MinMax, ahk_id %wid%
      if (state = -1) {
        WinRestore, ahk_id %wid%
      }
    } else {
      WinActivate, ahk_id %wid%
    }
  }
}

;------------------------------------------------------------5----------
;
; Add window list to listview
;
DrawListView(windows, startFrom := 0) {
  Global switcher_id, fileList, hlv
  static IconArray
  , WS_EX_TOOLWINDOW = 0x80
  , WS_EX_APPWINDOW = 0x40000
  , GW_OWNER = 4
  , WM_GETICON := 0x7F
  ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms632625(v=vs.85).aspx
  , ICON_BIG := 1
  , ICON_SMALL2 := 2
  , ICON_SMALL := 0
  if !WinExist("ahk_id" switcher_id)
    return
  imageListID := IL_Create(windowCount, 1, compact ? 0 : 1)
  If !IsObject(IconArray)
    IconArray := {}
  windowCount := windows.MaxIndex()
  If !windowCount
    return
  iconCount = 0
  removedRows := Array()
  allRows := []

  LV_SetImageList(imageListID, 1)
  LV_GetText(selectedRow, LV_GetNext(),3)
  GuiControl, -Redraw, list
  LV_Delete()
  For idx, window in windows {
    
    wid := window.id
    title := window.title
    procName := window.procName
    tab := window.num

    WinGet, style, ExStyle, ahk_id %wid%
    isAppWindow := (style & WS_EX_APPWINDOW)
    isToolWindow := (style & WS_EX_TOOLWINDOW)

    ownerHwnd := DllCall("GetWindow", "uint", wid, "uint", GW_OWNER)
    iconNumber := ""
    if window.HasKey("path") {
      FileName := window.path
      ; Calculate buffer size required for SHFILEINFO structure.
      sfi_size := A_PtrSize + 8 + (A_IsUnicode ? 680 : 340)
      VarSetCapacity(sfi, sfi_size)
      SplitPath, FileName,,, FileExt ; Get the file's extension.
      for i, e in fileList {
        if (e.path = window.path) {
          fileObj := fileList[i]
          iconHandle := fileObj.icon
          Break
        }
      }
      If !iconHandle {
        if !DllCall("Shell32\SHGetFileInfo" . (A_IsUnicode ? "W":"A"), "Str", FileName
        , "UInt", 0, "Ptr", &sfi, "UInt", sfi_size, "UInt", 0x101) { ; 0x101 is SHGFI_ICON+SHGFI_SMALLICON
          IconNumber := 9999999 ; Set it out of bounds to display a blank icon.
        } else {
          iconHandle := NumGet(sfi, 0)
          fileObj.icon := iconHandle
        }
      }
      if (iconHandle <> 0)
        iconNumber := DllCall("ImageList_ReplaceIcon", UInt, imageListID, Int, -1, UInt, iconHandle) + 1
    } else if (procName ~= "(Chrome|Firefox|Vivaldi) tab" || isAppWindow || ( !ownerHwnd and !isToolWindow )) {
      if !(iconHandle := window.icon) {
        if (procName = "Chrome tab") ; Apply the Chrome icon to found Chrome tabs
          wid := WinExist("ahk_exe chrome.exe")
        else if (procName = "Firefox tab")
          wid := WinExist("ahk_exe firefox.exe")
        else if (procName = "Vivaldi tab")
          wid := WinExist("ahk_exe vivaldi.exe")
        ; http://www.autohotkey.com/docs/misc/SendMessageList.htm

        SendMessage, WM_GETICON, ICON_BIG, 0, , ahk_id %wid%
        iconHandle := ErrorLevel
        if (iconHandle = 0) {
          SendMessage, WM_GETICON, ICON_SMALL2, 0, , ahk_id %wid%
          iconHandle := ErrorLevel
          if (iconHandle = 0) {
            SendMessage, WM_GETICON, ICON_SMALL, 0, , ahk_id %wid%
            iconHandle := ErrorLevel
            if (iconHandle = 0) {
              ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms633581(v=vs.85).aspx
              ; To write code that is compatible with both 32-bit and 64-bit
              ; versions of Windows, use GetClassLongPtr. When compiling for 32-bit
              ; Windows, GetClassLongPtr is defined as a call to the GetClassLong
              ; function.
              iconHandle := DllCall("GetClassLongPtr", "uint", wid, "int", -14) ; GCL_HICON is -14

              if (iconHandle = 0) {
                iconHandle := DllCall("GetClassLongPtr", "uint", wid, "int", -34) ; GCL_HICONSM is -34
                if (iconHandle = 0) {
                  iconHandle := DllCall("LoadIcon", "uint", 0, "uint", 32512) ; IDI_APPLICATION is 32512
                }
              }
            }
          }
        }
      }
      if (iconHandle <> 0) {
        iconNumber := DllCall("ImageList_ReplaceIcon", UInt, imageListID, Int, -1, UInt, iconHandle) + 1
        window.icon := iconHandle
      }
    } else {
      WinGetClass, Win_Class, ahk_id %wid%
      if Win_Class = #32770 ; fix for displaying control panel related windows (dialog class) that aren't on taskbar
        iconNumber := IL_Add(imageListID, "C:\WINDOWS\system32\shell32.dll", 217) ; generic control panel icon
    }
    if (iconNumber < 1) {
      removedRows.Push(idx)
    } else {
      iconCount+=1
      allRows.Push(["Icon" . iconNumber, iconCount, window.procName, title, wid])
      ; LV_Add("Icon" . iconNumber, iconCount, window.procName, title, tab)
    }
  }
  GuiControl, +Redraw, list
  for i, e in allRows { 
    if (i < startFrom)
      continue
      LV_Add(e*)
  }
  loop % LV_GetCount() {
    LV_GetText(r,A_Index,3)
    if (r = selectedRow) {
      LV_Modify(A_Index,"Select Focus Vis")
      break
    }
  }
  ; Don't draw rows without icons.
  windowCount-=removedRows.MaxIndex()
  For key,rowNum in removedRows {
    allRows.RemoveAt(rowNum)
  }

  LV_Modify(1, "Select Focus")

  LV_ModifyCol(1,compact ? 50 : 70)
  LV_ModifyCol(2,110)
  GuiControl, +Redraw, list
  If (windows.Count() = 1 && activateOnlyMatch)
    ActivateWindow(1)
}

RefreshTimer:
  if (pauseRefresh = 0 
      || (WinExist("ahk_exe vivaldi.exe") && vivaldiTabObj.count() = 0) 
  || (WinExist("ahk_exe chrome.exe") && chromeTabObj.count() = 0)) {
    for _, next in allwindowobj {
      procName := GetProcessName(next)
      if ( procname = "vivaldi" && (!IsObject(vivaldiTabObj[next]) || WinActive("ahk_id" next))) {
        vivaldiTabObj[next] := VivaldiGetTabNames(next,1)
      }
      if (procname = "chrome" && (!IsObject(chromeTabObj[next]) || WinActive("ahk_id" next))) {
        chromeTabObj[next] := StrSplit(JEE_ChromeGetTabNames(next),"`n")
      }
    }
    RefreshWindowList()
  }
return

VivaldiGetTabNames(hwnd, reset) {
  returnObj := []
  if (hWnd = "")
    hWnd := WinExist("ahk_exe vivaldi.exe")
  path := AccMatchTextAll(hwnd,{"roletext":"push button","name":"Menu"},"path",0,reset,20,obj)
  path := RegExReplace(path, ".{3}$", "2.1.1.1")
  for i, e in obj {
    if (InStr(e.path, path) && e.name != "" && e.role = 20) {
      ; for _, e2 in returnObj {
      ;   ; if (e2.name = e.name)
      ;     ; continue 2
      ; }
      returnObj.push({"title":e.name,"accpath":e.path})
    }
  }
return returnObj
}

RepStr( Str, Count ) { ; By SKAN / CD: 01-July-2017 | goo.gl/U84K7J
Return StrReplace( Format( "{:0" Count "}", "" ), 0, Str )
}

GetAccPath(Acc, byref hwnd="") {
  hwnd := Acc_WindowFromObject(Acc)
  WinObj := Acc_ObjectFromWindow(hwnd)
  WinObjPos := Acc_Location(WinObj).pos
  while Acc_WindowFromObject(Parent:=Acc_Parent(Acc)) = hwnd {
    t2 := GetEnumIndex(Acc) "." t2
    if Acc_Location(Parent).pos = WinObjPos
      return {AccObj:Parent, Path:SubStr(t2,1,-1)}
    Acc := Parent
  }
  while Acc_WindowFromObject(Parent:=Acc_Parent(WinObj)) = hwnd
    t1.="P.", WinObj:=Parent
return {AccObj:Acc, Path:t1 SubStr(t2,1,-1)}
}

GetEnumIndex(Acc, ChildId := 0) {
  if !ChildId {
    ChildPos := Acc_Location(Acc).pos
    try children := Acc_Children(Acc_Parent(Acc))
    For Each, child in children {
      if (IsObject(child) && Acc_Location(child).pos = ChildPos)
        return A_Index
    }
  } else {
    ChildPos := Acc_Location(Acc,ChildId).pos
    try children := Acc_Children(Acc)
    For Each, child in children {
      if !(IsObject(child) && Acc_Location(Acc,child).pos = ChildPos)
        return A_Index
    }
  }
}

VivaldiFocusTab(hwnd,tabName,path) {
  SetMouseDelay, -1
  SetDefaultMouseSpeed, 0
  If !WinActive("ahk_id" hwnd) {
    WinActivate, % "ahk_id" hwnd
    WinWaitActive, % "ahk_id" hwnd, , 1
    sleep 10
  }
  for _, p in StrSplit(Acc_Get("location",path,0,"ahk_id" hwnd),A_Space)
    var := SubStr(p,1,1), value := SubStr(p,2), %var% := value
  CoordMode, Mouse, Screen
  if (x) {
    MouseGetPos, x2, y2
    Click, % (x +3) . A_Space . (y +3)
    Click, % x2 A_Space y2 A_Space "0"
  }
}

;https://autohotkey.com/boards/viewtopic.php?f=6&t=40615

JEE_ChromeAccInit(vValue)
{
  static vTabs

  ; chrome := WinExist("ahk_exe chrome.exe")
  if (!vTabs && A_ThisLabel)
    vTabs := AccMatchTextAll(WinExist("ahk_exe chrome.exe"),{"roletext":"page tab list"},"path",,1,20) . ".1"
  if (vValue = "U1")
    return "4.1.2.1.2.5.2" ;address bar
  if (vValue = "U2")
    return "4.1.2.2.2.5.2" ;address bar
  if (vValue = "T")
    return vTabs ? vTabs : 0 ;"4.1.2.1.1.1" ;tabs (append '.1' to get the first tab)
}

JEE_ChromeGetTabNames(hWnd:="", vSep:="`n")
{
  local
  static vAccPath
  if !vAccPath
    vAccPath := JEE_ChromeAccInit("T")
  if (hWnd = "")
    hWnd := WinExist("A")
  oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id" hWnd)

  vHasSep := !(vSep = "")
  if vHasSep
    vOutput := ""
  else
    oOutput := []
  for _, oChild in Acc_Children(oAcc)
  {
    ;ROLE_SYSTEM_PUSHBUTTON := 0x2B
    if (oChild.accRole(0) = 0x2B)
      continue
    try vTabText := oChild.accName(0)
    catch
      vTabText := ""
    if vHasSep
      vOutput .= vTabText vSep
    else
      oOutput.Push(vTabText)
  }
  oAcc := oChild := ""
return vHasSep ? SubStr(vOutput, 1, -StrLen(vSep)) : oOutput
}

;==================================================

JEE_ChromeFocusTabByNum(hWnd:="", vNum:="")
{
  local
  static vAccPath
  if !vAccPath
    vAccPath := JEE_ChromeAccInit("T") 
  ; static vAccPath := JEE_ChromeAccInit("T")
  if (hWnd = "")
    hWnd := WinExist("A")
  if !vNum
    return
  oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
  if !Acc_Children(oAcc)[vNum]
    vNum := ""
  else
    Acc_Children(oAcc)[vNum].accDoDefaultAction(0)
  oAcc := ""
return vNum
}

;==================================================

JEE_ChromeFocusTabByName(hWnd:="", vTitle:="", vNum:="")
{
  local
  static vAccPath := JEE_ChromeAccInit("T")
  if (hWnd = "")
    hWnd := WinExist("A")
  if (vNum = "")
    vNum := 1
  oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
  vCount := 0, vRet := 0
  for _, oChild in Acc_Children(oAcc)
  {
    vTabText := oChild.accName(0)
    if (vTabText = vTitle)
      vCount++
    if (vCount = vNum)
    {
      oChild.accDoDefaultAction(0), vRet := A_Index
      break
    }
  }
  oAcc := oChild := ""
return vRet
}

JEE_FirefoxGetTabNames(hWnd:="", vSep:="`n")
{
  local
  if (hWnd = "")
    hWnd := WinExist("A")
  oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
  vRet := 0
  for _, oChild in Acc_Children(oAcc)
  {
    if (oChild.accName(0) == "Browser tabs")
    {
      oAcc := Acc_Children(oChild).1, vRet := 1
      break
    }
  }
  if !vRet
  {
    oAcc := oChild := ""
    return
  }

  vHasSep := !(vSep = "")
  if vHasSep
    vOutput := ""
  else
    oOutput := []
  for _, oChild in Acc_Children(oAcc)
  {
    ;ROLE_SYSTEM_PUSHBUTTON := 0x2B
    if (oChild.accRole(0) = 0x2B)
      continue
    try vTabText := oChild.accName(0)
    catch
      vTabText := ""
    if vHasSep
      vOutput .= vTabText vSep
    else
      oOutput.Push(vTabText)
  }
  oAcc := oChild := ""
return vHasSep ? SubStr(vOutput, 1, -StrLen(vSep)) : oOutput
}

;==================================================

JEE_FirefoxFocusTabByNum(hWnd:="", vNum:="")
{
  local
  if (hWnd = "")
    hWnd := WinExist("A")
  if !vNum
    return
  oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
  vRet := 0
  for _, oChild in Acc_Children(oAcc)
  {
    if (oChild.accName(0) == "Browser tabs")
    {
      oAcc := Acc_Children(oChild).1, vRet := 1
      break
    }
  }
  if !vRet || !Acc_Children(oAcc)[vNum]
    vNum := ""
  else
    Acc_Children(oAcc)[vNum].accDoDefaultAction(0)
  oAcc := oChild := ""
return vNum
}

;==================================================

JEE_FirefoxFocusTabByName(hWnd:="", vTitle:="", vNum:="")
{
  local
  if (hWnd = "")
    hWnd := WinExist("A")
  if (vNum = "")
    vNum := 1
  oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
  vRet := 0
  for _, oChild in Acc_Children(oAcc)
  {
    if (oChild.accName(0) == "Browser tabs")
    {
      oAcc := Acc_Children(oChild).1, vRet := 1
      break
    }
  }
  if !vRet
  {
    oAcc := oChild := ""
    return
  }

  vCount := 0, vRet := 0
  for _, oChild in Acc_Children(oAcc)
  {
    vTabText := oChild.accName(0)
    if (vTabText = vTitle)
      vCount++
    if (vCount = vNum)
    {
      oChild.accDoDefaultAction(0), vRet := A_Index
      break
    }
  }
  oAcc := oChild := ""
return vRet
}

;==================================================

TCMatch(aHaystack, aNeedle) {
  global DefaultTCSearch
  static tcMatch := DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "WStr", "lib\TCMatch" . (A_PtrSize == 8 ? "64" : ""), "Ptr"), "AStr", "MatchFileW","Ptr")
  if (SubStr(aNeedle, 1, 1) != "?" && DefaultTCSearch != "?" ) {
    for i, e in StrSplit("/\[^$.|?*+(){}")
      aHaystack := StrReplace(aHaystack, e, A_Space)
  }
  If ( aNeedle ~= "^[^\?<*]" && DefaultTCSearch )
    aNeedle := DefaultTCSearch . aNeedle
return DllCall(tcMatch, "WStr", aNeedle, "WStr", aHaystack)
}

FadeShow() {
  DllCall("AnimateWindow",UInt,switcher_id,UInt,75,UInt,0xa0000)
}

FadeHide() {
  DllCall("AnimateWindow",UInt,switcher_id,UInt,75,UInt,0x90000)
}

AccMatchTextAll(nWindow, matchList, get := "path", regex := 0, reload := 0, depthLimit := 0, ByRef Obj := "") {
  static
  start := A_TickCount
  if !IsObject(foundPaths)
    foundPaths := Object()
  , matchStr := ""
  , idx := 0
  ; nWindow := WinExist(title)
  ; getObj := (get ~= "^(object|obj|o|all)$")
  if (!IsObject(%nWindow%) || reload = 1)
    %nWindow% := JEE_AccGetTextAll(nWindow, , ,"gpath o" . (depthLimit > 0 ? " l" depthLimit : "") )
  count := matchList.Count()
  obj := %nWindow%
  for k, v in matchList {
    if !v {
      count--
      continue
    }
    idx++
    matchStr .= k . ":" . StrReplace(v,A_Space) ","
  }
  matchStr := RTrim(matchStr,",")
  if (!IsObject(foundPaths[nWindow]) || reload = 1)
    foundPaths[nWindow] := Object()
  else if foundPaths[nWindow].HasKey(matchStr) {
    return getObj ? foundPaths[nWindow,matchStr] : foundPaths[nWindow,matchStr,get]
  }
  for i, e in %nWindow% {
    found := 0
    for k, v in e {
      if (v != "" && matchlist[k] != "" && (getObj || e[get] != "" ))
        if ((regex = 0 && InStr(v,matchlist[k]))
        || (regex = 1 && RegExMatch(v, matchList[k])))
      found++
    }
    if (found = count) {
      foundPaths[nWindow,matchStr] := e
      e.time := A_TickCount - start
      return getObj ? e : e[get]
    }
  }
return
}

JEE_AccGetTextAll(hWnd:=0, vSep:="`n", vIndent:="`t", vOpt:="")
{
  vLimN := 20, vLimV := 20, retObj := 0, vLimL := 0, oOutput := []
  Loop, Parse, vOpt, % " "
  {
    vTemp := A_LoopField
    if (SubStr(vTemp, 1, 1) = "n")
      vLimN := SubStr(vTemp, 2)
    else if (SubStr(vTemp, 1, 1) = "v")
      vLimV := SubStr(vTemp, 2)
    else if (SubStr(vTemp, 1, 1) = "o")
      retObj := 1
    else if (SubStr(vTemp, 1, 1) = "l")
      vLimL := SubStr(vTemp, 2)
  }

  oMem := {}, oPos := {}
  ;OBJID_WINDOW := 0x0
  oMem[1, 1] := Acc_ObjectFromWindow(hWnd, 0x0)
  oPos[1] := 1, vLevel := 1
  VarSetCapacity(vOutput, 1000000*2)

  Loop
  {
    if !vLevel
      break
    if (!oMem[vLevel].HasKey(oPos[vLevel]) || (vLimL > 0 && vLevel > vLimL))
    {
      oMem.Delete(vLevel)
      oPos.Delete(vLevel)
      vLevelLast := vLevel, vLevel -= 1
      oPos[vLevel]++
      continue
    }
    oKey := oMem[vLevel, oPos[vLevel]]

    vName := "", vValue := ""
    if IsObject(oKey)
    {
      try vRole := oKey.accRole(0)
      try vRoleText := Acc_GetRoleText(vRole)
      ; vState := Acc_State(oKey)
      ; vState := Acc_GetStateTextEx2(oKey.accState(0))
      try vName := oKey.accName(0)
      try vValue := oKey.accValue(0)
    }
    else
    {
      oParent := oMem[vLevel-1,oPos[vLevel-1]]
      vChildId := IsObject(oKey) ? 0 : oPos[vLevel]
      try vRole := oParent.accRole(vChildID)
      try vRoleText := Acc_GetRoleText(vRole)
      ; vState := Acc_State(oParent)
      ; vState := Acc_GetStateTextEx2(oParent.accState(0))
      try vName := oParent.accName(vChildID)
      try vValue := oParent.accValue(vChildID)
    }

    vAccPath := ""
    if IsObject(oKey)
    {
      Loop, % oPos.Length() - 1
        vAccPath .= (A_Index=1?"":".") oPos[A_Index+1]
    }
    else
    {
      Loop, % oPos.Length() - 2
        vAccPath .= (A_Index=1?"":".") oPos[A_Index+1]
      vAccPath .= " c" oPos[oPos.Length()]
    }

    if retObj {
      oOutput.Push({path:vAccPath,name:vName,value:vValue,roletext:vRoleText,role:vRole,state:vState,depth:vLevel})
    } else {
      if (StrLen(vName) > vLimN)
        vName := SubStr(vName, 1, vLimN) "..."
      if (StrLen(vValue) > vLimV)
        vValue := SubStr(vValue, 1, vLimV) "..."
      vName := RegExReplace(vName, "[`r`n]", " ")
      vValue := RegExReplace(vValue, "[`r`n]", " ")
      vOutput .= vAccPath "`t" JEE_StrRept(vIndent, vLevel-1) vRoleText " [" vName "][" vValue "]" vSep
    }

    Try oChildren := Acc_Children(oKey)
    if !oChildren.Length()
      oPos[vLevel]++
    else
    {
      vLevelLast := vLevel, vLevel += 1
      oMem[vLevel] := oChildren
      oPos[vLevel] := 1
    }
  }

return retObj = 1 ? oOutput : SubStr(vOutput, 1, -StrLen(vSep))
}

JEE_StrRept(vText, vNum)
{
  if (vNum <= 0)
    return
return StrReplace(Format("{:" vNum "}", ""), " ", vText)
}

~LButton Up::
  critical
  If isResizing {
    Resize()
    SetTimer, % SaveTimer, -500 
    ; Tooltip
    isResizing := 0
    DllCall("ReleaseCapture")
  }
return

WM_LBUTTONDOWN() {

  global isResizing, resizeBorder, Windows
  static topBorder := 29

  if !A_Gui
    return

  ; Capture mouse if cursor is over the resize area
  If (!isResizing && resizeBorder) {
    isResizing := 1
    DllCall("SetCapture", "UInt", switcher_id)
    return
  }

  MouseGetPos, , mouseY,, ctrl
  If ( A_Gui && mouseY < topBorder )
    PostMessage, 0xA1, 2 ; 0xA1 = WM_NCLBUTTONDOWN
  ; If (ctrl = "SysListView321")
  ;   ControlFocus, % ctrl, % "ahk_id" switcher_id

}

WM_SETCURSOR() {

  global resizeBorder
  static borderSize := 6
  , cornerMargin := 12
  , IDC_SIZENS := 32645
  , IDC_SIZEWE := 32644
  , IDC_SIZENWSE := 32642
  , IDC_SIZENESW := 32643
  , IDC_HAND := 32649
  , SPI_SETCURSORS := 0x57
  , borderOffset := 0
  , LastCursor, CursorHandle

  if !A_Gui
    return

  WinGetPos, winX, winY, winWidth, winHeight, % "ahk_id" switcher_id
  borderW := winX + borderOffset
  , borderN := winY + borderOffset
  , borderE := winX + winWidth - borderOffset
  , borderS := winY + winHeight - borderOffset

  CoordMode, Mouse, Screen
  MouseGetPos, mouseX, mouseY, varWin, varControl
  GuiControlGet, ctrlText,, % varControl
  GuiControlGet, ctrlName, Name, % varControl

  Switch
  {
    Case (InRange(mouseX, borderW, cornerMargin ) && InRange(mouseY, borderN, cornerMargin )) : corner := "NW"
    Case (InRange(mouseX, borderE - cornerMargin, cornerMargin ) && InRange(mouseY, borderN, cornerMargin )) : corner := "NE"
    Case (InRange(mouseX, borderW, cornerMargin ) && InRange(mouseY, borderS - cornerMargin, cornerMargin )) : corner := "SW"
    Case (InRange(mouseX, borderE - cornerMargin, cornerMargin ) && InRange(mouseY, borderS - cornerMargin, cornerMargin )) : corner := "SE"
    default: corner := ""
  }

  Switch
  {
    Case InRange(mouseY, borderN, borderSize) : resizeBorder := "N"
    Case InRange(mouseY, borderS - borderSize, borderSize) : resizeBorder := "S"
    Case InRange(mouseX, borderE - borderSize, borderSize) : resizeBorder := "E"
    Case InRange(mouseX, borderW, borderSize) : resizeBorder := "W"
    default: resizeBorder := ""
  }

  resizeBorder := corner ? corner : resizeBorder

  Switch resizeBorder {
    Case "N", "S" : cursor := IDC_SIZENS
    Case "W", "E" : cursor := IDC_SIZEWE
    Case "SE", "NW" : cursor := IDC_SIZENWSE
    Case "SW", "NE" : cursor := IDC_SIZENESW
    default: cursor := ""
  }

  If (cursor) {
    CursorHandle := DllCall("LoadCursor", "ptr", 0, "ptr", Cursor, "ptr")
    LastCursor := DllCall("SetCursor", "uint", CursorHandle)
    Return true
  } ;else return

}

InRange(val, start, count) {
  return val >= start && val <= start + count
}

WM_MOUSEMOVE() {

  global resizeBorder, isResizing, borderOffset
  static minWidth := 200
  , minHeight := 150

  if !A_Gui
    return
  ListLines, On
  WinGetPos, winX, winY, winWidth, winHeight, % "ahk_id" switcher_id
  CoordMode, Mouse, Screen
  MouseGetPos, mouseX, mouseY

  If isResizing {

    winSYPos := winY + winHeight
    winEXPos := winX + winWidth

    If InStr(resizeBorder, "W") {
      newWidth := winEXPos - mouseX
      If (newWidth > minWidth && mouseX > 0)
        winX := mouseX
      Else
        newWidth := winWidth
    } Else If InStr(resizeBorder, "E") {
      newWidth := mouseX - winX
      newWidth := newWidth > minWidth ? newWidth : winWidth 
    } Else {
      newWidth := winWidth
    }

    If InStr(resizeBorder, "N") {
      newHeight := winSYPos - mouseY
      If (newHeight > minHeight && mouseY > 0)
        winY := mouseY
      else
        newHeight := winHeight
    } Else If InStr(resizeBorder, "S") {
      newHeight := mouseY - winY
      newHeight := newHeight > minHeight ? newHeight : winH
    } Else {
      newHeight := winHeight
    }
    if (newWidth <= 220 || newHeight <= 127)
      return  
    SetWindowPosition(switcher_id,winX,winY,newWidth,newHeight)
    Resize(newWidth,newHeight)
  }
}

Resize(width := "", height := "") {
  critical
  global hLV
  if (LV_VisibleRows().2 = LV_GetCount())
    LV_ScrollDown()
    ; sendmessage, 0x115, 0, 0,, ahk_id %hlv%  
  if (!width || !height)
    WinGetPos,,, width, height, % "ahk_id" switcher_id
  WinSet, Region , 0-0 w%width% h%height% R15-15, ahk_id %switcher_id%
  GuiControl, Move, list, % "w" (hideScrollBars ? width + 20 : width - 20) " h" height - 50
  GuiControl, Move, search, % "w" width - 52
  LV_ModifyCol(3
    , width - ( hideScrollBars
      ? (compact ? 170 : 190) ; Resizes column 3 to match gui width
    : (compact ? 200 : 220)))
  }

  SetWindowPosition(hwnd, x := "", y := "", w := "", h := "") {
    global hLV
    DllCall("SetWindowPos","uint",hwnd,"uint",0
      ,"int",x,"int",y,"int",w,"int",h
    ,"uint",0x40)
  }

GetProcessName(wid) {
  WinGet, name, ProcessName, ahk_id %wid%
  return StrSplit(name, ".").1
}
