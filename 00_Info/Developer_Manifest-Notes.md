## ⚙️ Manifest-Erstellung (PowerShell-Module)

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

### 💡 Vorteile

| Bereich                | Nutzen                                                                 |
| ---------------------- | ---------------------------------------------------------------------- |
| **Automatisierung**    | Manifestdaten werden automatisch gepflegt                              |
| **Konsistenz**         | Alle Libraries folgen einheitlicher Struktur                           |
| **Zukunftssicherheit** | Spätere Modulupdates oder Installationen automatisierbar               |
| **Doku-Integration**   | Developer Notes, Commit-Historie und Manifest-Hints greifen ineinander |

