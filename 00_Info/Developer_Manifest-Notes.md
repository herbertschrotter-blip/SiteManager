## ⚙️ Manifest-Erstellung (PowerShell-Module)
+ ### Version: DOC_V1.2.0 – Automatische Registry-Integration (22.10.2025)

**Ziel:**
Automatische Erstellung und Pflege von PowerShell-Modulmanifesten (`.psd1`) für den Site Manager.

---

### 🧭 Konzept

Ein Manifest beschreibt ein PowerShell-Modul mit Metadaten wie Version, Autor, Beschreibung, Abhängigkeiten und exportierten Funktionen.
Es wird zusammen mit einer `.psm1`-Datei genutzt, die die einzelnen Libraries (`Lib_*.ps1`) lädt.

---

### 🔧 Vorgehensweise

1. **Manifest manuell oder automatisch erzeugen**

   * PowerShell-Befehl:

     ```powershell
     New-ModuleManifest -Path .\SiteManager.Core.psd1 -RootModule SiteManager.Core.psm1
     ```
   * oder über das interne Tool `Tools-Manifest.ps1` mit der Funktion `New-SiteManagerManifest`.

2. **.psm1-Modul**

   * Lädt alle Libraries über Dot-Sourcing:

     ```powershell
     . "$PSScriptRoot\Libs\Lib_Menu.ps1"
     . "$PSScriptRoot\Libs\Lib_Json.ps1"
     ```

3. **Manifest (.psd1)**

   * Beschreibt das Modul (Version, Autor, Funktionen).
   * Hält Beziehungen zu anderen Modulen in `RequiredModules`.

---

### 🧩 ManifestHint-System

Jede Library enthält im Header einen Block, der automatisch ausgelesen wird:

```powershell
# ManifestHint:
#   ExportFunctions: Show-SubMenu, Write-MenuLog
#   Description: Menüsystem mit Navigation & Logging
#   Category: Core
#   Tags: Menu, Logging, Framework
#   Dependencies: (none)
```

Diese Informationen werden später genutzt, um:

* `FunctionsToExport`
* `Description`
* `Tags`
* `Dependencies`
  automatisch im Manifest zu generieren.

---

### 🤖 Automatische Manifest-Erstellung über Registry

Ab Version **LIB_V1.1.0** des ManifestGenerators wird das Manifest nicht mehr manuell erstellt,  
sondern automatisch auf Basis der Daten aus der **SystemRegistry (`00_Info\Module_Registry.json`)**.

**Ablauf:**

1. **SystemScanner** scannt alle Libraries und Module.  
   → Ergebnis: `Module_Registry.json` mit Version, ExportFunctions, Dependencies, Category usw.

2. **ManifestGenerator** liest diese Registry und erzeugt für jede Library oder jedes Modul  
   ein entsprechendes `.psd1`-Manifest, inklusive:
   - Version (aus Header)
   - FunctionsToExport (aus ManifestHint)
   - Dependencies (aus Registry)
   - Category & Description

3. **Abgleich & Update**  
   Bestehende `.psd1`-Dateien werden nur aktualisiert, wenn Versionsnummer oder ExportFunctions geändert wurden.

**Beispiel:**
```powershell
Invoke-SystemScan
Invoke-ManifestGenerator -Registry "00_Info\Module_Registry.json"

---

### 💡 Vorteile

| Bereich                | Nutzen                                                                 |
| ---------------------- | ---------------------------------------------------------------------- |
| **Automatisierung**    | Manifestdaten werden automatisch gepflegt                              |
| **Konsistenz**         | Alle Libraries folgen einheitlicher Struktur                           |
| **Zukunftssicherheit** | Spätere Modulupdates oder Installationen automatisierbar               |
| **Doku-Integration**   | Developer Notes, Commit-Historie und Manifest-Hints greifen ineinander |

---

### 🧠 Framework-Integration

Der ManifestGenerator ist direkt mit dem **SystemScanner** verknüpft:

| Komponente | Aufgabe |
|-------------|----------|
| `Lib_SystemScanner.ps1` | Sammelt Modul- & Librarydaten, erstellt Registry |
| `Lib_ManifestGenerator.ps1` | Liest Registry, erzeugt .psd1-Dateien |
| `Lib_Json.ps1` | Verwaltet Lese-/Schreibvorgänge und Logging |
| `Lib_PathManager.ps1` | Bestimmt Zielpfade der Manifeste |

Diese Zusammenarbeit bildet das Fundament der **automatisierten Modulverwaltung** im Site Manager.


| 2025-10-22 | V1.2.0 | Erweiterung: Automatische Manifest-Erstellung über Registry-System, Framework-Integration ergänzt |
