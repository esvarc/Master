## Popis
- Přehrávání médií pro klávesnice co nemají funkční tlačítka play, stop, next, previous  
- Držení kombinace kláves pro hry  
- Automatická maximalizace oken zadaných v konfiguračním souboru `%LOCALAPPDATA%\maximized-windows.cfg` na celou pracovní plochu bez rámečků  
- Ukončení Ganji agenta který je součástí Enlisted, Nenechám se špiónovat  
- Hlídání pozice a velikosti oken zadaných v konfiguračním souboru `%LOCALAPPDATA%\saved-windows.cfg`  
- Blokování spořiče obrazovky a přechodu do režimu spánku pokud je aktivní parametr `afk` v příkazové řádce nebo použita hot‑key není potřeba již reload  

**Autor:** Eduard Švarc  
**Datum:** 2. 9. 2026  
**Verze:** 2.1.9  

---

## Revize

### 2.1.9 (2026‑09‑02)
- Opraveno chybné cachování rozměrů desktopu AHK. SYSGET vrací souřadnice levého horního rohu a šířku s výškou desktopu, stejně musím přepočítat DLL které je v absolutních souřadnicích.

### 2.1.8 (2026‑08‑31)
- Oprava faktu že AHK rozměry desktopu cachuje, takže při změně monitorů SysGet nereflektuje aktuální stav  
- Musel jsem použít DLL pro enumeraci

### 2.1.7 (2026‑08‑11)
- Bump verze kvůli pokusu o zabránění AFK stavu pro Teams, ale pokus se nezdařil

### 2.1.6 (2026‑08‑11)
- Řešení jak ukončit master když je spuštěn jako elevated, potřebné pro aktualizace EXE verze

### 2.1.5 (2026‑08‑10)
- Zavedl jsem třídu s konstantami, nemusím je pak deklarovat jako global  
- Změna logování, teď již log obsahuje severitu DBG, INF, ERR

### 2.1.4 (2026‑08‑10)
- Bump verze kvůli build exe

### 2.1.3 (2026‑08‑07)
- Ukládání a obnova pozic oken funguje výborně  
- Ukládání oken rozšířeno o funkci profilů, tj. pro každé rozložení monitorů a jejich rozlišení se vytvoří samostatný profil. Profil je součástí tagu okna  
- Změna rozložení monitorů je propagována posloucháním WM_DISPLAYCHANGE, to změní profil automaticky  
- Blokování spořiče není moc spolehlivé, vypadá to že posílání F15 moc nezabírá  
- Testuji teď volání WinAPI SetThreadExecutionState, vypadá to že tahle možnost je ta pravá

### 2.1.2 (2026‑08‑06)
- Pokus o ukládání a obnovu pozic oken  
- Přidáno více kontrol na chyby při čtení konfigurace a manipulaci s okny  
- Blokace screensaveru pomocí skrytého okna a posílání F15 každých 50 sekund do něj

### 2.1.1 (2026‑08‑02)
- Držení kombinace kláves než dojde ke stisknutí libovolné klávesy  
- Změna major verze. Zahození předchozích nefunkčních částí
---
