class winMax { ; načtení seznamu oken z %LOCALAPPDATA%\maximized-windows.cfg, které se mají roztáhnout na pracovní plochu bez rámečků
  static WS_CAPTION  := 0x00C00000, WS_SIZEBOX  := 0x00040000, WindowStyle := winMax.WS_CAPTION | winMax.WS_SIZEBOX
  lookup := Array()
  congfigFile := ""
  __new() {
    global g_isDebug
    this.configFile := EnvGet('LOCALAPPDATA') '\maximized-windows.cfg'
    if FileExist(this.configFile) {
      try {
        oFile := FileOpen(this.configFile,'r',Const.S_FILE_ENCODING)
        if oFile {
          g_isDebug ? log_add(A_ThisFunc " Reading saved windows") : (_:=1)
          while (!oFile.AtEOF) {
            line := Trim(oFile.ReadLine()," `t")
            if (!StrLen(line) || RegExMatch(line,'^;|#'))
              continue
            g_isDebug ? log_add(A_ThisFunc " Add: '" line "'") : (_:=1)
            this.lookup.Push(line)
          }
          oFile.Close()
        }
      } catch Error as e {
        log_error(A_ThisFunc,e)
      }
    }
  }
  __delete() {
    this.lookup := ""
  }
  go() {
    global g_isDebug
    for (app in this.lookup) {
      handle := WinActive(app)
      if handle {
        try {
          style := WinGetStyle(handle)
          if (style & winMax.WindowStyle) {
            WinSetStyle(-winMax.WindowStyle, handle), Sleep(250)
            g_isDebug ? log_add(A_ThisFunc Format(' {:#8X} {:#8X}', handle, style)) : (_:=1)
          } 
          MonitorGetWorkArea(, &Left, &Top, &Right, &Bottom)
          width := Right - Left, height := Bottom - Top
          WinGetPos(&x, &y, &w, &h,handle)
          if (x != Left || y != Top || w != width || h != height) {
            (WinGetMinMax(handle) == 1) ? (WinRestore(handle), (g_isDebug ? log_add(A_ThisFunc Format(' Restore window: {:#8X}', handle)) : (_:=1))) : (_:=1) ; pokud je okno maximalizované tak s ním nelze manipulovat, proto musí být nejdříve obnoveno do normální velikosti
            WinMove(Left, Top, Right - Left, Bottom - Top, handle)
            g_isDebug ? log_add(A_ThisFunc Format(' Move window: x={1} y={2} w={3} h={4} screen: l={5} t={6} w={7} h={8}', x, y, w, h, Left, Top, width, height)) : (_:=1)
          }
        } catch Error as e {
          log_error(A_ThisFunc,e)
        }
      }
    }
  }
}

class winWatch { ; načtení seznamu oken z %LOCALAPPDATA%\saved-windows.cfg, které se mají hlídat a pokud se změní jejich stav tak se uloží do souboru
  static SM_XVIRTUALSCREEN := 76, SM_YVIRTUALSCREEN := 77, SM_CXVIRTUALSCREEN := 78, SM_CYVIRTUALSCREEN := 79 ; zjištění rozměrů virtuální obrazovky, pokud je více monitorů
  static WS_VISIBLE := 0x10000000 ; test viditelnosti okna
  static TOOLTIP_TIMEOUT := 2000 ; jak dlouho se zobrazí tooltip po přidání nebo odebrání okna ze seznamu hlídaných oken
  aWatch := Map(), index := 0 ; pole hlídaných oken, index pro přidávání do pole
  congfigFile := "" ; kde jsou uloženy definice oken u kterých se má hlídat pozice a velikost
  profile := "" ; profil podle rozložení monitorů
  __new() {
    global g_isDebug
    this.configFile := EnvGet('LOCALAPPDATA') '\saved-windows.cfg'
    if FileExist(this.configFile) {
      try {
        g_isDebug ? log_add(A_ThisFunc " Reading saved windows") : (_:=1)
        oFile := FileOpen(this.configFile,'r',Const.S_FILE_ENCODING)
        while (!oFile.AtEOF) {
          line := Trim(oFile.ReadLine()," `t")
          if (!StrLen(line) || RegExMatch(line,'^;|#'))
            continue
          parts := StrSplit(line, "|"," `t")
          if (parts.Length == 6) {
            this.aWatch[this.index++] := Map("tag",parts[1],"x",parts[2],"y",parts[3],"w",parts[4],"h",parts[5],"max",(parts[6] == "1"))
            g_isDebug ? log_add(A_ThisFunc Format(" tag '{1}' x={2} y={3} w={4} h={5} {}", parts[1], parts[2], parts[3], parts[4], parts[5], (parts[6]==1 ? "maximized" : "normal"))) : (_:=1)
          }
        }
        oFile.Close()
      } catch Error as e {
        log_error(A_ThisFunc,e)
      }
    }
    this.setProfile() ; nastavení profilu podle rozložení monitorů
  }
  __delete() {
    this.aWatch := ""
  }
  _tag(hWindow) { ; vrátí tag okna podle handle. tag je složen z názvu procesu a názvu okna, odděleného pomlčkou.
    try {
      return StrReplace(Format("{}-{}-{}", this.profile, WinGetProcessName(hWindow), Trim(WinGetTitle(hWindow)," `t")),"|","+")
    } catch Error as e {
      g_isDebug ? log_add(A_ThisFunc Format(" {}", WinGetTitle(hWindow)), true) : (_:=1) ; zajímá mě která okna nedokáží vrátit process name
    }
    return "Unknown"
  }
  _save() { ; uložení seznamu hlídaných oken do souboru
    global g_isDebug
    try {
      g_isDebug ? log_add(A_ThisFunc " Saving watched windows") : (_:=1)
      oFile := FileOpen(this.configFile,'w',Const.S_FILE_ENCODING)
      if oFile {
        for , window in this.aWatch {
          oFile.WriteLine(window.Get("tag") "|" window.Get("x") "|" window.Get("y") "|" window.Get("w") "|" window.Get("h") "|" (window.Get("max") ? "1" : "0"))
          g_isDebug ? log_add(A_ThisFunc Format(" tag '{1}' x={2} y={3} w={4} h={5} {}", window.Get("tag"), window.Get("x"), window.Get("y"), window.Get("w"), window.Get("h"), (window.Get("max")  ? "maximized" : "normal"))) : (_:=1)
        }
        oFile.Close()
      }
    } catch Error as e {
      log_error(A_ThisFunc,e)
    }
  }
  _get(tag) { ; vrátí okno z hlídaných oken podle tagu
    for , window in this.aWatch {
      if (StrCompare(window.get("tag"), tag) == 0)
        return window
    }
    return false
  }
  _isMoving(hWindow) { ; vrátí true pokud je okno přesouváno nebo měněna jeho velikost
    WinGetPos(&x1, &y1, &w1, &h1, hWindow)
    Sleep(30)
    WinGetPos(&x2, &y2, &w2, &h2, hWindow)
    return (x1 != x2 || y1 != y2 || w1 != w2 || h1 != h2)
  }
  go() {
    global g_isDebug
    targets := WinGetList() ; všechny okna
    try {
      for hwnd in targets {
        if (WinGetStyle(hwnd) & winWatch.WS_VISIBLE) { ; je okno zobrazené
          minmax := WinGetMinMax(hwnd)
          if (minmax == -1) ; minimalizované okno, nelze zasahovat
            continue

          window := this._get(this._tag(hwnd))
          if (!window) ; není v seznamu hlídaných oken, není potřeba zasahovat
            continue
          
          if (window.Has("fail") && (window.get("fail") > 2)) ; příliš mnoho neúspěšných pokusů tohle okno přesunout
            continue

          xs := window.Get("x"), ys := window.Get("y"), ws := window.Get("w"), hs := window.Get("h")
          WinGetPos(&x, &y, &w, &h, hwnd)
          if !(xs != x || ys != y || ws != w || hs != h || window.get("max") != minmax) ; je tak jak má být, není potřeba zasahovat
            continue
          
          if (this._isMoving(hwnd)) { ; okno se přesouvá nebo mění velikost, tak nelze zasahovat
            g_isDebug ? log_add(A_ThisFunc Format(" Window is moving, skip: tag:{1} x={2} y={3} w={4} h={5} {}", window.get("tag"), xs, ys, ws, hs, (window.get("max") ? "maximized" : "normal"))) : (_:=1)
            continue
          }

          g_isDebug ? log_add(A_ThisFunc Format(" Move tag:{1}", window.get("tag"))) : (_:=1)
          if (window.get("max")) {
            rc := set_window(window.get("x"), window.get("y"), window.get("w"), window.get("h"), hwnd) ; než se okno maximalizuje musí být na správné pozici
            rc ? WinMaximize(hwnd) : (_:=1)
          } else {
            WinRestore(hwnd) ; před přesunem musím zrušit maximalizaci, jinak se okno nepřesune a nezmění velikost
            rc := set_window(window.get("x"), window.get("y"), window.get("w"), window.get("h"), hwnd)
          }
          if (!rc) { ; nepodařený pokus o přesun okna 
            !window.Has("fail") ? window.Set("fail",0) : (_:=1)
            window.Set("fail",window.get("fail")+1)
            log_add(A_ThisFunc Format(" Failed count {} to move '{}'", window.get("fail"), window.get("tag")), true)
          }
        }
      }
    } catch Error as e {
      log_error(A_ThisFunc,e) 
    }
  }
  toggleWindow() { ; přidání nebo odstranění okna ze seznamu hlídaných oken
    global g_isDebug
    try {
      MouseGetPos(,,&hWindow)
      g_isDebug ? log_add(A_ThisFunc Format(" Window: {:#8X}", hWindow)) : (_:=1)
      tag := this._tag(hWindow)
      WinGetPos(&x, &y, &w, &h,hWindow)
      minmax := WinGetMinMax(hWindow), found := false
      for i, window in this.aWatch {
        if (StrCompare(window.get("tag"), tag) == 0) { ; odstraň
          this.aWatch.Delete(i)
          ToolTip(Format("Window removed`n{1}", tag))
          SetTimer(() => ToolTip(), -winWatch.TOOLTIP_TIMEOUT)
          g_isDebug ? log_add(A_ThisFunc Format(" Remove: '{1}'", tag)) : (_:=1)
          found := true
          break
        }
      }
      if (!found) { ; nové okno, přidej
        this.aWatch[this.index++] := Map("tag",tag,"x",x,"y",y,"w",w,"h",h,"max",(minmax == 1))
        ToolTip(Format("Window added`n{1}", tag))
        SetTimer(() => ToolTip(), -winWatch.TOOLTIP_TIMEOUT)
        g_isDebug ? log_add(A_ThisFunc Format(" Add: '{1}' x={2} y={3} w={4} h={5} {}", tag, x, y, w, h, (minmax==1 ? "maximized" : "normal"))) : (_:=1)
      }
      this._save() ; uložení aktualizovaného seznamu hlídaných oken do souboru
    } catch Error as e {
      log_error(A_ThisFunc,e)
    }
  }
  setProfile() { ; nastavení profilu podle rozložení monitorů
    global g_isDebug
    Left := 999999, Top := 999999, Right := -999999, Bottom := -999999
    MonitorEnumProc(hMonitor, hdcMonitor, lprcMonitor, dwData) {
      mLeft   := NumGet(lprcMonitor, 0, "Int")
      mTop    := NumGet(lprcMonitor, 4, "Int")
      mRight  := NumGet(lprcMonitor, 8, "Int")
      mBottom := NumGet(lprcMonitor, 12, "Int")
      Left := Min(Left, mLeft)
      Top := Min(Top, mTop)
      Right := Max(Right, mRight)
      Bottom := Max(Bottom, mBottom)
      return true ; Continue enumeration
    }
    callback := CallbackCreate(MonitorEnumProc, "F", 4)
    DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", callback, "Ptr", 0) ; Enumerate all active physical display monitors across the desktop session
    CallbackFree(callback) ; Free the allocated callback memory

    this.profile := Format("{1}{2}{3}{4}", Left, Top, Right - Left, Bottom - Top)
    ; this.profile := Format("{1}{2}{3}{4}", SysGet(winWatch.SM_XVIRTUALSCREEN), SysGet(winWatch.SM_YVIRTUALSCREEN), SysGet(winWatch.SM_CXVIRTUALSCREEN), SysGet(winWatch.SM_CYVIRTUALSCREEN))
    ; g_isDebug ? log_add(A_ThisFunc Format(" Profile set to '{1}'", this.profile)) : (_:=1)
    log_add(A_ThisFunc Format(" Profile set to '{1}'", this.profile), true)
  }
}