# ============================================================
# 🧩 Library: Lib_PathManager.ps1
# Version: LIB_V1.2.4
# Zweck:   Dynamischer Pfadmanager mit Multi-System-Erkennung,
#          konfigurierbarer Ordnerstruktur und rekursiver Unterordner-Erkennung.
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧩 ManifestHint:
#   ExportFunctions: Get-ProjectRoot, Get-PathMap, Get-PathConfig, Get-PathLogs, Get-PathBackup, Get-PathTemplates, Register-System, Get-ActiveSystem, Get-PathSubDirs
#   Description: Erkennt Projektstruktur, Systeme und liefert rekursiv alle Unterordner über Get-PathSubDirs.
#   Category: Core
#   Tags: Path, Root, Structure, Framework, MultiSystem, Dynamic, Recursive
#   Dependencies: (none)
# ============================================================


# ------------------------------------------------------------
# 🧭 Funktion: Get-ProjectRoot
# ------------------------------------------------------------
function Get-ProjectRoot {
    param([string]$StartPath = $PSScriptRoot)
    try {
        $current = Resolve-Path $StartPath -ErrorAction Stop
        while ($current -and -not (Test-Path (Join-Path $current "01_Config"))) {
            $parent = Split-Path $current
            if ($parent -eq $current) { return $null }
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
# 📁 Funktion: Get-PathMap (Dynamic Mode)
# ------------------------------------------------------------
function Get-PathMap {
    $root = Get-ProjectRoot
    if (-not $root) { throw "❌ Projekt-Root konnte nicht erkannt werden." }

    $configFile = Join-Path $root "01_Config\\PathManager_Config.json"

    # Fallback-Standardstruktur
    $defaultDirs = @{
        Config    = "01_Config"
        Templates = "02_Templates"
        Scripts   = "03_Scripts"
        Logs      = "04_Logs"
        Backup    = "05_Backup"
    }

    if (Test-Path $configFile) {
        try {
            $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
            if ($cfg.Ordnerstruktur) {
                $dirs = $cfg.Ordnerstruktur
                Write-Host "📁 Dynamische Ordnerstruktur erkannt (aus Config)." -ForegroundColor DarkGray
            }
            else {
                $dirs = $defaultDirs
            }
        }
        catch {
            Write-Host "⚠️ Fehler beim Lesen von PathManager_Config.json – verwende Standardstruktur." -ForegroundColor Yellow
            $dirs = $defaultDirs
        }
    }
    else {
        $dirs = $defaultDirs
    }

    return [PSCustomObject]@{
        Root       = $root
        Config     = Join-Path $root $dirs.Config
        Templates  = Join-Path $root $dirs.Templates
        Scripts    = Join-Path $root $dirs.Scripts
        Logs       = Join-Path $root $dirs.Logs
        Backup     = Join-Path $root $dirs.Backup
    }
}


# ------------------------------------------------------------
# 🔧 Hilfsfunktionen (Kurzaufrufe)
# ------------------------------------------------------------
function Get-PathConfig    { (Get-PathMap).Config }
function Get-PathLogs      { (Get-PathMap).Logs }
function Get-PathBackup    { (Get-PathMap).Backup }
function Get-PathTemplates { (Get-PathMap).Templates }

# ------------------------------------------------------------
# 🌲 Funktion: Get-PathSubDirs (neuer API-Endpunkt)
# ------------------------------------------------------------
function Get-PathSubDirs {
    <#
        .SYNOPSIS
        Liefert alle Unterordner eines gegebenen Basispfades rekursiv.

        .PARAMETER BasePath
        Der Pfad, ab dem rekursiv gesucht werden soll (Standard: Scripts).

        .OUTPUTS
        Array von vollständigen Unterordnerpfaden.

        .EXAMPLE
        PS> Get-PathSubDirs -BasePath (Get-PathMap).Scripts
    #>
    param(
        [string]$BasePath = (Get-PathMap).Scripts
    )

    try {
        if (-not (Test-Path $BasePath)) {
            throw "Pfad '$BasePath' nicht gefunden."
        }

        $dirs = Get-ChildItem -Path $BasePath -Directory -Recurse -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName

        Write-Host "📁 $($dirs.Count) Unterordner gefunden unter: $BasePath" -ForegroundColor DarkGray
        return $dirs
    }
    catch {
        Write-Host "❌ Fehler in Get-PathSubDirs: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}



# ------------------------------------------------------------
# 🧠 Multi-System-Erkennung (mit Fix)
# ------------------------------------------------------------
function Register-System {
    try {
        $pathMap    = Get-PathMap
        $configPath = Join-Path $pathMap.Config "PathManager_Config.json"

        $user     = $env:USERNAME
        $computer = $env:COMPUTERNAME
        $root     = $pathMap.Root

        # Neue Config-Struktur mit [ordered] für korrekte Reihenfolge
        $defaultConfig = [ordered]@{
            Version        = "CFG_V1.2.0"
            Ordnerstruktur = [ordered]@{
                Config    = "01_Config"
                Templates = "02_Templates"
                Scripts   = "03_Scripts"
                Logs      = "04_Logs"
                Backup    = "05_Backup"
            }
            Systeme = @()
        }

        # Datei anlegen, falls nicht vorhanden
        if (-not (Test-Path $configPath)) {
            Write-Host "⚙️  PathManager_Config.json nicht gefunden – wird neu erstellt." -ForegroundColor Yellow
            $defaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding utf8 -Force
        }

        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $exists = $config.Systeme | Where-Object { $_.Benutzer -eq $user -and $_.Computer -eq $computer }

        # ✅ Korrektur: nur hinzufügen, wenn kein Eintrag existiert
        if ($null -eq $exists -or $exists.Count -eq 0) {
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
            $exists.LetzteErkennung = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $config | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding utf8 -Force
            Write-Host "ℹ️ System bereits registriert → Zeitstempel aktualisiert." -ForegroundColor DarkGray
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
# ------------------------------------------------------------
function Get-ActiveSystem {
    try {
        $pathMap    = Get-PathMap
        $configPath = Join-Path $pathMap.Config "PathManager_Config.json"
        if (-not (Test-Path $configPath)) { Register-System | Out-Null }

        $config   = Get-Content $configPath -Raw | ConvertFrom-Json
        $user     = $env:USERNAME
        $computer = $env:COMPUTERNAME

        $system = $config.Systeme | Where-Object { $_.Benutzer -eq $user -and $_.Computer -eq $computer }
        if ($null -eq $system -or $system.Count -eq 0) {
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
