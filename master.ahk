; globalní konstanty
class Const {
  ; stringy
  static S_DEBUG_PREFIX := "MA: "
  static S_FILE_ENCODING := "UTF-16"
  static S_LOG_BASE_DIR := EnvGet("TEMP")
  static S_LOG_STAMP := "yyyyMMdd HH:mm:ss"
  static S_VERSION := "2.2.2", S_PROGRAM_NAME := "Master"
;@Ahk2Exe-Let verze=%A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-Let name=%A_PriorLine~U)^(.+"){3}(.+)".*$~$2%
  static S_COMPANY := "Trantor", S_COPYRIGHT := "GPL 2026"
;@Ahk2Exe-Let company=%A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-Let copyright=%A_PriorLine~U)^(.+"){3}(.+)".*$~$2%
  static S_PROGRAM_TITLE := Const.S_PROGRAM_NAME " " Const.S_VERSION ; tooltip k ikoně v tray
  ; časové konstanty
  static N_TIME_SECOND := 1000
  static N_TIME_MINUTE := Const.N_TIME_SECOND * 60
  static N_TIME_050MS :=  50
  static N_TIME_100MS := 100
  static N_TIME_150MS := 150
  static N_TIME_200MS := 200
  static N_TIME_250MS := 250
  static N_TIME_500MS := 500
  ;
  static S_GJ_AGENT := "ahk_exe i)gjagent.exe"
  static S_MOZILLA_DIALOG := "Password Required - Mozilla Thunderbird"
}
; Sekce pro kompilaci
;@Ahk2Exe-Base ..\AutoHotkey64.exe
;@Ahk2Exe-ExeName master.exe
;@Ahk2Exe-SetMainIcon ico\stop.ico
;@Ahk2Exe-AddResource ico\auto.ico, 10
;@Ahk2Exe-AddResource ico\down.ico, 11
;@Ahk2Exe-AddResource ico\expand.ico, 12
;@Ahk2Exe-AddResource ico\globe.ico, 13
;@Ahk2Exe-AddResource ico\info.ico, 14
;@Ahk2Exe-AddResource ico\question.ico, 15
;@Ahk2Exe-AddResource ico\shield.ico, 16
;@Ahk2Exe-AddResource ico\stop.ico, 17
;@Ahk2Exe-SetName %U_name%
;@Ahk2Exe-SetVersion %U_verze%
;@Ahk2Exe-SetCopyright %U_company% %U_copyright% 
;@Ahk2Exe-SetCompanyName %U_company%
;@Ahk2Exe-SetDescription Skript pro udržování pozice a rozměru oken
;@Ahk2Exe-SetLanguage 0x0405
;@Ahk2Exe-Set OriginalFilename, master.ahk
; parametry pro AHK 
#Requires AutoHotkey >=v2
#SingleInstance force ; vynucení jen jedné instance
#Warn All ; upozornění na nedeklarované proměnné a nejasnosti mezi global a local
DetectHiddenWindows(true)
SetWorkingDir(A_ScriptDir)
SetTitleMatchMode("RegEx")
SendMode("Input")
; import knihoven
#include lib\timer.ahk ; jednotlivé časovače
#include lib\utility.ahk ; podpůrné funkce
#include lib\windows.ahk ; manipulace s okny
; inicializace
args_parse() ; parse parametrů v příkazové řádce
log_init() ; logování, musí být až za args_parse protože globální debug se definuje i z příkazové řádky
tray_update() ; ikona v tray a její tooltip
timer_init() ; celé prostředí je připraveno je možné startovat časovač
return
; definice kláves
#HotIf !A_IsCompiled ; nedává smysl pro kompilované skripty
  <#T:: log_dump()
; aplikačně závislé klávesy
#HotIf WinActive("ahk_exe Blossom The Seed Of Life.exe")
  +LButton:: hold_keys(true, "LButton")
#HotIf  WinExist("\w\sOGame")
 <#PgDn:: ogame_cycle(true)
 <#PgUp:: ogame_cycle(false)
; obecné klávesy
#HotIf
  ^+#a::  afk_toggle() ; přepnutí AFK režimu
  <#F10:: g_oWatch.toggleWindow() ; přidání nebo odebrání okna v seznamu hlídaných oken
; ovládání skriptu
  <#F11:: log_toggle() ; přepnutí debug výstupu
  <#F12:: reload_reload() ; restart skriptu u kompilovaného načtení configuračních souborů
  <#End:: reload_quit() ; konec
; klávesy pro ovládání multimédií
  <#F5:: Send("{Volume_Mute}")
  <#F6:: Send("{Media_Prev}")
  <#F7:: Send("{Media_Play_Pause}")
  <#F8:: Send("{Media_Next}")
; konec skriptu, to je vše lidičky