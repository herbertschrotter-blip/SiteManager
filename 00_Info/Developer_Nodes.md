# 🏗️ SITE MANAGER – Projektübersicht

> 🚀 **Hinweis:** Dies ist die Startversion der Projektübersicht. Das Dokument wird mit neuen Versionen des Site Managers kontinuierlich erweitert und aktualisiert.

---

> 💡 **Header-Standard:** Alle neuen PowerShell-Dateien im Projekt sollen mit folgendem Block beginnen:

```
# ============================================================
# 🧭 MASTER SETUP – SYSTEMSTART
# Version: SYS_V1.1.5
# Zweck:   Hauptmenü des PowerShell Master Setup Systems
# Autor:   Herbert Schrotter
# Datum:   19.10.2025
# ============================================================
```

---

## 📘 Gesamtziel

Das Projekt **Site Manager** ist das zentrale PowerShell-Framework zur Verwaltung, Pflege und Automatisierung von Baustellenprojekten. Es dient als Steuerzentrale für Module, Libraries, Konfigurationen und Backups.

---

## 🧩 Hauptkomponenten

### 🧠 1. Hauptmodul

| Datei             | Zweck                                                                                                     |
| ----------------- | --------------------------------------------------------------------------------------------------------- |
| `SiteManager.ps1` | Einstiegspunkt und Steuerzentrale des Systems (Startmenü, Modul-Loader, Debug-System, Manifest-Anbindung) |

### ⚙️ 2. Libraries (Lib_*.ps1)

| Datei                | Zweck                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------- |
| `Lib_Systeminfo.ps1` | Ermittelt Benutzername, Computername, Betriebssystem, Laufwerksstruktur usw.                |
| `Lib_ListFiles.ps1`  | Liest und listet Dateien/Ordner aus; kann Strukturen als JSON speichern.                    |
| `Lib_Debug.ps1`      | Debugging-, Logging- und Fehlerausgabefunktionen (mit `debugMode`).                         |
| `Lib_Json.ps1`       | Lesen, Schreiben und Validieren von JSON-Dateien.                                           |
| `Lib_Menu.ps1`       | Dynamische Menüsysteme für den Site Manager (mehrstufige Navigation, Rücksprung, Eingaben). |

> 💡 *Die Libs werden zu Beginn automatisch geladen.*

### 🧰 3. Module (Modules/*.ps1)

> 💡 Module können thematisch in Unterordner gegliedert werden (z. B. `Modules\Menu`, `Modules\System`, `Modules\Project`).

| Modul                 | Zweck                                                    |
| --------------------- | -------------------------------------------------------- |
| `Add-Baustelle.ps1`   | Erstellt neue Baustellen und legt Projektordner an.      |
| `Backup-Monitor.ps1`  | Überwacht und prüft Backups.                             |
| `Update-Vorlagen.ps1` | Aktualisiert Vorlagen und Konfigurationsdateien.         |
| `Check-System.ps1`    | System- und Rechteprüfungen (OneDrive, Schreibrechte).   |
| `Manage-Config.ps1`   | Verwaltung und Migration von JSON-Dateien.               |
| `Show-Logs.ps1`       | Anzeige und Filterung von Logdateien.                    |
| `Dev-Tools.ps1`       | Entwicklerfunktionen: Testaufrufe, Debug-Modus, Analyse. |

### 🧱 4. Konfigurationsdateien (Config)

| Datei                   | Zweck                                                              |
| ----------------------- | ------------------------------------------------------------------ |
| `Parameter_Master.json` | Hauptparameter aller Baustellen (Projektliste, Pfade, Systeminfo). |
| `System.json`           | Benutzer- und Rechnerbezogene Systemkonfiguration.                 |
| `Defaults.json`         | Standardwerte für neue Projekte und Backups.                       |

### 🗂️ 5. Geplante Ordnerstruktur

> 💡 Falls du Module nach Kategorien trennen willst, füge Unterordner wie `Menu`, `System`, `Project` unter `Modules` hinzu.

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
│   └── Defaults.json
│
├── 02_Templates\
│   └── (Vorlagen und Systemtemplates)
│
├── 03_Scripts\
│   ├── SiteManager.ps1
│   ├── Modules\
│   │   ├── Menu\
│   │   ├── System\
│   │   ├── Project\
│   │   └── Dev\
│   └── Libs\
│       ├── Lib_Systeminfo.ps1
│       ├── Lib_ListFiles.ps1
│       ├── Lib_Debug.ps1
│       ├── Lib_Json.ps1
│       └── (weitere Libs)
│
├── 04_Logs\
│   ├── Fehler_Log.txt
│   ├── System_Log.txt
│   └── Debug_Log.txt
│
└── 05_Backup\
    ├── Parameter_Master_YYYY-MM-DD.json
    ├── Templates_Versionen\
    └── Config_Backups\
```

### 🧩 6. Manifeste & Projektdateien

| Datei                | Zweck                                                         |
| -------------------- | ------------------------------------------------------------- |
| `SiteManager.psd1`   | PowerShell Modul-Manifest – beschreibt das gesamte Framework. |
| `README.md`          | Dokumentation des Projekts.                                   |
| `Changelog.txt`      | Versionsverlauf und Änderungsnotizen.                         |
| `Developer_Notes.md` | Technische Notizen, To-Dos, Erweiterungsideen.                |

### 🧭 7. Menüstruktur (Lib_Menu)

**Hauptmenü:** Neue Baustelle, Vorlagen aktualisieren, Backup prüfen, Logs anzeigen, Entwickler-Tools, Beenden.
**Untermenüs:** Baustellenverwaltung, System, Entwickler.

### 🧾 8. Logs & Backups

| Ordner      | Zweck                                                   |
| ----------- | ------------------------------------------------------- |
| `04_Logs`   | Fehler-, Debug- und Systemlogs pro Modul.               |
| `05_Backup` | Automatische Sicherungen (Parameterdateien, Templates). |

---

## ⚙️ Versionierung

* **Hauptmodul:** `SM_Vx.y.z`
* **Module:** `MOD_Vx.y.z`
* **Libraries:** `LIB_Vx.y.z`

> Jede Datei trägt ihre eigene Versionsnummer im Kopfkommentar.

---

## 🧰 Nächste Aufgaben / TODO

* [ ] Manifest `SiteManager.psd1` erstellen
* [ ] `Lib_Menu.ps1` implementieren (mehrstufig, kommentiert)
* [ ] Hauptmenü in `SiteManager.ps1` integrieren
* [ ] JSON-Validierung testen (`Lib_Json.ps1`)
* [ ] Debug-Log-Format finalisieren
* [ ] Erste Modultests (Add-Baustelle, Backup-Monitor)

---

## 🧩 Commit-Standard

```text
🧩 Commit – [Datum] – [Version]
• [Kurzbeschreibung der Änderungen]
• [Neue/aktualisierte Dateien]
• [Relevante Hinweise]
```

---

# 🧭 Git & VS Code Workflow (Stand 2025)

## 📘 Ziel

Dieser Abschnitt beschreibt den empfohlenen **Git- und VS-Code-Workflow** für das Projekt **Site Manager**. Er stellt sicher, dass alle Änderungen sauber versioniert, nachvollziehbar dokumentiert und konfliktfrei zwischen Geräten oder Entwicklern synchronisiert werden.

### 🌿 Branch-Strategie

| Branch-Typ  | Zweck             | Beispiel          |
| ----------- | ----------------- | ----------------- |
| `main`      | stabile Version   | `main`            |
| `dev`       | Entwicklungszweig | `dev`             |
| `feature-*` | neue Funktion     | `feature-menu`    |
| `bugfix-*`  | Fehlerbehebung    | `bugfix-jsonload` |
| `release-*` | stabile Version   | `release-v1.1.0`  |
| `hotfix-*`  | schneller Fix     | `hotfix-logging`  |

**Regeln:**

* Nicht direkt in `main` entwickeln.
* Neue Funktionen → eigener `feature-` Branch.
* Nach Fertigstellung → Merge in `dev`, später in `main`.
* Alte Branches nach Merge löschen (`git branch -d feature-xyz`).

### 🧩 Commit-Regeln

Strukturierter Commit-Text:

```text
🧩 Commit – [Datum] – [Version]
• [Kurzbeschreibung der Änderungen]
• [Neue/aktualisierte Dateien]
• [Relevante Hinweise]
```

**Beispiel:**

```text
🧩 Commit – 2025-10-22 – LIB_V1.0.0
• Add dynamic menu system (Lib_Menu.ps1)
• Improve debug output
• Fix missing log path in Lib_Debug
```

### ⚙️ Synchronisation mit GitHub

Grundregel: Immer zuerst `pull`, dann `push`.

```bash
git pull
git add .
git commit -m "🧩 Commit – ..."
git push
```

### 🧱 Merge-Konflikte lösen

Wenn Git Konflikte meldet, öffnet VS Code die betroffenen Dateien. Wähle:

* ✅ *Accept Current Change*
* ⬇️ *Accept Incoming Change*
* 🔀 *Accept Both Changes*

Danach:

```bash
git add .
git commit -m "Merge conflict resolved"
```

### 🧰 Nützliche Git-Befehle

| Befehl                        | Zweck                                 |
| ----------------------------- | ------------------------------------- |
| `git branch`                  | Zeigt Branches an                     |
| `git checkout -b <name>`      | Neuer Branch                          |
| `git merge <name>`            | Branch zusammenführen                 |
| `git status`                  | Änderungen anzeigen                   |
| `git diff`                    | Unterschiede anzeigen                 |
| `git log --oneline --graph`   | Verlauf grafisch                      |
| `git restore <Datei>`         | Änderung rückgängig                   |
| `git reset --soft HEAD~1`     | Letzten Commit rückgängig             |
| `git stash` / `git stash pop` | Temporär speichern & wiederherstellen |

### 🧹 Repository-Hygiene

* `.gitignore` regelmäßig prüfen.
* Alte Branches löschen.
* `Changelog.txt` sauber führen.

### 🚀 Erweiterte Techniken

* **Tags für Releases:**

```bash
git tag -a v1.0.0 -m "Stable release"
git push origin v1.0.0
```

* **GitHub Issues** für To-Dos.
* **Regelmäßige Backups.**
* **GitLens in VS Code:** Historie im Editor.

### 🧾 Standard-Ablauf

| Schritt | Befehl                                        | Beschreibung            |
| ------- | --------------------------------------------- | ----------------------- |
| 1       | `git pull`                                    | Änderungen holen        |
| 2       | `git checkout -b feature-xyz`                 | Neuen Branch erstellen  |
| 3       | (Ändern & Testen)                             | Entwicklung durchführen |
| 4       | `git add .`                                   | Änderungen vormerken    |
| 5       | `git commit -m "🧩 Commit – ..."`             | Commit erstellen        |
| 6       | `git push -u origin feature-xyz`              | Branch hochladen        |
| 7       | `git checkout main` / `git merge feature-xyz` | Zusammenführen          |
| 8       | `git branch -d feature-xyz`                   | Branch löschen          |

---

🧩 **Stand:**  21.10.2025
📁 **Version:** DOC_V1.0.0
✍️ **Autor:** Herbert Schrotter