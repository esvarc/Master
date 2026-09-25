timer_init() { ; inicializace časovače
  static WM_DISPLAYCHANGE := 0x007E
  SetTimer(timer_runner, Const.N_TIME_250MS)
  OnMessage(WM_DISPLAYCHANGE, DisplayChangeHandler)
}
DisplayChangeHandler(wParam, lParam, msg, hwnd) { ; callback reakce na změnu rozložení monitorů
  global g_oWatch
  g_oWatch.setProfile()
}
timer_runner() { ; hlavní timer, který spouští jednotlivé časovače
  static sStop := Const.S_LOG_BASE_DIR '\stop.me'
  SetTitleMatchMode("RegEx")
  SendMode("Input")
  DetectHiddenWindows(true)
  timer_restore(Const.N_TIME_500MS)
  timer_debug(Const.N_TIME_SECOND)
  timer_mozilla(Const.N_TIME_SECOND)
  timer_agent(5 * Const.N_TIME_SECOND)
  timer_client(5 * Const.N_TIME_SECOND)
  if FileExist(sStop) {
    try {
      FileDelete(sStop)
    } catch Error as e {
      return ; nic se neděje zkusím to znovu příště
    }
    reload_quit() ; a končím tohle je způsob jak ukončit elevated master z neprivilegovaného procesu
  }
}
timer_client(nWait) { ; kontroluje zda je aktivní okno z konfiguračního souboru a pokud ano tak ho maximalizuje na celou pracovní plochu bez rámečků
  global g_oScreen
  static tSleep := 0
  if (A_TickCount > tSleep) {
    tSleep := A_TickCount + nWait
    try {
      g_oScreen.go() ; maximize windows
    } catch Error as e {
      log_error(A_ThisFunc,e)
    }
  }
}
timer_debug(nWait) { ; zapisuje debug log
  static tSleep := 0
  if (A_TickCount > tSleep) {
    tSleep := A_TickCount + nWait
    log_flush()
  }
}
timer_restore(nWait) { ; hlídač pozice oken
  global g_oWatch
  static tSleep := 0
  if (A_TickCount > tSleep) {
    tSleep := A_TickCount + nWait
    g_oWatch.go()
  }
}
timer_agent(nWait) { ; kill Ganji agent, který je součástí Enlisted, Nenechám se špiónovat.
  static tSleep := 0
  if (A_TickCount > tSleep) {
    tSleep := A_TickCount + nWait
    handle := WinExist(Const.S_GJ_AGENT)
    (handle ? WinClose(handle) : (_:=1))
  }
}
timer_mozilla(nWait) { ; kontroluje dialog Mozilla Thunderbird pro zadání hesla
  static tSleep := 0
  if (A_TickCount > tSleep) {
    tSleep := A_TickCount + nWait
    handle := WinExist(Const.S_MOZILLA_DIALOG)
    (handle && !WinActive(handle) ? WinActivateBottom(handle) : (_:=1))
  }
}
timer_hold(timer, sKeyEnd) { ; testuje zda nebyla stisknuta libovolná klávesa, pak se zastaví tento timer a zruší držení kláves(y)
  ih := InputHook("VT0.5")
  ih.KeyOpt((sKeyEnd != "" ? sKeyEnd : "{All}"), "E") ; Klávesy, které ukončí čekání. Pokud není zadáno, tak všechny klávesy.
  ih.Start(), (ih.Wait() != "Timeout") ? (SetTimer(timer,0), hold_keys(false)) : (_:=1) ; a teď čekat na stisknutí klávesy, pokud byla stisknuta, tak se zastaví timer a zruší držení kláves(y)
}