# 🧩 Developer Notes – Lib_Log

**Library:** `Lib_Log.ps1`
**Status:** Stable
**Maintainer:** Herbert Schrotter
**Last update:** 23.10.2025

---

## 1) Zweck & Überblick

`Lib_Log.ps1` ist das **zentrale Logging-System** des Site Manager Frameworks. Es bietet:

* **Multi-Session-Logging**: mehrere Module (z. B. `MenuSystem`, `DevLogSystem`, `SystemScanner`) können **gleichzeitig** in **eigene** Logdateien schreiben.
* **Logrotation pro Modul**: Begrenzung nach Anzahl und/oder Alter.
* **Konfigurierbares Format** inkl. Sekunden im Dateinamen.
* **Konsole-Output** (abschaltbar) und **Debug-Level**.
* **Auto-Erstellung der Konfigurationsdatei** (falls nicht vorhanden).

⚠️ **Wichtig:** Seit **LIB_V1.1.x** werden **keine globalen Einzel-Session-Variablen** mehr genutzt. Stattdessen verwaltet `Lib_Log` **mehrere parallele Sitzungen** in einer Registry (`$ActiveLogSessions`).

---

## 2) Dateien & Abhängigkeiten

* **Pfad (empfohlen):** `03_Scripts/Modules/Libs/Lib_Log.ps1`
* **Config:** `01_Config/Log_Config.json` (auto-generiert bei Erststart)
* **Log-Zielordner:** `04_Logs/`
* **Dependencies:**

  * `Lib_PathManager.ps1` (optional, für `Get-PathConfig` / `Get-PathLogs`)

---

## 3) ManifestHint

```text
ManifestHint:
  ExportFunctions: Load-LogConfig, Initialize-LogSession, Write-FrameworkLog, Write-DebugLog, Rotate-Logs, Close-LogSession, Lock-LogSystem, Unlock-LogSystem
  Description: Framework-Logging mit exklusivem Modulzugriff (Lock-System) und Logrotation
  Category: Core
  Tags: Logging, Framework, Rotation, Config, Lock, SiteManager
  Dependencies: Lib_PathManager

```

---

## 4) Konfiguration (`Log_Config.json`)

**Wird bei Bedarf automatisch angelegt.** Beispielstruktur:

```json
{
  "Version": "CFG_V1.1.1",
  "MaxLogsPerModule": 10,
  "MaxAgeDays": 14,
  "RotationMode": "Both",        // "Count" | "Age" | "Both"
  "EnableDebug": true,
  "EnableConsoleOutput": true,
  "DateFormat": "yyyy-MM-dd_HHmm_ss",
  "LogLevels": ["INFO", "WARN", "ERROR", "DEBUG"],
  "LogStructure": "[{Timestamp}] [{Level}] [{Module}] {Message}",
  "IncludeSessionHeader": true,
  "SessionHeaderTemplate": "Neue Log-Session für {Module} gestartet um {Timestamp}"
}
```

**Hinweise:**

* `DateFormat` enthält **Sekunden** (Konflikte bei mehrfachen Sessions pro Minute werden vermieden).
* `RotationMode` steuert die Löschlogik bei `Rotate-Logs`.
* `LogStructure` kann frei angepasst werden; Platzhalter werden beim Schreiben ersetzt.

---

## 5) Öffentliche Funktionen (API)

### 5.1 `Load-LogConfig`

* **Zweck:** Config laden oder erstellen.
* **Besonderheit:** JSON wird **automatisch in `[hashtable]`** konvertiert (verhindert Typfehler bei Parametern, z. B. in `Rotate-Logs`).
* **Globaleffekte:** Setzt `$global:LogConfig`.

### 5.2 `Initialize-LogSession -ModuleName <String>`

* **Zweck:** Startet **eine neue Log-Session für ein Modul**.
* **Ablauf:**

  1. `Rotate-Logs` für das Modul ausführen.
  2. Logdatei mit Zeitstempel anlegen (`<Module>_Log_<Datum>.txt`).
  3. Session in `$global:ActiveLogSessions[ModuleName]` registrieren.
  4. Optionalen Session-Header schreiben.

### 5.3 `Write-FrameworkLog -Message <String> -Module <String> -Level <INFO|WARN|ERROR|DEBUG>`

* **Zweck:** Schreibt einen Eintrag **in die Logdatei des angegebenen Moduls** (sofern Session aktiv).
* **Fallback:** Wenn keine Session für `<Module>` existiert, wird in `04_Logs/Fallback_Log.txt` geschrieben.
* **Konsole:** Ausgabe entsprechend `EnableConsoleOutput` und `EnableDebug`.

### 5.4 `Write-DebugLog -Message <String> -Module <String>`

* Kurzform für `Write-FrameworkLog` mit `Level = DEBUG` (nur aktiv, wenn `EnableDebug = true`).

### 5.5 `Rotate-Logs -ModuleName <String> -LogConfig <Hashtable>`

* **Zweck:** Löscht alte Logdateien **modulweise** gemäß Konfiguration (Alter/Anzahl/Both).
* **Wichtig:** Erwartet **Hashtable** – wird durch `Load-LogConfig` sichergestellt.

### 5.6 `Close-LogSession -ModuleName <String>`

* **Zweck:** Beendet die **Session eines Moduls**, schreibt Dauer (`[CLOSE]`) und entfernt die Session aus `ActiveLogSessions`.

### 5.7 `Lock-LogSystem -ModuleName <String>`
- **Zweck:** Reserviert das Logsystem exklusiv für ein Modul (z. B. `MenuSystem`).
- **Rückgabe:** `$true`, wenn erfolgreich; `$false`, wenn bereits ein anderes Modul schreibt.
- **Konsolenausgabe:**
  - `🔒 LogSystem exklusiv gesperrt durch: <Module>`
  - `⚠️ Logging aktuell gesperrt durch Modul: <Name>`

### 5.8 `Unlock-LogSystem -ModuleName <String>`
- **Zweck:** Gibt das Logsystem wieder frei.
- **Wird automatisch** von `Close-LogSession` aufgerufen.
- Kann manuell genutzt werden, wenn ein Modul unerwartet beendet wird.

---

## 6) Multi-Session & Lock-Design (ab LIB_V1.2.x)

🆕 Ab Version LIB_V1.2.x verfügt Lib_Log zusätzlich über ein **Lock-System**, das exklusiven Schreibzugriff erzwingt.

- Nur **ein Modul** darf aktiv loggen.
- Wenn ein anderes Modul (`MenuSystem`, `DevLogSystem` etc.) eine Log-Session startet, während das System gesperrt ist, wird es abgewiesen.
- Die Sperre wird automatisch durch `Close-LogSession` aufgehoben.
- Dadurch sind keine Fallback- oder Überschneidungslogs mehr möglich.


**Problem (früher):** Eine globale Datei/Session führte bei gleichzeitiger Nutzung (z. B. Menü + Tool) zu Überschreibungen/Konflikten.

**Lösung (jetzt):**

* `$global:ActiveLogSessions` als **Registry** für alle aktiven Modul-Sessions.
* Jeder Aufruf von `Initialize-LogSession -ModuleName X` erstellt **eine eigene Datei** und registriert sie unter `ActiveLogSessions[X]`.
* `Write-FrameworkLog -Module X` route’t automatisch in die **richtige Datei**.
* `Close-LogSession -Module X` beendet **nur** diese Sitzung.

**Konsequenzen:**

* `Lib_Menu.ps1` kann mit `ModuleName = "MenuSystem"` loggen, während `Dev-LogSystem` parallel schreibt – **ohne Konflikte**.
* Rotation und Retention gelten **pro Modul**.

**Ablauf mit Lock-System:**

1. `MenuSystem` startet → `Lock-LogSystem` aktiviert.
2. `DevLogSystem` versucht zu starten → wird blockiert.
3. Nach `Close-LogSession` wird Lock automatisch freigegeben.

---

## 7) Beispiele & Best Practices

### 7.1 Minimalablauf in einem Modul

```powershell
Load-LogConfig
Initialize-LogSession -ModuleName "MyModule"

Write-FrameworkLog -Module "MyModule" -Level INFO  -Message "Start"
Write-FrameworkLog -Module "MyModule" -Level WARN  -Message "Warnhinweis"
Write-FrameworkLog -Module "MyModule" -Level ERROR -Message "Fehler aufgetreten"
Write-DebugLog     -Module "MyModule" -Message "Debug-Details"

Close-LogSession -ModuleName "MyModule"
```

### 7.2 Integration in `Lib_Menu.ps1`

* Beim Laden:

```powershell
. "$PSScriptRoot\..\Libs\Lib_Log.ps1"
Load-LogConfig
Initialize-LogSession -ModuleName "MenuSystem"
Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message "Menüsystem gestartet."
```

* Beim Beenden (Taste `X`):

```powershell
Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message "Programm beendet."
Close-LogSession -ModuleName "MenuSystem"
```

### 7.3 Dev-Tool parallel zum Menü

```powershell
# Menü läuft mit ModuleName "MenuSystem"
Initialize-LogSession -ModuleName "DevLogSystem"
Write-FrameworkLog -Module "DevLogSystem" -Message "Tool gestartet."
# … Einträge …
Close-LogSession -ModuleName "DevLogSystem"
```

**Ergebnis (Beispiel):**

### 7.4 Exklusiver Zugriff (Lock-System, ab LIB_V1.2.0)

```powershell
Load-LogConfig

# Menü startet zuerst
Initialize-LogSession -ModuleName "MenuSystem"
Write-FrameworkLog -Module "MenuSystem" -Message "Menü aktiv"

# Dev-Tool versucht zu starten (parallel)
Initialize-LogSession -ModuleName "DevLogSystem"
# → Ausgabe:
# ⚠️ Logging aktuell gesperrt durch Modul: MenuSystem
# ❌ LogSession für DevLogSystem nicht gestartet – System belegt.

# Menü beendet
Close-LogSession -ModuleName "MenuSystem"
# → 🔓 LogSystem-Freigabe durch: MenuSystem

```
04_Logs/
├── MenuSystem_Log_2025-10-23_1530_12.txt
└── DevLogSystem_Log_2025-10-23_1530_14.txt
```

---

## 8) Migration & Kompatibilität

* **Vorher**: Globale Variablen `$CurrentLogFile` / `$CurrentLogSessionStart` (Single-Session).
* **Jetzt**: Mehrere Sessions unter `$ActiveLogSessions[<Module>]`.
* **Anpassungen:**

  * Stelle sicher, dass **jedes Modul** `Initialize-LogSession -ModuleName "<Name>"` aufruft.
  * Alle Log-Schreibvorgänge **immer** mit `-Module "<Name>"` durchführen.
  * Beim Exit: `Close-LogSession -ModuleName "<Name>"` nicht vergessen.
* **Typfehler-Fix**: `Load-LogConfig` wandelt JSON-Objekt → Hashtable. Keine Änderungen in Aufrufen nötig.

---

## 9) Tests & Checkliste

* [ ] Config wird erzeugt, wenn nicht vorhanden.
* [ ] `DateFormat` enthält Sekunden (`yyyy-MM-dd_HHmm_ss`).
* [ ] `Initialize-LogSession` erzeugt Datei und schreibt Header.
* [ ] Gleichzeitiges Logging aus **zwei Modulen** erzeugt **zwei Dateien**.
* [ ] `Rotate-Logs` löscht erwartungsgemäß bei `RotationMode = Both`.
* [ ] `Close-LogSession` schreibt `[CLOSE]` und entfernt Eintrag aus `ActiveLogSessions`.
* [ ] Konsolenausgabe abschaltbar (`EnableConsoleOutput = false`).
* [ ] Debug-Ausgaben nur bei `EnableDebug = true`.
- [ ] Nur ein Modul darf gleichzeitig loggen (Lock-System aktiv).
- [ ] `Close-LogSession` gibt den Lock automatisch wieder frei.

---

## 10) Bekannte Stolpersteine

* **Kein `Initialize-LogSession` aufgerufen:** Einträge landen im `Fallback_Log.txt`.
* **Falscher Modulname beim Schreiben:** Einträge erscheinen (scheinbar) nicht → Modulname prüfen.
* **Ältere Config ohne Sekunden:** Es kann zu kollidierenden Dateinamen kommen, wenn Sessions innerhalb derselben Minute gestartet werden → `DateFormat` aktualisieren.
- **Lock nicht freigegeben:** Wenn ein Modul abstürzt, bleibt das System gesperrt → manuell mit `Unlock-LogSystem -ModuleName "<Name>"` aufheben.
- **Mehrere gleichzeitige Initialisierungen:** Nur das erste Modul erhält Zugriff; alle anderen werden geblockt.


---

## 11) Changelog

### LIB_V1.2.0 – 23.10.2025
* **Neu:** Exklusives **Lock-System** für das Logging.
* **Ziel:** Nur ein Modul darf gleichzeitig schreiben (Single Active Log).
* **Neue Funktionen:** `Lock-LogSystem`, `Unlock-LogSystem`.
* **Initialize-LogSession:** Prüft Lock-Status und blockiert, wenn belegt.
* **Close-LogSession:** Gibt Lock automatisch frei.
* **Vorteil:** Keine Fallbacks oder Überschneidungen mehr.


### LIB_V1.1.1 – 23.10.2025

* **Neu:** Automatische **Hashtable-Konvertierung** in `Load-LogConfig` (verhindert Typfehler in `Rotate-Logs`).
* **Stabilisierung:** Konsolidierter Multi-Session-Betrieb.

### LIB_V1.1.0 – 23.10.2025

* **Neu:** **Multi-Session-Logging** via `$ActiveLogSessions`.
* **Refactor:** `Initialize-LogSession`, `Write-FrameworkLog`, `Close-LogSession` für parallele Sessions überarbeitet.

### LIB_V1.0.0 – 22.10.2025

* Initiale Version mit Single-Session, Rotation, Debug- und Console-Output.

---

## 12) Commit-Vorlage

```
🧠 DOC – Developer Notes: Lib_Log aktualisiert (V1.3.2)
• Lock-System dokumentiert (Single Active Log Mode)
• Neue Funktionen: Lock-LogSystem, Unlock-LogSystem
• Multi-Session-Abschnitt zu „Multi-Session & Lock-Design“ erweitert
• Beispiele und Checkliste ergänzt
• Changelog auf LIB_V1.2.0 aktualisiert

```

---

## 13) ToDo / Ideen

* Optionale **asynchrone** Log-Pufferung (Batch-Flush) für sehr große Output-Mengen.
* Konfigurierbare **Archivierung** (z. B. ZIP älterer Logs vor Löschung).
* **JSON-Log-Ausgabe** (zusätzlich zu Text) für maschinelle Auswertung.
* **EventLog-Bridge** (Windows Event Log) als optionaler Sink.
* Einheitliche **Viewer-Tools** (Tail/Filter) im Menü „Tools“.
