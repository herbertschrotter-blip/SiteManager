# 🧠 Developer Notes – Lib_PathManager.ps1

---

## 📘 Überblick

**Modulname:** `Lib_PathManager.ps1`
**Aktuelle Version:** `LIB_V1.0.0`
**Zweck:** Zentrale Verwaltung der Pfadstruktur innerhalb des Master Setup Frameworks.
Dient als universelle Schnittstelle für alle Module und Libraries, um konsistente Systempfade zu ermitteln.

---

## 🧩 Kernfunktionen

| Funktion             | Beschreibung                                                |
| -------------------- | ----------------------------------------------------------- |
| `Get-RootPath`       | Ermittelt den Projekt-Stammordner (Root).                   |
| `Get-PathMap`        | Gibt ein objektbasiertes Mapping aller Hauptordner zurück.  |
| `Test-PathStructure` | Prüft Existenz aller wichtigen Ordner und legt sie ggf. an. |

---

## ⚙️ Architektur

### 🔹 Grundprinzip

Der PathManager arbeitet mit einer vordefinierten Standardstruktur und kann sowohl lokal (Single User) als auch innerhalb des Frameworks (Multi User) eingesetzt werden.

### 🔹 Pfadstruktur (Beispiel)

```plaintext
00_Site Manager\
├── 01_Config\
├── 02_Templates\
├── 03_Scripts\
├── 04_Logs\
└── 05_Backup\
```

### 🔹 PathMap-Objekt

Die Funktion `Get-PathMap` liefert ein PowerShell-Objekt mit allen relevanten Pfaden:

```powershell
@{
    Root      = "D:\\...\\00_Site Manager"
    Config    = "D:\\...\\00_Site Manager\\01_Config"
    Templates = "D:\\...\\00_Site Manager\\02_Templates"
    Scripts   = "D:\\...\\00_Site Manager\\03_Scripts"
    Logs      = "D:\\...\\00_Site Manager\\04_Logs"
    Backup    = "D:\\...\\00_Site Manager\\05_Backup"
}
```

---

## 🧠 Technische Details

### 🔸 Root-Erkennung

```powershell
$root = Split-Path (Split-Path $PSScriptRoot)
```

Ermittelt automatisch den übergeordneten Projektpfad – unabhängig vom Modulstandort.

### 🔸 Ordnerprüfung

```powershell
foreach ($p in $map.Values) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
```

Garantiert, dass alle wichtigen Hauptordner existieren.

### 🔸 Rückgabestruktur

`Get-PathMap` gibt ein HashTable-ähnliches PowerShell-Objekt zurück, das direkt in anderen Libs (z. B. Lib_Json) eingebunden werden kann.

---

## 🧰 Entwicklungs- und Teststrategie

### 🔹 Testmodul: `Test-LibPathManager.ps1`

* **Version:** DEV_V1.0.0
* **Zweck:** Überprüfung der Root-Erkennung und Pfadzuordnung.

### 🔹 Testszenarien

| Test               | Beschreibung                          | Erwartung              |
| ------------------ | ------------------------------------- | ---------------------- |
| Root-Erkennung     | Ermittelt korrekten Hauptordner       | ✅ gültiger Root-Pfad   |
| Pfadmap-Erstellung | Erstellt Objekt mit allen Hauptpfaden | ✅ vollständiges Objekt |
| Ordnerprüfung      | Legt fehlende Ordner automatisch an   | ✅ keine Fehler         |

### 🔹 Beispielausgabe

```
📊 PFADÜBERSICHT:
──────────────────────────────
Root       : D:\...\00_Site Manager
Config     : D:\...\01_Config
Templates  : D:\...\02_Templates
Scripts    : D:\...\03_Scripts
Logs       : D:\...\04_Logs
Backup     : D:\...\05_Backup
```

---

## 🚀 Geplante Erweiterungen

| Version | Feature                      | Beschreibung                                                          |
| ------- | ---------------------------- | --------------------------------------------------------------------- |
| V1.1.0  | Dynamische Projektpfade      | Unterstützung für verschiedene Projektwurzeln (z. B. 00_Master_Setup) |
| V1.2.0  | Multi-System-Erkennung       | Automatische Erkennung anhand Benutzername & Computername             |
| V1.3.0  | Integration in Config-System | Übergabe an zentrale `System.json` für globale Pfadverwaltung         |
| V1.5.0  | Projektwechsler              | Ermöglicht das Umschalten zwischen unterschiedlichen Root-Strukturen  |

---

## 📦 Commit-Historie

| Datum      | Version | Änderungen                                                           |
| ---------- | ------- | -------------------------------------------------------------------- |
| 2025-10-22 | V1.0.0  | Erstveröffentlichung – stabile Pfadermittlung und Verzeichnisprüfung |

---

📘 **Status:** Stabil – empfohlen für alle Core-Libs (z. B. Lib_Json, Lib_Menu)

🧩 **Getestet mit:** `Test-LibPathManager.ps1` (DEV_V1.0.0)

---
