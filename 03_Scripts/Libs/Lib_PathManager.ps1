# ============================================================
# Library: Lib_PathManager.ps1
# Version: LIB_V1.1.0
# Zweck:   Ermittelt, verwaltet und registriert Systempfade sowie erkannte Systeme im Site Manager Framework
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Get-ProjectRoot, Get-PathMap, Get-PathConfig, Get-PathLogs, Get-PathBackup, Get-PathTemplates, Register-System, Get-ActiveSystem
#   Description: Erkennt automatisch den Site Manager Root-Ordner, verwaltet Systempfade und erkennt Benutzer/Computer für Multi-System-Betrieb
#   Category: Core
#   Tags: Path, Root, Structure, Framework, MultiSystem
#   Dependencies: (none)
# ============================================================


# ------------------------------------------------------------
# 🧭 Funktion: Get-ProjectRoot
# Zweck:
#   Findet den obersten Ordner des Site Managers anhand der typischen Struktur.
# Rückgabe:
#   Vollständiger Pfad des Root-Verzeichnisses oder $null bei Fehler.
# ------------------------------------------------------------
function Get-ProjectRoot {
    param([string]$StartPath = $PSScriptRoot)

    try {
        $current = Resolve-Path $StartPath -ErrorAction Stop
        while ($current -and -not (Test-Path (Join-Path $current "01_Config"))) {
            $parent = Split-Path $current
            if ($parent -eq $current) { return $null }  # Root erreicht
            $current = $parent
        }
        return $current
    }
    catch {
        Write-Host "❌ Fehler beim Ermitteln des Projekt-Roots: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ------------------------------------------------------------
# 📁 Funktion: Get-PathMap
# Zweck:
#   Gibt ein Objekt mit allen relevanten Pfaden zurück.
# Rückgabe:
#   PSCustomObject mit Root-, Config-, Template-, Log- und Backup-Pfaden.
# ------------------------------------------------------------
function Get-PathMap {
    $root = Get-ProjectRoot
    if (-not $root) { throw "❌ Projekt-Root konnte nicht erkannt werden." }

    return [PSCustomObject]@{
        Root       = $root
        Config     = Join-Path $root "01_Config"
        Templates  = Join-Path $root "02_Templates"
        Scripts    = Join-Path $root "03_Scripts"
        Logs       = Join-Path $root "04_Logs"
        Backup     = Join-Path $root "05_Backup"
    }
}

# ------------------------------------------------------------
# 🔧 Hilfsfunktionen für gezielten Zugriff
# ------------------------------------------------------------
function Get-PathConfig    { (Get-PathMap).Config }
function Get-PathLogs      { (Get-PathMap).Logs }
function Get-PathBackup    { (Get-PathMap).Backup }
function Get-PathTemplates { (Get-PathMap).Templates }


# ------------------------------------------------------------
# 🧠 Multi-System-Erkennung & Config-Verwaltung
# ------------------------------------------------------------
function Register-System {
    try {
        $pathMap    = Get-PathMap
        $configPath = Join-Path $pathMap.Config "PathManager_Config.json"

        # Aktuelles System
        $user     = $env:USERNAME
        $computer = $env:COMPUTERNAME
        $root     = $pathMap.Root

        # Standardstruktur der Config
        $defaultConfig = @{
            Version      = "CFG_V1.0.0"
            Systeme      = @()
            StandardRoot = $root
        }

        # Datei anlegen, falls nicht vorhanden
        if (-not (Test-Path $configPath)) {
            Write-Host "⚙️  PathManager_Config.json nicht gefunden – wird neu erstellt." -ForegroundColor Yellow
            $defaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding utf8 -Force
        }

        # Config laden
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $exists = $config.Systeme | Where-Object { $_.Benutzer -eq $user -and $_.Computer -eq $computer }

        # Neues System registrieren, falls nicht vorhanden
        if (-not $exists) {
            Write-Host "➕ Neues System erkannt: $user@$computer" -ForegroundColor Green
            $newEntry = [PSCustomObject]@{
                Benutzer        = $user
                Computer        = $computer
                Root            = $root
                LetzteErkennung = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }

            $config.Systeme += $newEntry
            $config | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding utf8 -Force
        }
        else {
            # Zeitstempel aktualisieren
            $exists.LetzteErkennung = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $config | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding utf8 -Force
        }

        return $config
    }
    catch {
        Write-Host "❌ Fehler bei Register-System: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ------------------------------------------------------------
# 🔍 Funktion: Get-ActiveSystem
# Zweck:
#   Gibt den aktuell erkannten Systemeintrag aus PathManager_Config.json zurück.
# ------------------------------------------------------------
function Get-ActiveSystem {
    try {
        $pathMap    = Get-PathMap
        $configPath = Join-Path $pathMap.Config "PathManager_Config.json"

        if (-not (Test-Path $configPath)) {
            Write-Host "⚠️  PathManager_Config.json nicht gefunden – führe Register-System aus." -ForegroundColor Yellow
            Register-System | Out-Null
        }

        $config   = Get-Content $configPath -Raw | ConvertFrom-Json
        $user     = $env:USERNAME
        $computer = $env:COMPUTERNAME

        $system = $config.Systeme | Where-Object { $_.Benutzer -eq $user -and $_.Computer -eq $computer }

        if (-not $system) {
            Write-Host "⚠️  Kein Eintrag für aktuelles System gefunden – registriere neu." -ForegroundColor Yellow
            Register-System | Out-Null
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $system = $config.Systeme | Where-Object { $_.Benutzer -eq $user -and $_.Computer -eq $computer }
        }

        return $system
    }
    catch {
        Write-Host "❌ Fehler bei Get-ActiveSystem: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}


# ------------------------------------------------------------
# 🧩 Initialisierung beim Laden
# ------------------------------------------------------------
try {
    $system = Get-ActiveSystem
    if ($system) {
        Write-Host "✅ Aktives System erkannt: $($system.Benutzer)@$($system.Computer)" -ForegroundColor DarkGray
        Write-Host "📁 Root: $($system.Root)" -ForegroundColor DarkGray
    }
    else {
        Write-Host "⚠️ Kein System erkannt – PathManager arbeitet im Fallback-Modus." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️ PathManager konnte beim Laden kein System registrieren: $($_.Exception.Message)" -ForegroundColor Yellow
}
