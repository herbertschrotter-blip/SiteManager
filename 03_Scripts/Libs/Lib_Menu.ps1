# ============================================================
# Library: Lib_Menu.ps1
# Version: LIB_V1.5.2
# Zweck:   Menüsystem mit Navigation, Logging, Stack-Verwaltung & PathManager-Unterstützung
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Show-SubMenu, Write-MenuLog, Push-MenuStack, Pop-MenuStack, Get-CurrentMenuPath
#   Description: Zentrale Menüsteuerung des Site Managers mit Logging, Rückkehrfunktion und Pfadanzeige.
#   Category: Core
#   Tags: Menu, Logging, Framework, SiteManager
#   Dependencies: Lib_PathManager.ps1
# ============================================================


# ------------------------------------------------------------
# 🔹 PathManager-Integration
# ------------------------------------------------------------
try {
    $pathManagerPath = "$PSScriptRoot\Lib_PathManager.ps1"
    if (-not (Test-Path $pathManagerPath)) {
        $pathManagerPath = "$PSScriptRoot\..\Libs\Lib_PathManager.ps1"
    }

    if (Test-Path $pathManagerPath) {
        . $pathManagerPath
        $pathMap = Get-PathMap
        Write-Host "✅ PathManager geladen – dynamische Pfade aktiviert." -ForegroundColor Green
    }
    else {
        throw "Lib_PathManager.ps1 nicht gefunden – Fallback auf lokale Pfade."
    }
}
catch {
    Write-Host "⚠️ PathManager nicht verfügbar, verwende Standardpfade." -ForegroundColor Yellow
    $pathMap = @{
        Config = "$PSScriptRoot\..\..\01_Config"
        Logs   = "$PSScriptRoot\..\..\04_Logs"
    }
}

# ------------------------------------------------------------
# 🔹 Parameterdatei prüfen oder neu anlegen
# ------------------------------------------------------------
$configPath = Join-Path $pathMap.Config "Menu_Config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "Parameterdatei nicht gefunden. Erstelle Standard-Konfiguration ..." -ForegroundColor Yellow

    $defaultConfig = @{
        Version = "CFG_V1.0.0"
        Menu    = @{
            ShowPath          = $false
            MaxLogFiles       = 10
            LogFilePrefix     = "Menu_Log_"
            LogDateFormat     = "yyyy-MM-dd_HHmm"
            LogRetentionDays  = 30
            ColorScheme       = @{
                Title     = "White"
                Highlight = "Cyan"
                Error     = "Red"
            }
        }
    }

    $json = $defaultConfig | ConvertTo-Json -Depth 4
    if (-not (Test-Path $pathMap.Config)) {
        New-Item -Path $pathMap.Config -ItemType Directory -Force | Out-Null
    }
    $json | Out-File -FilePath $configPath -Encoding UTF8

    Write-Host "Standard-Konfiguration erstellt unter: $configPath" -ForegroundColor Green
}

# ------------------------------------------------------------
# 🔹 Parameterdatei laden
# ------------------------------------------------------------
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $menuConfig = $config.Menu
}
catch {
    Write-Host "Fehler beim Laden der Menu_Config.json: $($_.Exception.Message)" -ForegroundColor Red
    $menuConfig = @{}
}

# Standardwerte (Fallback bei fehlenden Parametern)
if (-not $menuConfig.MaxLogFiles) { $menuConfig.MaxLogFiles = 10 }
if (-not $menuConfig.ShowPath) { $menuConfig.ShowPath = $false }
if (-not $menuConfig.LogFilePrefix) { $menuConfig.LogFilePrefix = "Menu_Log_" }
if (-not $menuConfig.LogDateFormat) { $menuConfig.LogDateFormat = "yyyy-MM-dd_HHmm" }
if (-not $menuConfig.LogRetentionDays) { $menuConfig.LogRetentionDays = 30 }
if (-not $menuConfig.ColorScheme) {
    $menuConfig.ColorScheme = @{
        Title     = "White"
        Highlight = "Cyan"
        Error     = "Red"
    }
}

# ------------------------------------------------------------
# 🔹 Log-Initialisierung (mit Parametern aus Config)
# ------------------------------------------------------------
$logDir = $pathMap.Logs
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

$timestamp = (Get-Date).ToString($menuConfig.LogDateFormat)
$global:MenuLogPath = Join-Path $logDir ("{0}{1}.txt" -f $menuConfig.LogFilePrefix, $timestamp)

# Alte Logs bereinigen (max. Anzahl oder Alter)
$logFiles = Get-ChildItem -Path $logDir -Filter "$($menuConfig.LogFilePrefix)*.txt" | Sort-Object LastWriteTime -Descending

# Nur die letzten N behalten
if ($logFiles.Count -gt $menuConfig.MaxLogFiles) {
    $oldLogs = $logFiles | Select-Object -Skip $menuConfig.MaxLogFiles
    foreach ($log in $oldLogs) {
        try { Remove-Item $log.FullName -Force } catch {}
    }
}

# Optional: Alte Logs nach Tagen löschen
if ($menuConfig.LogRetentionDays -gt 0) {
    $cutoff = (Get-Date).AddDays(-$menuConfig.LogRetentionDays)
    $expired = $logFiles | Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($log in $expired) {
        try { Remove-Item $log.FullName -Force } catch {}
    }
}

# ------------------------------------------------------------
# 🔹 Menüstack initialisieren
# ------------------------------------------------------------
if (-not $global:MenuStack) { $global:MenuStack = @() }

# ------------------------------------------------------------
# 🔹 Sitzungsstart markieren (nur einmal pro Lauf)
# ------------------------------------------------------------
if (-not $global:MenuSessionStarted) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $sessionHeader = "--------------------------------------------`n[{0}] Neue Menü-Session gestartet`n--------------------------------------------" -f $timestamp
    Add-Content -Path $global:MenuLogPath -Value $sessionHeader
    $global:MenuSessionStarted = $true
}

# ------------------------------------------------------------
# 🔹 Hilfsfunktionen: Logging & Stack
# ------------------------------------------------------------
function Write-MenuLog {
    param(
        [string]$MenuTitle,
        [string]$Selection,
        [string]$Action
    )

    try {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $logEntry = "[{0}] Menü: {1} | Auswahl: {2} | Aktion: {3}" -f $timestamp, $MenuTitle, $Selection, $Action
        Add-Content -Path $global:MenuLogPath -Value $logEntry
    }
    catch {
        Write-Host "Fehler beim Schreiben des Menülogs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Push-MenuStack {
    param([string]$Title)
    $global:MenuStack += $Title
}

function Pop-MenuStack {
    if ($global:MenuStack.Count -gt 0) {
        $global:MenuStack = $global:MenuStack[0..($global:MenuStack.Count - 2)]
    }
}

function Get-CurrentMenuPath {
    if ($global:MenuStack.Count -eq 0) { return "[ROOT]" }
    return ($global:MenuStack -join " -> ")
}

# ------------------------------------------------------------
# 🔹 Hauptfunktion: Show-SubMenu
# ------------------------------------------------------------
function Show-SubMenu {
    param(
        [Parameter(Mandatory)][string]$MenuTitle,
        [Parameter(Mandatory)][hashtable]$Options,
        [switch]$ReturnAfterAction
    )

    # Stack aktualisieren
    Push-MenuStack -Title $MenuTitle

    # Hauptmenü-Schleife
    while ($true) {
        Clear-Host
        $menuPath = Get-CurrentMenuPath

        Write-Host "=============================================" -ForegroundColor $menuConfig.ColorScheme.Title
        Write-Host ("        " + ($MenuTitle -replace '^\s+', '')) -ForegroundColor $menuConfig.ColorScheme.Title
        Write-Host "=============================================" -ForegroundColor $menuConfig.ColorScheme.Title

        # Pfadanzeige optional
        if ($menuConfig.ShowPath -and $menuPath -ne "[ROOT]") {
            Write-Host ("Pfad: " + $menuPath) -ForegroundColor DarkGray
        }

        foreach ($key in ($Options.Keys | Sort-Object {
            if ($_ -match '^\d+$') { [int]$_ } else { $_ }
        })) {
            Write-Host "$key - $($Options[$key].Split('|')[0])" -ForegroundColor $menuConfig.ColorScheme.Highlight
        }

        Write-Host "`nB - Zurück zum vorherigen Menü" -ForegroundColor $menuConfig.ColorScheme.Title
        Write-Host "X - Komplett beenden" -ForegroundColor $menuConfig.ColorScheme.Title
        Write-Host ""

        $choice = Read-Host "Bitte Auswahl eingeben"

        # Beenden
        if ($choice -match '^(x|X)$') {
            Write-Host "`nProgramm wird beendet ..." -ForegroundColor Yellow
            Write-MenuLog -MenuTitle $MenuTitle -Selection "X" -Action "Programm beendet"
            Start-Sleep -Seconds 1
            exit
        }

        # Zurück
        if ($choice -match '^(b|B)$') {
            Pop-MenuStack
            Write-MenuLog -MenuTitle $MenuTitle -Selection "B" -Action "Zurück"
            return "0"
        }

        # Auswahl ausführen
        if ($Options.ContainsKey($choice)) {
            $action = $Options[$choice].Split('|')[1]

            try {
                Write-MenuLog -MenuTitle $MenuTitle -Selection $choice -Action $action
                Invoke-Expression $action
            }
            catch {
                Write-Host "Fehler beim Ausführen von '$action': $($_.Exception.Message)" -ForegroundColor $menuConfig.ColorScheme.Error
                Write-MenuLog -MenuTitle $MenuTitle -Selection $choice -Action "Fehler: $($_.Exception.Message)"
            }

            Pause
            if ($ReturnAfterAction) {
                Pop-MenuStack
                return $choice
            }
        }
        else {
            Write-Host "Ungültige Eingabe. Bitte erneut versuchen." -ForegroundColor $menuConfig.ColorScheme.Error
            Start-Sleep 1
        }
    }
}
