# 🏗️ SITE MANAGER – Projektbeschreibung

---

## 📘 Überblick

**Site Manager** ist ein modulares PowerShell-Framework zur Verwaltung, Pflege und Automatisierung von Baustellenprojekten. Das Projekt bildet die zentrale Steuerzentrale für alle zugehörigen Tools, Module, Konfigurationen und Systemfunktionen.

Es wurde entwickelt, um die wiederkehrenden administrativen und organisatorischen Aufgaben auf Baustellen effizient zu automatisieren und standardisieren – von der Projekterstellung über Backups bis hin zur Log- und Vorlagenverwaltung.

---

## 🎯 Ziele

* Einheitliche Struktur und Automatisierung für alle Baustellenprojekte.
* Zentrale Steuerung aller Tools und Module über ein Hauptmenü.
* Konsistente JSON-basierte Konfiguration für maximale Kompatibilität.
* Automatische Erstellung, Pflege und Sicherung von Projektdaten.
* Modularer Aufbau zur einfachen Erweiterung durch Libraries und Module.

---

## ⚙️ Kernfunktionen

| Kategorie                     | Beschreibung                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------- |
| 🧠 **Hauptmodul**             | `SiteManager.ps1` – Startpunkt, Menüsystem, Debug-Modus und Manifeststeuerung.  |
| ⚙️ **Libraries (Lib_*.ps1)**  | Systemweite Bibliotheken für Debug, JSON, Systeminfo, Menüführung u. a.         |
| 🧰 **Module (Modules/*.ps1)** | Funktionale Einheiten wie `Add-Baustelle`, `Backup-Monitor`, `Update-Vorlagen`. |
| 🧱 **Konfiguration**          | JSON-Dateien zur Definition von Systempfaden, Parametern und Standardwerten.    |
| 🧾 **Logs & Backups**         | Automatische Erstellung und Verwaltung von Logdateien und Sicherungen.          |

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
│   └── Defaults.json
│
├── 02_Templates\
│   └── (Vorlagen und Systemtemplates)
│
├── 03_Scripts\
│   ├── SiteManager.ps1
│   ├── Modules\
│   └── Libs\
│
├── 04_Logs\
│   ├── Fehler_Log.txt
│   ├── System_Log.txt
│   └── Debug_Log.txt
│
└── 05_Backup\
    ├── Parameter_Master_YYYY-MM-DD.json
    └── Templates_Versionen\
```

---

## 👨‍💻 Autor & Version

**Autor:** Herbert Schrotter
**Projektstart:** Oktober 2025
**Version:** DOC_V1.0.0
**Stand:** 21.10.2025
