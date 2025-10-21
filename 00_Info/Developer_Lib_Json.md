# 🧠 Developer Notes – Lib_Json.ps1

---

## 📘 Überblick

**Modulname:** `Lib_Json.ps1`
**Aktuelle Version:** `LIB_V1.4.0`
**Zweck:** Universelle JSON-Verwaltung mit optionaler PathManager-Integration, konfigurierbarem Verhalten und automatischer Erstellung einer Standardkonfiguration.

---

## 🧩 Kernfunktionen

| Funktion           | Beschreibung                                                                                 |
| ------------------ | -------------------------------------------------------------------------------------------- |
| `Get-JsonFile`     | Liest JSON-Datei und gibt Objekt zurück. Optional mit automatischer Erstellung leerer Datei. |
| `Save-JsonFile`    | Schreibt Daten als JSON (UTF8, OneDrive-kompatibel) mit Warteprüfung.                        |
| `Add-JsonEntry`    | Fügt Datensätze zu einer JSON-Datei hinzu (Array-basiert).                                   |
| `Update-JsonValue` | Aktualisiert gezielt einen Key-Value-Paar-Eintrag in JSON.                                   |
| `Remove-JsonEntry` | Entfernt Einträge aus JSON-Arrays anhand eines Feldwerts.                                    |

---

## ⚙️ Architektur

### 🔹 PathManager-Integration (optional)

* Wird beim Laden automatisch eingebunden, falls `Lib_PathManager.ps1` existiert.
* Pfade wie `01_Config` und `04_Logs` werden dynamisch erkannt.
* Fallback auf lokale Pfade, falls PathManager fehlt.

### 🔹 Config-Verwaltung

* **Config-Datei:** `Json_Config.json`
* **Speicherort:** automatisch unter `01_Config` (oder lokal neben der Lib)
* **Auto-Erstellung:** Wenn keine Datei vorhanden, wird eine Standardversion erzeugt:

  ```json
  {
    "CreateIfMissing": true,
    "WaitTimeMs": 200,
    "WaitLoopMax": 10,
    "DefaultDepth": 8,
    "EnableLogging": false,
    "LogFile": "04_Logs\\Json_Log.txt"
  }
  ```

### 🔹 Standardwerte (Fallback)

Falls Config defekt oder nicht lesbar → Standardwerte aktiv.
Die Datei wird automatisch neu angelegt.

### 🔹 Logging

* Optional, über `EnableLogging` steuerbar.
* Schreibt bei Aktivierung Einträge wie:

  ```
  [2025-10-22 20:15:30] WRITE → D:\...\Json_Test.json
  ```

### 🔹 OneDrive-Kompatibilität

* Schreibvorgänge werden mit Verzögerung geprüft (`WaitTimeMs`, `WaitLoopMax`).
* Dadurch kein Race-Condition-Fehler bei Cloud-Sync-Verzeichnissen.

---

## 🧠 Technische Details

### 🔸 Schreibsicherheit

```powershell
$Data | ConvertTo-Json -Depth $JsonConfig.DefaultDepth | Out-File -FilePath $Path -Encoding utf8 -Force
$maxWait = $JsonConfig.WaitLoopMax
while (-not (Test-Path $Path) -and $maxWait -gt 0) {
    Start-Sleep -Milliseconds $JsonConfig.WaitTimeMs
    $maxWait--
}
```

→ Verhindert Timing-Fehler durch OneDrive-/NTFS-Verzögerungen.

### 🔸 Konfigurationsinitialisierung

```powershell
if (-not (Test-Path $defaultConfigPath)) {
    $DefaultJsonConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $defaultConfigPath -Encoding utf8
}
```

→ Erstellt automatisch eine gültige Config, falls keine existiert.

### 🔸 Fehlertoleranz

* Alle Hauptfunktionen sind in `try/catch`-Blöcken eingebettet.
* Fehler werden farbig im Terminal ausgegeben, nicht geworfen.
* Rückgabe immer kontrolliert (`@()` bei Fehlschlag).

---

## 🧰 Entwicklungs- und Teststrategie

### 🔹 Testmodul: `Test-LibJson.ps1`

* Aktuelle Version: `DEV_V1.6.0`
* Getrennte, interaktive Tests mit RAW-Ausgabe und Abbruchfunktion.
* Vollsuite mit 9 Haupttests:

  1. Datei erstellen
  2. Datei lesen
  3. Dummy löschen
  4. Eintrag hinzufügen
  5. Wert aktualisieren
  6. Roundtrip-Integrität
  7. Fehlerhafte Datei
  8. Auto-Erstellung bei Fehlpfad
  9. Performance-Test (100 Schreibvorgänge)

### 🔹 Besonderheiten im Test

* `Check-Abort` erlaubt Abbruch mit `q`
* `Show-Raw` zeigt aktuellen JSON-Inhalt farbig an
* `Start-Sleep`-Delays vermeiden Race-Conditions bei Cloud-Dateien

---

## 🚀 Geplante Erweiterungen

| Version | Feature              | Beschreibung                                         |
| ------- | -------------------- | ---------------------------------------------------- |
| V1.5.0  | Backup-Unterstützung | Automatische Sicherung alter JSONs vor Überschreiben |
| V1.6.0  | Transaktionslog      | Erfasst alle Änderungen mit Timestamp und Quelle     |
| V1.7.0  | ErrorReport.json     | Speichert JSON-bezogene Fehler zentral ab            |
| V2.0.0  | Multi-File-Support   | Verarbeitung mehrerer JSON-Dateien parallel          |

---

## 📦 Commit-Historie

| Datum      | Version | Änderungen                                                  |
| ---------- | ------- | ----------------------------------------------------------- |
| 2025-10-22 | V1.1.0  | Integration PathManager, auto Fallback, Logging vorbereitet |
| 2025-10-22 | V1.2.0  | Warte-Loop für OneDrive implementiert                       |
| 2025-10-22 | V1.3.0  | Konfigurationsdatei Json_Config.json integriert             |
| 2025-10-23 | V1.4.0  | Auto-Erstellung der Standardkonfig + Merge mit UserConfig   |

---

📘 **Status:** Stabil – Einsatzbereit im Framework (Core-Layer)

🧩 **Getestet mit:** `Test-LibJson.ps1` (DEV_V1.6.0)

---
