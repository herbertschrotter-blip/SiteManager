# 🧩 Developer Notes – Lib_SystemScanner

---

## 📘 Überblick

**Lib_SystemScanner** ist die zentrale Analysetool-Library des Site Manager Frameworks. Sie dient dazu, alle Module, Libraries und Core-Komponenten automatisch zu scannen, deren Metadaten (ManifestHints) zu erfassen, die Beziehungen untereinander zu ermitteln und diese Informationen in einer zentralen Registry abzulegen.

---

## 🎯 Ziele

* Vollautomatische Erkennung und Katalogisierung aller .ps1-Dateien innerhalb des Frameworks.
* Auslesen und Interpretieren der **ManifestHint**-Blöcke aus jedem Modul-Header.
* Erstellung einer **JSON-basierten Registry**, die Version, Kategorie, Beschreibung, Exportfunktionen, Tags und Abhängigkeiten enthält.
* Erkennung von **Beziehungen zwischen Modulen** („Dependencies“ ↔ „UsedBy“).
* Automatische Erstellung eines **Statistikblocks** mit Scanzeit, Modulanzahl und Fehlerstatus.
* Grundlage für spätere **Visualisierung** (z. B. Mermaid-Diagramme oder Systemstatusberichte).

---

## ⚙️ Funktionsweise

### 1️⃣ Initialisierung

Beim Aufruf von `Invoke-SystemScan` werden zunächst die Libraries **Lib_PathManager** und **Lib_Json** geladen. Dadurch steht die dynamische Pfadverwaltung und standardisierte JSON-Verarbeitung zur Verfügung.

```powershell
$pathManager = Join-Path $PSScriptRoot "Lib_PathManager.ps1"
$jsonLib = Join-Path $PSScriptRoot "Lib_Json.ps1"
```

### 2️⃣ Pfaderkennung

Über `Get-PathMap` wird die aktuelle Projektstruktur (Config, Scripts, Logs, Info usw.) ermittelt, sodass der Scanner systemunabhängig arbeitet.

### 3️⃣ Scan-Vorgang

Der Scanner durchsucht rekursiv den Scripts-Ordner nach allen Dateien vom Typ `Lib_*.ps1`, `Mod_*.ps1` und `Core_*.ps1`.

Jede Datei wird eingelesen und Zeile für Zeile nach einem **ManifestHint-Block** durchsucht.

```powershell
$content | Select-String -Pattern "ManifestHint" -SimpleMatch
```

Der Block wird dynamisch bis zur nächsten Trennlinie (`# ====...`) oder Leerzeile gelesen. Dadurch ist die Erkennung Unicode-tolerant und auch bei unterschiedlichen Headerlängen robust.

### 4️⃣ Datenerfassung

Für jede Datei werden folgende Felder in einem Objekt gespeichert:

| Feld                | Bedeutung                            |
| ------------------- | ------------------------------------ |
| **Name**            | Dateiname ohne Endung                |
| **Path**            | Vollständiger Pfad zur Datei         |
| **Version**         | Version aus Header                   |
| **Category**        | Kategorie (Core, Utility, Test etc.) |
| **Description**     | Kurzbeschreibung aus ManifestHint    |
| **ExportFunctions** | Liste exportierter Funktionen        |
| **Dependencies**    | Benötigte Libraries oder Module      |
| **Tags**            | Stichworte zur Klassifikation        |
| **Status**          | OK, Fehler oder Kein ManifestHint    |

### 5️⃣ Beziehungsermittlung

Nach der Datensammlung wird eine zweite Schleife ausgeführt, um **UsedBy**-Beziehungen aufzubauen:

```powershell
foreach ($key in $registryData.Keys) {
    foreach ($dep in $registryData[$key].Dependencies) {
        if ($dep -and $registryData.ContainsKey($dep)) {
            $registryData[$dep].UsedBy += $key
        }
    }
}
```

Damit wird für jede Dependency automatisch festgehalten, welches Modul sie verwendet.

### 6️⃣ Statistikblock

Zusätzlich erzeugt der Scanner einen eigenen Registry-Eintrag `__SystemInfo`, der den Gesamtstatus enthält:

```json
"__SystemInfo": {
  "GesamtModule": 12,
  "Libraries": 5,
  "Module": 6,
  "CoreModule": 1,
  "MitManifestHint": 11,
  "OhneManifestHint": 1,
  "Fehlerhafte": 0,
  "LetzterScan": "2025-10-22 19:00:15"
}
```

### 7️⃣ Ausgabe & Speicherung

Die Ergebnisse werden in zwei Dateien ausgegeben:

| Datei                          | Zweck                                   |
| ------------------------------ | --------------------------------------- |
| `00_Info\Module_Registry.json` | Enthält alle Modul- und Beziehungsdaten |
| `04_Logs\System_ScanLog.txt`   | Protokolliert den Ablauf und Fehler     |

---

## 🧠 Nutzen & Erweiterbarkeit

| Bereich             | Nutzen                                                            |
| ------------------- | ----------------------------------------------------------------- |
| **Analyse**         | Ermöglicht Abhängigkeits- und Statusanalysen des gesamten Systems |
| **Visualisierung**  | Grundlage für Graphen, Mermaid-Diagramme oder Netzwerke           |
| **Dokumentation**   | Dient als dynamischer Modulindex des Frameworks                   |
| **Fehlererkennung** | Ermittelt fehlerhafte oder unvollständige Module automatisch      |
| **Zukunft**         | Geplant: grafische Ausgabe, HTML-Bericht, Diagramm-Export         |

---

## 🔗 Abhängigkeiten

* **Lib_PathManager** – zur Pfadverwaltung und Systemerkennung.
* **Lib_Json** – zum standardisierten Lesen und Schreiben der Registry.

---

## 📂 Ausgabestruktur (Beispiel)

```json
{
  "Lib_Json": {
    "Version": "LIB_V1.4.0",
    "Category": "Utility",
    "Description": "JSON Utility Library",
    "Dependencies": [],
    "UsedBy": ["Lib_SystemScanner", "Start_SiteManager"],
    "Status": "OK"
  },
  "Lib_SystemScanner": {
    "Version": "LIB_V1.2.0",
    "Category": "Utility",
    "Description": "Scans all modules and updates registry.",
    "Dependencies": ["Lib_PathManager", "Lib_Json"],
    "UsedBy": ["Start_SiteManager"],
    "Status": "OK"
  },
  "__SystemInfo": {
    "GesamtModule": 5,
    "Libraries": 3,
    "Module": 1,
    "CoreModule": 1,
    "MitManifestHint": 5,
    "OhneManifestHint": 0,
    "Fehlerhafte": 0,
    "LetzterScan": "2025-10-22 19:00:15"
  }
}
```

---

## 🧱 Geplante Erweiterungen

1. **Diagramm-Generator:** Automatische Erstellung einer `.mmd`-Datei (Mermaid-Diagramm) zur grafischen Visualisierung der Modulabhängigkeiten.
2. **Auto-Scan beim Systemstart:** Integration des Scanners in den Startprozess von `Start_SiteManager`.
3. **Fehlerklassifizierung:** Detaillierte Kennzeichnung (z. B. Datei fehlt, JSON ungültig, unvollständiger Hint).
4. **Versionvergleich:** Abgleich zwischen Registry und Live-System, um geänderte Module zu markieren.
5. **Filter und Export:** Möglichkeit, Registry-Teile nach Kategorie oder Status zu exportieren.

---

## 🪶 Changelog

| Datum          | Version        | Änderungen                                                                            |
| -------------- | -------------- | ------------------------------------------------------------------------------------- |
| **2025-10-22** | **LIB_V1.1.0** | Erste Version mit ManifestHint-Erkennung, Registry-Erstellung und Logging             |
| **2025-10-22** | **LIB_V1.1.1** | Unicode-tolerante ManifestHint-Erkennung, dynamische Blockgrenzen, Casting-Fix        |
| **2025-10-22** | **LIB_V1.2.0** | Hinzufügung von UsedBy-Beziehungen, Statistikblock `__SystemInfo`, optimierte Ausgabe |
