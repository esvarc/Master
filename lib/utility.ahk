args_parse() { ; parsovani argumentu z příkazové řádky
  global g_isDebug := false, g_isAFK := false
  for _, param in A_Args {
    (param == "debug") ? (g_isDebug := true) : (_:=1)
    (param == "afk") ? (g_isAFK := true) : (_:=1)
  }
}
tray_update() { ; ikona a tooltip v tray
  global g_isDebug, g_isAFK
  static aIcons := {
    auto     : ["ico\auto.ico", -10],
    down     : ["ico\down.ico", -11],
    expand   : ["ico\expand.ico", -12],
    globe    : ["ico\globe.ico", -13],
    info     : ["ico\info.ico", -14],
    question : ["ico\question.ico", -15],
    shield   : ["ico\shield.ico", -16],
    stop     : ["ico\stop.ico", -17],
  }
  sTrayMsg := Const.S_PROGRAM_TITLE, sICO := aIcons.stop[(A_IsCompiled ? 2 : 1)]
  (g_isDebug ? (sTrayMsg .= "[D]", sICO := aIcons.question[(A_IsCompiled ? 2 : 1)]) : (_:=1))
  g_isAFK ? (sTrayMsg .= "[A]", sICO := aIcons.shield[(A_IsCompiled ? 2 : 1)]) : (_:=1)
  g_isDebug ? log_add(A_ThisFunc " icon '" sICO "' tooltip '" sTrayMsg "'") : (_:=1)
  (A_IsCompiled ? TraySetIcon(A_ScriptFullPath, sICO) : TraySetIcon(sICO))
  A_IconTip := sTrayMsg
}
class logQueue { ; fifo fronta pro debug zprávy
  items := ""
  log := ""
  __new() {
    this.items := Array()
    (!InStr(FileExist(Const.S_LOG_BASE_DIR), "D")) ? DirCreate(Const.S_LOG_BASE_DIR) : (_:=1) ; pro jistotu vytvořím base dir
    this.log := Const.S_LOG_BASE_DIR  "\" StrReplace(A_ScriptName,(A_IsCompiled ? ".exe" : ".ahk"),".log") ; soubor s logováním
  }
  put(item:="") {
    ((item != "") ? this.items.Push(item) : (_:=1))
  }
  get() {
    val := (this.items.length ? this.items.RemoveAt(1) : "")
    return ((!val) ? "" : val)
  }
  flush() {
    try {
      if this.items.length {
        oFile := FileOpen(this.log, "a", Const.S_FILE_ENCODING)
        while ((sText := this.get())) {
          (oFile ? oFile.WriteLine(sText) : (_:=1))
        }
        (oFile ? oFile.Close() : (_:=1))
      }
    } catch Error as e {
      ; supress error, log file may be locked by another process      
    }
  }
}
log_init() { ; inicializace proměnných a debug
  global g_oLog, g_isDebug, g_isAFK, g_oScreen, g_oWatch
  g_oLog := logQueue() ; fronta debug zpráv
  OnExit(ExitFunc)
  log_add(A_ThisFunc " (" Const.S_PROGRAM_TITLE ") debug " (g_isDebug ? "ON" : "OFF") " compiled " (A_IsCompiled ? "YES" : "NO"), true), log_flush()
  g_oScreen := winMax() ; načtení konfigurace
  g_oWatch := winWatch() ; načtení konfigurace
  g_isAFK ? afk_toggle(true) : (_:=1) ; force AFK pokud je nastaveno v příkazové řádce
}
log_add(sText,info:=false) { ; přidání debug textu do fronty
  global g_isDebug, g_oLog
  msg := Format("{} {} {}",FormatTime(,Const.S_LOG_STAMP),(info ? "INF" : "DBG"),sText)
  OutputDebug(Const.S_DEBUG_PREFIX msg)
  ((g_isDebug || info) ? (g_oLog.put(msg)) : (_:=1)) ; do fronty
}
log_flush() { ; zápis fronty do souboru
  global g_oLog
  g_oLog.flush()
}
log_toggle() { ; přepnutí debug výstupu
  global g_isDebug 
  g_isDebug := !g_isDebug, log_add(A_ThisFunc " debug is " (g_isDebug ? "ON" : "OFF"),true), log_flush(), tray_update()
}
log_error(func, e,*) { ; ošetření chyby a dump v případě kompilovaného skriptu
  out := func " in " (e.File) " at " (e.Line) " Message '" (e.Message) "'"
  (Trim(e.What) != "") ? (out .= " What '" (e.What) "'") : (_:=1)
  (Trim(e.Extra) != "") ? (out .= " Extra '" (e.Extra) "'") : (_:=1)
  msg := Format("{} {} {}",FormatTime(,Const.S_LOG_STAMP),"ERR",out)
  OutputDebug(Const.S_DEBUG_PREFIX msg), g_oLog.put(msg)
  return true
}
reload_reload() { ; reload nové verze skriptu nebo konfigurace
  global g_isDebug, g_isAFK, g_oScreen, g_oWatch
  if !A_IsCompiled {
    sCmd := A_AhkPath " /restart "  A_ScriptFullPath (g_isDebug ? " debug" : "") (g_isAFK ? " afk" : "")
    log_add(A_ThisFunc " [" sCmd  "]",true)
    log_flush()
    run sCmd, A_ScriptDir
  } else {
    log_add(A_ThisFunc " reload konfigurace!",true)
    g_oScreen := winMax()
    g_oWatch := winWatch()
  }
}
reload_quit() { ; ukončí tento skript
  log_add(A_ThisFunc,true), log_flush()
  ExitApp(0)
}
ExitFunc(ExitReason, ExitCode) { ; ošetření ukončení skriptu
  log_flush() ; zprávy ve frontě se zapíší do souboru
}
hold_keys(isOn := true, sKeyString := "", sKeyEnd := "") { ; držení kláves(y), je možné zadat více '+' je oddělovač, do té doby než se stiskne jakákoliv klávesa.
  static aKeys := ""
  if (isOn) {
    Sleep(500) ; počkat nějaký čas
    aKeys := StrSplit(sKeyString, "+")
    for key in aKeys {
      Send("{" key " down}")
      Sleep(250) ; nemačkat je příliš rychle
    }
    timer := () => timer_hold(timer, sKeyEnd)
    SetTimer(timer, 100)
  } else {
    for key in aKeys {
      Send("{" key " up}")
    }
    aKeys := ""
  }
}
afk_toggle(force:=false) { ; blokuje screen saver
  global g_isAFK
  static ES_CONTINUOUS := 0x80000000, ES_SYSTEM_REQUIRED  := 0x00000001, ES_DISPLAY_REQUIRED := 0x00000002
  force ? (g_isAFK := true) : (g_isAFK := !g_isAFK)
  g_isAFK ? DllCall("SetThreadExecutionState", "UInt" , ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED) : DllCall("SetThreadExecutionState", "UInt", ES_CONTINUOUS)
  tray_update() ; ikona v tray a její tooltip
}
set_window(x, y, w, h, hwnd) { ; nastavení pozice a velikosti okna
  static uFlags := 0x0004 | 0x0010 ; SWP_NOZORDER | SWP_NOACTIVATE
  static isDLL := true
  try {
    if isDLL {
      hwnd ? (rc := DllCall("SetWindowPos", "ptr", hwnd , "ptr", 0, "int", x, "int", y, "int", w, "int", h, "uint", uFlags, "int")) : (_:=1)
      return rc != 0
    } else
      WinMove(x, y, w, h, hwnd)
  } catch Error as e {
    log_error(A_ThisFunc,e)
    return false
  }
  return true
}
set_windowsize(hwnd, widthPercent, heightPercent) { ; nastavení velikosti okna v procentech pracovní plochy
  static WS_SIZEBOX := 0x00040000
  try {
    if (!IsNumber(widthPercent) || !IsNumber(heightPercent) || widthPercent < 20 || widthPercent > 90 || heightPercent < 20 || heightPercent > 90)
      return false
    if (WinGetMinMax(hwnd) == -1 || !(WinGetStyle(hwnd) & WS_SIZEBOX))
      return false
    if (WinGetMinMax(hwnd) == 1)
      WinRestore(hwnd)
    WinGetPos(&x, &y, &currentWidth, &currentHeight, hwnd)
    monitorIndex := 1, maxOverlap := -1
    Loop MonitorGetCount() {
      MonitorGet(A_Index, &monitorLeft, &monitorTop, &monitorRight, &monitorBottom)
      overlapWidth := Max(0, Min(x + currentWidth, monitorRight) - Max(x, monitorLeft))
      overlapHeight := Max(0, Min(y + currentHeight, monitorBottom) - Max(y, monitorTop))
      overlap := overlapWidth * overlapHeight
      if (overlap > maxOverlap)
        monitorIndex := A_Index, maxOverlap := overlap
    }
    MonitorGetWorkArea(monitorIndex, &Left, &Top, &Right, &Bottom)
    width := Floor((Right - Left) * widthPercent / 100)
    height := Floor((Bottom - Top) * heightPercent / 100)
    if (currentWidth == width && currentHeight == height)
      return true
    return set_window(x, y, width, height, hwnd)
  } catch Error as e {
    log_error(A_ThisFunc,e)
    return false
  }
}
ogame_resize() {
  for hwnd in WinGetList(Const.S_OGAME)
    set_windowsize(hwnd, Const.N_OGAME_WIDTH, Const.N_OGAME_HEIGHT)
}
; ladicí dump bude vždy na konci tohoto skriptu
log_dump() { ; ladění
  log_add("Start",true)
  aWindows := WinGetList(Const.S_OGAME)
  log_add("aWindows.Count " aWindows.Length, true)
  log_add("End",true)
}
ogame_cycle(forward:=true) {
  static index := 0
  static aList := []
  static lastHandle := 0
  check := WinGetList(Const.S_OGAME)
  if (check.Length != aList.Length) {
    aList := check
    index := 0
  }
  if (aList.Length) {
    if (index < 1 || index > aList.Length)
      index := forward ? 1 : aList.Length
    else if (forward)
      index := (index >= aList.Length) ? 1 : index + 1
    else
      index := (index <= 1) ? aList.Length : index - 1
    hwnd := aList[index]
    try {
      if WinExist("ahk_id " hwnd) {
        if (lastHandle && lastHandle != hwnd && WinExist("ahk_id " lastHandle))
          WinMinimize(lastHandle)
        if (WinGetMinMax(hwnd) == -1)
          WinRestore(hwnd)
        lastHandle := hwnd
      }
    } catch Error as e {
      log_error(A_ThisFunc,e)
    }
  }
}