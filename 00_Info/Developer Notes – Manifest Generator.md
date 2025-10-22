# 🧩 Developer Notes – Manifest Generator

---

## 📘 Überblick

Der **Manifest Generator** ist eine zentrale Komponente des SiteManager-Frameworks.
Er dient dazu, automatisch PowerShell-Manifestdateien (`.psd1`) für alle Libraries und Module im System zu erstellen und zu pflegen.

Ziel ist es, eine einheitliche, automatisierte Modulverwaltung zu ermöglichen, die Versionen, Abhängigkeiten und Exporte standardisiert.

---

## 🎯 Ziele und Aufgaben

| Bereich                      | Beschreibung                                                                                                                                                         |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 🧾 **Manifest-Erstellung**   | Liest den `ManifestHint`-Block jeder Library (.ps1 oder .psm1) aus und erzeugt daraus automatisch ein PowerShell-Manifest (.psd1).                                   |
| 🔁 **Aktualisierung**        | Erkennt geänderte Libraries anhand von Zeitstempeln und aktualisiert ihre Manifestdateien bei Bedarf.                                                                |
| 📚 **Registry-Pflege**       | Schreibt oder aktualisiert die zentrale `Module_Registry.json` im Ordner `00_Info`, in der alle Module, Versionen, Kategorien und Abhängigkeiten gespeichert werden. |
| 🧠 **Metadatenverwaltung**   | Extrahiert Beschreibung, Autor, Version und Exportfunktionen direkt aus dem Header der Library.                                                                      |
| ⚙️ **Framework-Integration** | Wird später automatisch beim Start des SiteManager (z. B. im `Start_SiteManager.ps1`) eingebunden, um Moduländerungen zu erkennen und Manifeste aktuell zu halten.   |

---

## 🧠 Funktionsweise

1. **Scan-Vorgang starten:**

   * Befehl: `Invoke-ManifestScan -Path "03_Scripts\\Libs"`
   * Der Generator durchsucht rekursiv den angegebenen Pfad nach Dateien mit `Lib_*.ps1` oder `Lib_*.psm1`.

2. **ManifestHint auslesen:**

   * Der obere Headerbereich jeder Datei wird nach einem Block durchsucht, der mit `# 🧩 ManifestHint:` beginnt.
   * Alle untergeordneten Einträge (ExportFunctions, Description, Category, Tags, Dependencies) werden analysiert.

3. **Manifestdatei generieren:**

   * Für jede erkannte Library wird eine `.psd1`-Datei mit standardisiertem Aufbau erstellt:

     ```powershell
     @{
         RootModule        = 'Lib_X.psm1'
         ModuleVersion     = '1.0.0'
         Author            = 'Herbert Schrotter'
         Description       = '...'
         FunctionsToExport = @('FunktionA', 'FunktionB')
         RequiredModules   = @('Lib_PathManager', 'Lib_Json')
     }
     ```

4. **Registry aktualisieren:**

   * Nach der Manifest-Erstellung wird die Datei `00_Info\\Module_Registry.json` automatisch ergänzt oder angepasst.
   * Jedes Modul erhält dort einen Eintrag mit:

     ```json
     {
       "Lib_Json": {
         "Version": "1.0.0",
         "Category": "Library",
         "Description": "JSON Utility Library",
         "Dependencies": ["Lib_PathManager"]
       }
     }
     ```

5. **Änderungserkennung:**

   * Beim nächsten Lauf prüft der Generator die Zeitstempel der `.ps1`- und `.psd1`-Dateien.
   * Wenn die Library neuer ist, wird ihr Manifest automatisch aktualisiert.

6. **Logging:**

   * Alle Vorgänge werden in `04_Logs\\Manifest_ScanLog.txt` protokolliert.
   * Jede Aktion (erstellt, aktualisiert, übersprungen, Fehler) wird mit Zeitstempel geloggt.

---

## 🧩 Spätere Systemintegration

Der Manifest Generator wird in einer späteren Entwicklungsphase **direkt in das Framework eingebunden**, um automatisch ausgeführt zu werden, sobald der SiteManager gestartet wird.

### 🔧 Geplanter Ablauf beim Systemstart

1. **Start_SiteManager.ps1** lädt PathManager und erkennt Libraries.
2. **ManifestGenerator** wird aufgerufen, um Änderungen oder fehlende `.psd1`-Dateien zu erkennen.
3. Wenn nötig, erstellt oder aktualisiert der Generator die Manifestdateien.
4. Erst danach werden alle Module (Libs) geladen oder importiert.

### 📦 Vorteile der Integration

| Vorteil                        | Beschreibung                                                                                |
| ------------------------------ | ------------------------------------------------------------------------------------------- |
| 🔁 **Automatische Konsistenz** | Alle Module sind beim Start auf dem neuesten Stand.                                         |
| 🧠 **Selbstheilendes System**  | Fehlende oder veraltete Manifeste werden automatisch erzeugt.                               |
| 📚 **Zentrale Modulübersicht** | Die Registry dient als Basis für die Developer-Dokumentation.                               |
| ⚙️ **Erweiterbarkeit**         | Später kann die Manifest-Logik auch auf externe Module (Tools, Plugins) ausgeweitet werden. |

---

## 🧱 Aktueller Status (Stand 22.10.2025)

* [x] **Library `Lib_ManifestGenerator.ps1`** funktionsfähig (manueller Aufruf)
* [x] **Testtool `Test-ManifestGenerator.ps1`** erkennt Pfade & Libraries
* [ ] Automatische Integration in `Start_SiteManager.ps1`
* [ ] Versionierung & Dependency-Prüfung in Registry erweitern

---

## 🧾 Versionshistorie

### 🪶 DEV_NOTES_V1.1.0 – 22.10.2025

* Erweiterung der Developer Notes um Versionsinformationen und Statusübersicht.
* Detaillierte Beschreibung der Funktionsweise und geplanter Integration.
* Ergänzung der Vorteile-Tabelle und Statusliste.

### 🪶 DEV_NOTES_V1.0.0 – 22.10.2025

* Ersterstellung der Developer Notes zum ManifestGenerator.
* Enthält Zieldefinition, Aufgabenbeschreibung und Ablaufstruktur.
* Dokumentiert geplante Integration in den SiteManager-Startprozess.
* Grundlage für automatische Manifest- und Registry-Verwaltung.
