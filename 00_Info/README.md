# 🏗️ SITE MANAGER – README (DOC_V1.1.0)

---

## 📘 Überblick

**Site Manager** ist ein modulares PowerShell-Framework zur Verwaltung, Pflege und Automatisierung von Baustellen- und Projektstrukturen.
Es vereint System-Erkennung, Pfadverwaltung, Menüführung, JSON-Handling und automatische Modul-Manifeste in einem zentralen Framework.

---

## 🎯 Ziele

* Einheitliche Struktur und Automatisierung für alle Baustellenprojekte.
* Dynamische Pfadverwaltung mit Mehrsystem-Support.
* Zentrale Steuerung aller Tools und Module über ein einheitliches Menüsystem.
* JSON-basierte Konfiguration für maximale Kompatibilität.
* Automatische Erstellung, Pflege und Sicherung von Projektdaten.
* Vollständig modularer Aufbau zur einfachen Erweiterung durch Libraries und Module.

---

## ⚙️ Neue Kernfunktionen (Stand Oktober 2025)

| Kategorie                  | Beschreibung                                                                                                                                                                      |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🧭 **Lib_PathManager.ps1** | Dynamische Pfadverwaltung mit Multi-System-Erkennung, automatischer `PathManager_Config.json` und geordnetem JSON-Format. Erkennt Benutzer + Computer und pflegt Root-Strukturen. |
| 🧩 **Lib_Menu.ps1**        | Vollständig integriertes Menüsystem mit Logging (automatische Log-Rotation), PathManager-Anbindung und Fallback-Modus.                                                            |
| 🧠 **Lib_Json.ps1**        | Robuste JSON-Verwaltung mit Cloud-Kompatibilität (OneDrive), automatischer Config-Erstellung und optionalem Logging.                                                              |
| ⚙️ **Manifest-System**     | Automatische Generierung von `.psd1` Modulmanifesten aus den Headern der Libraries (`ManifestHint`-Blöcke).                                                                       |
| 🧰 **Testmodule**          | `Test-PathManager.ps1`, `Dev-TestMenu.ps1`, `Test-LibJson.ps1` – Entwicklungs- und Validierungstools mit Echtzeit-Feedback.                                                       |
| 🪄 **Developer Notes**     | Einheitliche Dokumentationsstruktur für jede Library (Funktionen, Tests, Commit-Historie, geplante Erweiterungen).                                                                |

---

## 🧩 Architekturübersicht

### 🔹 Komponenten

| Ebene               | Inhalt                                                                                                     |
| ------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Core-Libraries**  | `Lib_PathManager.ps1`, `Lib_Json.ps1`, `Lib_Menu.ps1`                                                      |
| **Dev-Tools**       | `Test-PathManager.ps1`, `Dev-TestMenu.ps1`, `Test-LibJson.ps1`                                             |
| **Manifest-System** | `Tools-Manifest.ps1` liest `ManifestHint`-Header aus allen Libs und erstellt automatisch `.psd1` Manifeste |
| **Config-System**   | Alle Module speichern Parameter und Pfade in JSON-Dateien unter `01_Config/`                               |

---

## 🗂️ Projektstruktur

```plaintext
SiteManager\
├── 00_Info\
│   ├── README.md
│   ├── Changelog.txt
│   └── Developer_Notes.md
│
├── 01_Config\
│   ├── Parameter_Master.json
│   ├── System.json
│   ├── Defaults.json
│   └── PathManager_Config.json
│
├── 02_Templates\
│   └── (Vorlagen und Systemtemplates)
│
├── 03_Scripts\
│   ├── SiteManager.ps1
│   ├── Modules\
│   │   ├── Add-Baustelle.ps1
│   │   ├── Backup-Monitor.ps1
│   │   ├── Update-Vorlagen.ps1
│   │   └── Dev\
│   │       ├── Dev-TestMenu.ps1
│   │       ├── Test-PathManager.ps1
│   │       └── Test-LibJson.ps1
│   └── Libs\
│       ├── Lib_PathManager.ps1
│       ├── Lib_Menu.ps1
│       ├── Lib_Json.ps1
│       └── (weitere Libs)
│
├── 04_Logs\
│   ├── Fehler_Log.txt
│   ├── System_Log.txt
│   ├── Menu_Log_*.txt
│   └── Debug_Log.txt
│
└── 05_Backup\
    ├── Parameter_Master_YYYY-MM-DD.json
    └── Templates_Versionen\
```

---

## 🧭 Manifest- und Modulsystem

**Manifest-Erstellung:**
Automatische Generierung der PowerShell-Manifeste (`.psd1`) aus Header-Informationen (ManifestHint).
Damit werden Funktionen, Kategorien, Abhängigkeiten und Versionen zentral verwaltet.

**Vorteile:**

* Automatische Pflege der Modulstruktur
* Einheitliche Dokumentation & Exportfunktion
* Nahtlose Integration in das Framework und VS Code

---

## 🧠 Developer-Notes & Dokumentation

Jede Library enthält:

* ManifestHint-Block (für automatische Manifesterstellung)
* Developer Notes (in `/00_Info/Developer_Notes/`)
* Commit-Historie & geplante Erweiterungen

**Aktuelle Libraries:**

* `Lib_PathManager.ps1` – Version LIB_V1.2.3
* `Lib_Menu.ps1` – Version LIB_V1.5.2
* `Lib_Json.ps1` – Version LIB_V1.4.0

---

## ⚙️ Versionierung

* **Hauptmodul:** `SM_Vx.y.z`
* **Module:** `MOD_Vx.y.z`
* **Libraries:** `LIB_Vx.y.z`
* **Developer Notes:** `DEVNOTES_Vx.y.z`

> Jede Datei enthält im Kopfkommentar Versions- und Manifestinformationen.

---

## 🧱 Git & VS Code Workflow

**Branch-Strategie:**

* `main` – stabile Version
* `dev` – Entwicklungszweig
* `feature-*` – neue Funktionen
* `bugfix-*` – Korrekturen

**Commit-Format:**

```
🧩 Commit – [Datum] – [Version]
• [Kurzbeschreibung]
• [Dateien]
• [Hinweise]
```

**Beispiel:**

```
🧩 Commit – 2025-10-22 – LIB_V1.5.2
• Integration von PathManager in Menu-System
• Dynamische Pfade & automatische Logrotation aktiviert
```

---

## 👨‍💻 Autor & Metadaten

**Autor:** Herbert Schrotter
**Projektstart:** Oktober 2025
**Version:** DOC_V1.1.0
**Stand:** 22.10.2025
