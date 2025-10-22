# ============================================================
# Library: Lib_Menu.ps1
# Version: LIB_V1.6.0
# Zweck:   Menüsystem mit Navigation, Stack-Verwaltung & zentralem Logging (Lib_Log)
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Show-SubMenu, Write-MenuLog, Push-MenuStack, Pop-MenuStack, Get-CurrentMenuPath
#   Description: Menüsystem für den Site Manager mit zentralem Logging über Lib_Log.ps1.
#   Category: Core
#   Tags: Menu, Framework, SiteManager, Logging
#   Dependencies: Lib_PathManager.ps1, Lib_Log.ps1
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
# 🔹 Menü-Konfiguration laden (nur Anzeige & Verhalten)
# ------------------------------------------------------------
try {
    $configPath = Join-Path $pathMap.Config "Menu_Config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Menu_Config.json nicht gefunden – erstelle Standard-Konfiguration ..." -ForegroundColor Yellow

        $defaultConfig = @{
            Version = "CFG_V1.1.0"
            Menu    = @{
                ShowPath     = $false
                ColorScheme  = @{
                    Title     = "White"
                    Highlight = "Cyan"
                    Error     = "Red"
                }
            }
        }

        $defaultConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $configPath -Encoding UTF8
        $menuConfig = $defaultConfig.Menu
    }
    else {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $menuConfig = $config.Menu
        Write-Host "✅ Menu_Config.json geladen." -ForegroundColor Green
    }

    # Fallbacks falls Parameter fehlen
    if (-not $menuConfig.ShowPath) { $menuConfig.ShowPath = $false }
    if (-not $menuConfig.ColorScheme) {
        $menuConfig.ColorScheme = @{
            Title     = "White"
            Highlight = "Cyan"
            Error     = "Red"
        }
    }
}
catch {
    Write-Host "⚠️ Fehler beim Laden der Menu_Config.json: $_" -ForegroundColor Yellow
    $menuConfig = @{
        ShowPath = $false
        ColorScheme = @{
            Title     = "White"
            Highlight = "Cyan"
            Error     = "Red"
        }
    }
}

# ------------------------------------------------------------
# 🔹 Zentrales Logging über Lib_Log.ps1
# ------------------------------------------------------------
try {
    $libLog = "$PSScriptRoot\Lib_Log.ps1"
    if (-not (Test-Path $libLog)) {
        $libLog = "$PSScriptRoot\..\Libs\Lib_Log.ps1"
    }

    if (Test-Path $libLog) {
        . $libLog
        Load-LogConfig
        Initialize-LogSession -ModuleName "MenuSystem"
        Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message "Menüsystem gestartet."
    }
    else {
        Write-Host "⚠️ Lib_Log.ps1 nicht gefunden – Menülogging deaktiviert." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️ Fehler beim Laden von Lib_Log.ps1: $_" -ForegroundColor Yellow
}

# ------------------------------------------------------------
# 🔹 Menüstack initialisieren
# ------------------------------------------------------------
if (-not $global:MenuStack) { $global:MenuStack = @() }

# ------------------------------------------------------------
# 🔹 Logging-Wrapper & Stack-Funktionen
# ------------------------------------------------------------
function Write-MenuLog {
    param(
        [string]$MenuTitle,
        [string]$Selection,
        [string]$Action
    )

    try {
        $msg = "Menü: $MenuTitle | Auswahl: $Selection | Aktion: $Action"
        Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message $msg
    }
    catch {
        Write-Host "❌ Fehler beim Menülogging: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Push-MenuStack {
    param([string]$Title)
    $global:MenuStack += $Title
    Write-FrameworkLog -Module "MenuSystem" -Level DEBUG -Message "Stack PUSH → $Title"
}

function Pop-MenuStack {
    if ($global:MenuStack.Count -gt 0) {
        $removed = $global:MenuStack[-1]
        $global:MenuStack = $global:MenuStack[0..($global:MenuStack.Count - 2)]
        Write-FrameworkLog -Module "MenuSystem" -Level DEBUG -Message "Stack POP ← $removed"
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
            Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message "Programm beendet."
            Close-LogSession -ModuleName "MenuSystem"
            Write-Host "`nProgramm wird beendet ..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            exit
        }

        # Zurück
        if ($choice -match '^(b|B)$') {
            Pop-MenuStack
            Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message "Zurück aus Menü: $MenuTitle"
            return "0"
        }

        # Auswahl ausführen
        if ($Options.ContainsKey($choice)) {
            $action = $Options[$choice].Split('|')[1]

            try {
                Write-FrameworkLog -Module "MenuSystem" -Level INFO -Message "Auswahl $choice → Aktion: $action"
                Invoke-Expression $action
            }
            catch {
                Write-Host "Fehler beim Ausführen von '$action': $($_.Exception.Message)" -ForegroundColor $menuConfig.ColorScheme.Error
                Write-FrameworkLog -Module "MenuSystem" -Level ERROR -Message "Fehler bei Auswahl $choice → $($_.Exception.Message)"
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
