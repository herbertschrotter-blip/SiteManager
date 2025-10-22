# 🧪 Developer Notes – Lib_SystemScanner

---

## 📘 Überblick

**Lib_SystemScanner** ist die zentrale Analysetool-Library des Site Manager Frameworks.
Sie dient dazu, alle Module, Libraries, Core-Komponenten und Testskripte automatisch zu scannen,
deren Metadaten (**ManifestHints**) zu erfassen, Beziehungen zu erkennen
und diese Informationen in einer **zentralen Registry-Datei (Module_Registry.json)** abzulegen.

Ab Version **LIB_V1.3.2** werden die Einträge zusätzlich **automatisch gruppiert**
(Libraries, Modules, Tests, DevTools, Core, Other),
ohne die flache JSON-Struktur zu verändern – ein sogenannter **Hybridansatz**.

---

## 🎯 Ziele

* Vollautomatische Erkennung und Katalogisierung **aller `.ps1`-Dateien** innerhalb des Frameworks.
* Auslesen und Interpretieren der **ManifestHint-Blöcke** aus jedem Modul-Header.
* Erstellung einer **JSON-basierten Registry**, die Version, Kategorie, Beschreibung, Exportfunktionen, Tags und Abhängigkeiten enthält.
* Erkennung von **Beziehungen zwischen Modulen** („Dependencies“ ↔ „UsedBy“).
* Erweiterte **Gruppenzuordnung** (Libraries, Modules, Tests, DevTools, Core) für bessere Übersicht und spätere Filterung.
* Erstellung eines **Statistikblocks** mit Scanzeit, Modulanzahl und Fehlerstatus.
* Grundlage für spätere **Visualisierung** (Mermaid-Diagramme, HTML-Reports, Statusmonitore).

---

## ⚙️ Funktionsweise

### 1️⃣ Initialisierung

Beim Aufruf von `Invoke-SystemScan` werden zunächst die Libraries
**Lib_PathManager** und **Lib_Json** geladen.
Dadurch steht die dynamische Pfadverwaltung (`Get-PathMap`)
und das standardisierte JSON-Handling (`Save-JsonFile`) zur Verfügung.

```powershell
$pathManager = Join-Path $PSScriptRoot "Lib_PathManager.ps1"
$jsonLib     = Join-Path $PSScriptRoot "Lib_Json.ps1"
```

---

### 2️⃣ Pfaderkennung

Über `Get-PathMap` wird die Projektstruktur (Config, Scripts, Logs, Info usw.) erkannt.
Anschließend wird `Get-PathSubDirs` aus dem PathManager verwendet,
um **alle Unterordner unterhalb von `03_Scripts`** automatisch zu erfassen:

```powershell
$subDirs = Get-PathSubDirs -BasePath $paths.Scripts
```

Falls die Funktion fehlt, wird automatisch auf eine Standard-Suche im `Scripts`-Ordner zurückgegriffen.

---

### 3️⃣ Scan-Vorgang

Der Scanner durchsucht **rekursiv** alle gefundenen Unterordner
nach den folgenden Datei-Mustern:

```powershell
$searchPatterns = @("Lib_*.ps1", "Mod_*.ps1", "Core_*.ps1", "Test-*.ps1", "Dev-*.ps1")
```

Damit werden nun **auch alle Test- und Dev-Module** berücksichtigt,
z. B.:

```
03_Scripts\Modules\Dev\Test-SystemScanner.ps1
03_Scripts\Modules\Dev\Dev-TestMenu.ps1
```

Jede gefundene Datei wird eingelesen und Zeile für Zeile
nach einem **ManifestHint-Block** durchsucht.

Dieser Block wird dynamisch erkannt und tolerant gegenüber
Unicode-Zeichen, unterschiedlichen Leerzeilen und Headerlängen verarbeitet.

---

### 4️⃣ Datenerfassung & Gruppierung

Für jede Datei werden die wichtigsten Metadaten extrahiert und gespeichert:

| Feld                | Beschreibung                                                                         |
| ------------------- | ------------------------------------------------------------------------------------ |
| **Name**            | Dateiname ohne `.ps1`                                                                |
| **Path**            | Vollständiger Pfad zur Datei                                                         |
| **Group**           | Automatisch zugewiesene Kategorie (Libraries, Modules, Tests, DevTools, Core, Other) |
| **Version**         | Version aus Header                                                                   |
| **Category**        | Kategorie aus ManifestHint                                                           |
| **Description**     | Beschreibung aus ManifestHint                                                        |
| **ExportFunctions** | Funktionen aus ManifestHint                                                          |
| **Dependencies**    | Andere Module, die benötigt werden                                                   |
| **Tags**            | Stichworte zur Einordnung                                                            |
| **Status**          | OK, ⚠️ Kein ManifestHint oder ❌ Fehler                                               |

Die **Gruppenzuordnung** erfolgt automatisch anhand des Dateinamens:

```powershell
$info.Group = if ($name -like "Lib_*") { "Libraries" }
              elseif ($name -like "Mod_*") { "Modules" }
              elseif ($name -like "Core_*" -or $name -like "Start_*") { "Core" }
              elseif ($name -like "Test-*") { "Tests" }
              elseif ($name -like "Dev-*") { "DevTools" }
              else { "Other" }
```

Dieser Wert wird in der Registry als eigenes Feld `"Group"` mitgeschrieben,
ohne die flache JSON-Struktur zu verändern (→ **Hybridmodell**).

---

### 5️⃣ Beziehungsermittlung

Nachdem alle Module erfasst sind, werden automatisch
**„UsedBy“-Beziehungen** aufgebaut:

```powershell
foreach ($key in $registryData.Keys) {
    $deps = $registryData[$key].Dependencies
    foreach ($dep in $deps) {
        $depName = $dep.Trim()
        if ($depName -and $registryData.ContainsKey($depName)) {
            $registryData[$depName].UsedBy += $key
        }
    }
}
```

Damit entsteht ein vollständiges Beziehungsnetz zwischen allen Modulen.

---

### 6️⃣ Statistikblock

Der Statistik-Eintrag `__SystemInfo` enthält alle Kennzahlen:

```json
"__SystemInfo": {
  "GesamtModule": 10,
  "Libraries": 5,
  "Modules": 2,
  "Tests": 2,
  "DevTools": 1,
  "CoreModule": 0,
  "MitManifestHint": 10,
  "OhneManifestHint": 0,
  "Fehlerhafte": 0,
  "LetzterScan": "2025-10-22 20:45:03"
}
```

---

### 7️⃣ Ausgabe & Speicherung

Die Ergebnisse werden in zwei Dateien gespeichert:

| Datei                          | Zweck                                     |
| ------------------------------ | ----------------------------------------- |
| `00_Info\Module_Registry.json` | Alle Modul-, Gruppen- und Beziehungsdaten |
| `04_Logs\System_ScanLog.txt`   | Ablaufprotokoll des letzten Scans         |

Falls `Lib_Json` verfügbar ist, wird `Save-JsonFile` genutzt,
ansonsten erfolgt ein Fallback mit `ConvertTo-Json`.

---

## 🧠 Nutzen & Erweiterbarkeit

| Bereich             | Nutzen                                                          |
| ------------------- | --------------------------------------------------------------- |
| **Analyse**         | Übersicht aller Module inkl. Gruppen, Versionen und Beziehungen |
| **Filterung**       | Einfache Abfragen nach Gruppen (z. B. nur Tests oder Libraries) |
| **Automatisierung** | Ermöglicht Auto-Scan bei Systemstart                            |
| **Visualisierung**  | Grundlage für Diagramme (z. B. Mermaid oder HTML-Graphen)       |
| **Wartung**         | Identifikation veralteter oder fehlerhafter Module              |
| **Zukunft**         | Vorbereitung für automatisches Modul-Dashboard im Framework     |

---

## 🔗 Abhängigkeiten

* **Lib_PathManager** – zur Pfadverwaltung, Systemerkennung und Unterordner-Auflistung (`Get-PathSubDirs`).
* **Lib_Json** – zum Lesen und Schreiben der Registry-Dateien.

---

## 📂 Ausgabestruktur (Hybridmodell)

```json
{
  "Lib_Json": {
    "Group": "Libraries",
    "Version": "LIB_V1.4.0",
    "Category": "Core",
    "Description": "JSON Utility Library",
    "Dependencies": [],
    "UsedBy": ["Lib_SystemScanner", "Start_SiteManager"],
    "Status": "OK"
  },
  "Test-SystemScanner": {
    "Group": "Tests",
    "Version": "TEST_V1.0.0",
    "Category": "Test",
    "Description": "Testmodul für SystemScanner",
    "Dependencies": ["Lib_SystemScanner"],
    "UsedBy": [],
    "Status": "OK"
  },
  "__SystemInfo": {
    "GesamtModule": 10,
    "Libraries": 5,
    "Modules": 2,
    "Tests": 2,
    "DevTools": 1,
    "CoreModule": 0,
    "MitManifestHint": 10,
    "OhneManifestHint": 0,
    "Fehlerhafte": 0,
    "LetzterScan": "2025-10-22 20:45:03"
  }
}
```

---

## 🧱 Geplante Erweiterungen

1. **Diagramm-Generator:** Automatische Erstellung einer `.mmd`-Datei (Mermaid-Diagramm) zur grafischen Darstellung der Modulabhängigkeiten und Gruppierungen.
2. **Auto-Scan beim Systemstart:** Integration des Scanners in `Start_SiteManager`, um bei jedem Start die Registry zu aktualisieren.
3. **Fehlerklassifizierung:** Detaillierte Kennzeichnung (z. B. Datei fehlt, JSON ungültig, unvollständiger Hint).
4. **Versionvergleich:** Abgleich zwischen Registry-Versionen zur Änderungsüberwachung.
5. **Filter- und Exportfunktionen:** Export einzelner Gruppen (z. B. nur „Tests“ oder „DevTools“) als separate JSON-Dateien.
6. **UI-Integration:** Spätere Anzeige in einem grafischen Modul-Dashboard mit Tabs pro Gruppe.

---

## 🦦 Changelog

| Datum          | Version        | Änderungen                                                                                                   |
| -------------- | -------------- | ------------------------------------------------------------------------------------------------------------ |
| **2025-10-22** | **LIB_V1.1.0** | Erste Version mit ManifestHint-Erkennung, Registry-Erstellung und Logging                                    |
| **2025-10-22** | **LIB_V1.1.1** | Unicode-tolerante ManifestHint-Erkennung, dynamische Blockgrenzen, Casting-Fix                               |
| **2025-10-22** | **LIB_V1.2.0** | Hinzufügung von UsedBy-Beziehungen, Statistikblock `__SystemInfo`, optimierte Ausgabe                        |
| **2025-10-22** | **LIB_V1.3.0** | Integration von `Get-PathSubDirs` aus Lib_PathManager – rekursiver Scan aller Unterordner                    |
| **2025-10-22** | **LIB_V1.3.1** | Erweiterte Suchmuster (`Test-*`, `Dev-*`), automatische Erkennung von Testmodulen                            |
| **2025-10-22** | **LIB_V1.3.2** | Hybridansatz: neue Gruppenzuordnung (Libraries, Modules, Tests, DevTools, Core) + erweiterter Statistikblock |
