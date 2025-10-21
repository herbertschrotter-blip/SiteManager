## 🧩 Lib_Menu.ps1 – Menüsystem

**Pfad:** `03_Scripts/Libs/Lib_Menu.ps1`
**Version:** LIB_V1.5.1
**Status:** stabil, unabhängig
**Abhängigkeiten:** keine

---

### ⚙️ Zweck

Zentrale Library zur Steuerung der textbasierten Menüführung im Site Manager.
Sie bietet eine universelle Navigation mit Rückkehr- und Exit-Funktion, Stack-Verwaltung
und automatisches Logging über rotierende Logdateien.
Seit Version 1.5.1 ist sie vollständig unabhängig von `Lib_Systeminfo.ps1` und Debug-Funktionen.

---

### 🔧 Hauptfunktionen

| Funktion                           | Beschreibung                                                                 |
| ---------------------------------- | ---------------------------------------------------------------------------- |
| `Show-SubMenu`                     | Erstellt ein Menü mit beliebig vielen Optionen, inklusive Rückkehr und Exit. |
| `Write-MenuLog`                    | Schreibt Aktionen ins aktuelle Menü-Logfile (rotierend, max. N Dateien).     |
| `Push-MenuStack` / `Pop-MenuStack` | Verwalten die hierarchische Menüstruktur.                                    |
| `Get-CurrentMenuPath`              | Gibt den aktuellen Menüpfad als String zurück.                               |

---

### ⚙️ Konfiguration & Logik

* **Parameterdatei:**

  * Wird automatisch unter `01_Config/Menu_Config.json` angelegt, falls sie fehlt.
  * Steuert Anzeige, Farben, Log-Rotation und Pfadanzeige.
  * Beispielparameter:

    ```json
    {
      "ShowPath": false,
      "MaxLogFiles": 10,
      "LogRetentionDays": 30,
      "ColorScheme": {
        "Title": "White",
        "Highlight": "Cyan",
        "Error": "Red"
      }
    }
    ```

* **Logging:**

  * Jede Sitzung erzeugt eine neue Datei `Menu_Log_YYYY-MM-DD_HHMM.txt`.
  * Älteste Logs werden automatisch gelöscht, sobald die Maximalanzahl erreicht ist.
  * Alte Logs können alternativ nach X Tagen entfernt werden.

* **Navigation:**

  * `B` → Zurück zum vorherigen Menü
  * `X` → Programm beenden
  * Optional: Anzeige des Menüpfads (aktivierbar über `ShowPath = true`)

---

### 🧩 Integration in Module

**Einbindung:**
Alle Module, die ein Menüsystem benötigen, sollen `Lib_Menu.ps1` über Dot-Sourcing laden:

```powershell
. "$PSScriptRoot\..\Libs\Lib_Menu.ps1"
```

Damit stehen alle Menüfunktionen (`Show-SubMenu`, `Write-MenuLog`, …) global zur Verfügung.

---

**Empfohlene Struktur:**

1. Library laden
2. Menüoptionen als Hashtable definieren
3. `Show-SubMenu` mit Titel und Optionen aufrufen
4. (Optional) Rückgabewerte auswerten oder bei `ReturnAfterAction` neu zeichnen

---

**Beispiel:**

```powershell
. "$PSScriptRoot\..\Libs\Lib_Menu.ps1"

$options = @{
    "1" = "Status anzeigen|Show-Status"
    "2" = "Einstellungen öffnen|Show-Settings"
}

Show-SubMenu -MenuTitle "Projektverwaltung" -Options $options
```

---

**Richtlinien:**

* Keine direkten Zugriffe auf `$global:MenuStack` außerhalb der Lib.
* Keine eigenen Log-Dateien für Menüaktionen anlegen – immer `Write-MenuLog` verwenden.
* Die Menüstruktur soll nur über `Show-SubMenu` erstellt werden.
* Untermenüs müssen als eigene Hashtables definiert und per Backtick (`$optionsSub`) übergeben werden.
* Rückgabewerte („B“, „X“, Auswahl) dürfen zur internen Navigation verwendet werden.

---

**Ziel:**
Einheitliche Menülogik in allen Modulen – unabhängig davon,
ob sie im **Master_Controller**, in **Dev-Tools** oder in **User-Modulen** genutzt wird.

---

### 📁 Verzeichnisstruktur

```
01_Config/
│   └── Menu_Config.json
03_Scripts/
│   └── Libs/
│       └── Lib_Menu.ps1
04_Logs/
    ├── Menu_Log_2025-10-21_1930.txt
    ├── Menu_Log_2025-10-21_1950.txt
    └── ...
```

---

### 🔄 Commit-Historie (Lib_Menu.ps1)

| Version    | Datum      | Beschreibung                                          |
| ---------- | ---------- | ----------------------------------------------------- |
| LIB_V1.5.1 | 21.10.2025 | Debug & Systeminfo entfernt, vollständig eigenständig |
| LIB_V1.5.0 | 21.10.2025 | Parameterdatei & automatische Log-Rotation            |
| LIB_V1.4.6 | 21.10.2025 | Logsystem mit Zeitstempel und max. N Logs             |
| LIB_V1.4.4 | 21.10.2025 | Pfadanzeige deaktivierbar                             |
| LIB_V1.0.0 | 19.10.2025 | Grundstruktur des Menüsystems erstellt                |

---

### 🧭 Geplante Erweiterungen

* Optionaler Debug-Mode (später aus `Lib_Systeminfo.ps1`)
* Direkter Sprung zum Hauptmenü (`H`)
* Farbschemata als vordefinierte Presets
* Log-Viewer-Funktion (`Dev-ViewLogs.ps1`)
* Integration in zukünftige GUI-Module (`Lib_GUI.ps1`)
* **Menu_Config soll später im Site Manager über die Einstellungen anpassbar sein (mittlere bis niedrige Priorität)**
