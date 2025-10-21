## 🧩 Lib_Menu.ps1 – Menüsystem

**Pfad:** `03_Scripts/Libs/Lib_Menu.ps1`
**Version:** LIB_V1.5.2
**Status:** stabil (Framework-integriert)
**Abhängigkeiten:** `Lib_PathManager.ps1`

---

### ⚙️ Zweck

Zentrale Library zur Steuerung der textbasierten Menüführung im **Site Manager**.
Seit Version 1.5.2 unterstützt sie den **Lib_PathManager**, um Config- und Log-Pfade dynamisch aus dem Framework zu ermitteln.
Dadurch entfallen alle hartcodierten Pfadangaben; die Lib passt sich automatisch an das installierte System an.

---

### 🔧 Hauptfunktionen

| Funktion                         | Beschreibung                                                                 |
| -------------------------------- | ---------------------------------------------------------------------------- |
| `Show-SubMenu`                   | Erstellt ein Menü mit beliebig vielen Optionen, inklusive Rückkehr und Exit. |
| `Write-MenuLog`                  | Schreibt Aktionen ins aktuelle Menü-Logfile (rotierend, max. N Dateien).     |
| `Push-MenuStack / Pop-MenuStack` | Verwalten die hierarchische Menüstruktur.                                    |
| `Get-CurrentMenuPath`            | Gibt den aktuellen Menüpfad als String zurück.                               |

---

### ⚙️ Konfiguration & Logik

* **Parameterdatei:**

  * Wird automatisch unter `01_Config/Menu_Config.json` angelegt (wenn nicht vorhanden).
  * Bei aktivem PathManager werden diese Pfade über `$pathMap.Config` ermittelt.
  * Steuerung von Anzeige, Farben, Log-Rotation und Pfadanzeige.
  * Standard-Config:

    ```json
    {
      "ShowPath": false,
      "MaxLogFiles": 10,
      "LogRetentionDays": 30,
      "LogFilePrefix": "Menu_Log_",
      "LogDateFormat": "yyyy-MM-dd_HHmm",
      "ColorScheme": {
        "Title": "White",
        "Highlight": "Cyan",
        "Error": "Red"
      }
    }
    ```

* **Logging:**

  * Log-Pfad wird über `$pathMap.Logs` ermittelt.
  * Jede Sitzung legt eine neue Datei `Menu_Log_YYYY-MM-DD_HHMM.txt` an.
  * Alte Logs werden automatisch gelöscht (nach Anzahl oder Alter).

* **PathManager-Integration:**

  * Erkennt automatisch, ob `Lib_PathManager.ps1` vorhanden ist.
  * Fallback auf lokale Pfade (`..\\..\\01_Config`, `..\\..\\04_Logs`), falls nicht verfügbar.
  * Konsistente Verzeichnisverwaltung innerhalb des Frameworks.

---

### 🧩 Integration in Module

**Einbindung:**

```powershell
. "$PSScriptRoot\\..\\Libs\\Lib_Menu.ps1"
```

Nach dem Laden stehen alle Menü-Funktionen sowie die dynamischen Pfad-Features zur Verfügung.

---

**Empfohlene Struktur:**

1. Library laden
2. Menüoptionen als Hashtable definieren
3. `Show-SubMenu` aufrufen
4. (Optional) Rückgabewert auswerten

---

### 📘 Richtlinien

* Keine direkten Zugriffe auf `$global:MenuStack` außerhalb der Lib.
* Keine eigenen Log-Dateien für Menüaktionen anlegen – immer `Write-MenuLog` verwenden.
* Menüstruktur ausschließlich über `Show-SubMenu` erstellen.
* Untermenüs als eigene Hashtables definieren und übergeben.
* Rückgabewerte (`B`, `X`, Auswahl) können zur internen Navigation genutzt werden.

---

### 🎯 Ziel

Einheitliche Menülogik für alle Module des **Site Managers** – unabhängig davon, ob sie im Hauptmodul, in Dev-Tools oder Benutzererweiterungen verwendet werden.
Die Lib soll ein konsistentes Bedienverhalten sicherstellen und später auch als Basis für GUI-Elemente dienen.

---

### 📁 Verzeichnisstruktur (nach Integration)

```
01_Config/
│   └── Menu_Config.json
03_Scripts/
│   └── Libs/
│       ├── Lib_Menu.ps1
│       └── Lib_PathManager.ps1
04_Logs/
    ├── Menu_Log_2025-10-22_2100.txt
    └── ...
```

---

### 🔄 Commit-Historie (Lib_Menu.ps1)

| Version    | Datum      | Beschreibung                                                                               |
| ---------- | ---------- | ------------------------------------------------------------------------------------------ |
| LIB_V1.5.2 | 22.10.2025 | Integration von Lib_PathManager (für Config & Logs), automatische Pfaderkennung + Fallback |
| LIB_V1.5.1 | 21.10.2025 | Debug & Systeminfo entfernt, vollständig eigenständig                                      |
| LIB_V1.5.0 | 21.10.2025 | Parameterdatei & Log-Rotation                                                              |
| LIB_V1.4.6 | 21.10.2025 | Zeitstempel-Logs, max. N Logs                                                              |
| LIB_V1.4.4 | 21.10.2025 | Pfadanzeige deaktivierbar                                                                  |
| LIB_V1.0.0 | 19.10.2025 | Grundstruktur erstellt                                                                     |

---

### 🧭 Geplante Erweiterungen

* Optionaler Debug-Mode (aus `Lib_Systeminfo.ps1`)
* Direkter Sprung zum Hauptmenü (`H`)
* Vordefinierte Farbschemata
* Log-Viewer (`Dev-ViewLogs.ps1`)
* GUI-Integration (`Lib_GUI.ps1`)
* **Zentrale Anpassung von `Menu_Config` über Framework-Einstellungen (geplant)**
