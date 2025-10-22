# 🧠 Developer Notes – Lib_PathManager.ps1

---

## 📘 Überblick

**Modulname:** `Lib_PathManager.ps1`
**Aktuelle Version:** `LIB_V1.2.3`
**Zweck:** Zentrale Verwaltung der Pfadstruktur innerhalb des Master Setup Frameworks.
Dient als universelle Schnittstelle für alle Module und Libraries, um konsistente Systempfade zu ermitteln und Multi-System-Unterstützung zu bieten.

---

## 🧩 Kernfunktionen

| Funktion            | Beschreibung                                                                                 |
| ------------------- | -------------------------------------------------------------------------------------------- |
| `Get-ProjectRoot`   | Ermittelt den Hauptordner (Root) des Site Managers anhand der Standardstruktur.              |
| `Get-PathMap`       | Gibt ein objektbasiertes Mapping aller Hauptordner zurück, dynamisch aus der Config geladen. |
| `Get-PathConfig`    | Liefert den Pfad zum Config-Verzeichnis.                                                     |
| `Get-PathLogs`      | Liefert den Pfad zum Log-Verzeichnis.                                                        |
| `Get-PathBackup`    | Liefert den Pfad zum Backup-Verzeichnis.                                                     |
| `Get-PathTemplates` | Liefert den Pfad zum Template-Verzeichnis.                                                   |
| `Register-System`   | Registriert das aktuelle System (Benutzer + Computer) in der PathManager-Config.             |
| `Get-ActiveSystem`  | Liest den aktuell aktiven Systeme-Eintrag aus der Config aus.                                |

---

## ⚙️ Architektur

### 🔹 Grundprinzip

Der PathManager arbeitet mit einer konfigurierbaren Ordnerstruktur, die in `01_Config/PathManager_Config.json` gespeichert wird.
Beim Start erkennt er automatisch den aktiven Benutzer und Computer, legt ggf. neue Systeme an und verwaltet mehrere Root-Pfade.

### 🔹 Pfadstruktur (Beispiel)

```plaintext
00_Site Manager\
├── 01_Config\
├── 02_Templates\
├── 03_Scripts\
├── 04_Logs\
└── 05_Backup\
```

### 🔹 Beispiel PathMap-Objekt

```powershell
@{
    Root      = "D:\\...\\00_Site Manager"
    Config    = "D:\\...\\01_Config"
    Templates = "D:\\...\\02_Templates"
    Scripts   = "D:\\...\\03_Scripts"
    Logs      = "D:\\...\\04_Logs"
    Backup    = "D:\\...\\05_Backup"
}
```

---

## 🧠 Technische Details

### 🔸 Multi-System-Erkennung

Der PathManager erstellt oder aktualisiert automatisch die Datei `PathManager_Config.json`.

```json
{
  "Version": "CFG_V1.2.0",
  "Ordnerstruktur": {
    "Config": "01_Config",
    "Templates": "02_Templates",
    "Scripts": "03_Scripts",
    "Logs": "04_Logs",
    "Backup": "05_Backup"
  },
  "Systeme": [
    {
      "Benutzer": "herbe",
      "Computer": "DESKTOP-PC",
      "Root": "D:\\OneDrive\\Dokumente\\...",
      "LetzteErkennung": "2025-10-22 08:11:50"
    }
  ]
}
```

### 🔸 Verbesserte Systemerkennung (seit V1.2.3)

* Erkennt bestehende Systeme korrekt anhand Benutzername & Computername.
* Verhindert doppelte Einträge.
* Aktualisiert nur den Zeitstempel bei erneutem Aufruf.

### 🔸 Geordnete JSON-Struktur

Alle Config-Dateien werden mit `[ordered]@{}` erstellt, damit die Reihenfolge in der JSON-Datei stabil bleibt.

### 🔸 Initialisierung

Beim Laden der Library:

* Wird `Get-ActiveSystem` automatisch aufgerufen.
* Gibt Statusmeldungen aus („Aktives System erkannt“ oder „Fallback-Modus“).

---

## 🧰 Entwicklungs- und Teststrategie

### 🔹 Testmodul: `Test-PathManager.ps1`

* **Version:** DEV_V1.1.0
* **Zweck:** Vollständige Funktionsprüfung aller Endpunkte inkl. Systemerkennung & Pfadmapping.

### 🔹 Testszenarien

| Test               | Beschreibung                             | Erwartung                          |
| ------------------ | ---------------------------------------- | ---------------------------------- |
| `Get-ProjectRoot`  | Root wird korrekt erkannt                | ✅ Gültiger Root-Pfad               |
| `Get-PathMap`      | Gibt alle Hauptpfade zurück              | ✅ Vollständige Struktur            |
| `Register-System`  | Neues System wird nur einmal registriert | ✅ Kein Duplikat                    |
| `Get-ActiveSystem` | Liefert das aktuelle Systemobjekt        | ✅ Enthält Benutzer, Computer, Root |

### 🔹 Beispielausgabe

```
📊 PFAD- UND SYSTEMÜBERSICHT:
──────────────────────────────────────────────
Root         : D:\...\00_Site Manager
Config       : D:\...\01_Config
Templates    : D:\...\02_Templates
Scripts      : D:\...\03_Scripts
Logs         : D:\...\04_Logs
Backup       : D:\...\05_Backup
──────────────────────────────────────────────
Benutzer        : herbe
Computer        : DESKTOP-PC
Root            : D:\...\00_Site Manager
LetzteErkennung : 2025-10-22 08:11:50
```

---

## 🚀 Geplante Erweiterungen

| Version | Feature                  | Beschreibung                                              |
| ------- | ------------------------ | --------------------------------------------------------- |
| V1.3.0  | Integration mit Lib_Json | Gemeinsame JSON-Lese-/Schreiblogik zur Vereinheitlichung  |
| V1.4.0  | DebugMode-Unterstützung  | Ausgabe erweiterter Statusinfos bei Systemerkennung       |
| V1.5.0  | Systemprofil-Export      | Ermöglicht Export aller bekannten Systeme als Tabelle     |
| V2.0.0  | Projektwechsler          | Umschalten zwischen Root-Strukturen und Arbeitsumgebungen |

---

## 📦 Commit-Historie

| Datum      | Version | Beschreibung                                                                   |
| ---------- | ------- | ------------------------------------------------------------------------------ |
| 2025-10-22 | V1.2.3  | Multi-System-Erkennung optimiert, geordnete JSON-Ausgabe, Duplikate verhindert |
| 2025-10-22 | V1.2.2  | Reihenfolge der JSON-Felder fixiert (Version → Ordnerstruktur → Systeme)       |
| 2025-10-22 | V1.2.0  | Multi-System-Unterstützung hinzugefügt                                         |
| 2025-10-22 | V1.1.0  | Dynamische Ordnerstruktur aus Config eingebaut                                 |
| 2025-10-22 | V1.0.0  | Erstveröffentlichung – stabile Pfadermittlung und Verzeichnisprüfung           |

---

📘 **Status:** Stabil – empfohlen für Core-Libs (z. B. Lib_Menu, Lib_Json)

🧩 **Getestet mit:** `Test-PathManager.ps1 (DEV_V1.1.0)` und `Dev-TestMenu.ps1 (MOD_V1.1.1)`
