# ============================================================
# Library: Lib_Menu.ps1
# Version: LIB_V1.4.1
# Zweck:   Einheitliche Menüführung mit Rückkehrfunktion, Logging, Menüstack & Untermenü-Erkennung
# Autor:   Herbert Schrotter
# Datum:   21.10.2025
# ============================================================

# ------------------------------------------------------------
# 🔧 Globale Variablen
# ------------------------------------------------------------
if (-not $global:MenuStack) { $global:MenuStack = @() }
$global:MenuLogPath = "$PSScriptRoot\..\..\04_Logs\System_Log.txt"

# ------------------------------------------------------------
# 🧭 Sitzungsstart markieren (nur einmal pro Lauf)
# ------------------------------------------------------------
if (-not $global:MenuSessionStarted) {
    $sessionHeader = "────────────────────────────────────────────`n[{0}] 🧭 Neue Menü-Session gestartet`n────────────────────────────────────────────" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $global:MenuLogPath -Value $sessionHeader
    $global:MenuSessionStarted = $true
}

# ------------------------------------------------------------
# 🔄 Menüstack beim Start der Session zurücksetzen
# ------------------------------------------------------------
if ($global:MenuStack.Count -gt 0) {
    $global:MenuStack = @()
    Add-Content -Path $global:MenuLogPath -Value "[{0}] 🔄 Menüstack zurückgesetzt (neue Sitzung)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

# ------------------------------------------------------------
# 🧩 Hilfsfunktionen: Logging & Stack
# ------------------------------------------------------------

function Write-MenuLog {
    <#
        .SYNOPSIS
            Schreibt Menüaktionen ins System-Log.
    #>
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
        Write-Host "⚠️ Fehler beim Schreiben des Menülogs: $($_.Exception.Message)" -ForegroundColor DarkRed
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
    return ($global:MenuStack -join " → ")
}

# ------------------------------------------------------------
# 🧩 Hauptfunktion: Show-SubMenu
# ------------------------------------------------------------
function Show-SubMenu {
    <#
        .SYNOPSIS
            Zeigt ein (Unter-)Menü mit Rücksprung- und Beendenfunktion an.
        .PARAMETER MenuTitle
            Titel des Menüs
        .PARAMETER Options
            Hashtable mit Key = Auswahl, Value = "Text|Aktion"
        .PARAMETER ReturnAfterAction
            Option für Rückkehr nach einer Aktion
    #>

    param(
        [Parameter(Mandatory)][string]$MenuTitle,
        [Parameter(Mandatory)][hashtable]$Options,
        [switch]$ReturnAfterAction
    )

    # Stack aktualisieren
    Push-MenuStack -Title $MenuTitle

    # 🧠 DebugMode prüfen
    try {
        . "$PSScriptRoot\Lib_Systeminfo.ps1"
        $debugMode = Get-DebugMode
    }
    catch { $debugMode = $false }

    # 🔁 Hauptmenü-Schleife
    while ($true) {
        Clear-Host
        $menuPath = Get-CurrentMenuPath

        Write-Host "============================================="
        Write-Host ("        " + ($MenuTitle -replace '^\s+', ''))
        Write-Host "============================================="
        if ($menuPath -ne "[ROOT]") {
            Write-Host ("📂 Pfad: " + $menuPath) -ForegroundColor DarkGray
        }
        if ($debugMode) { Write-Host "🪲 DEBUG-MODE AKTIVIERT`n" -ForegroundColor DarkYellow }

        foreach ($key in ($Options.Keys | Sort-Object {
            if ($_ -match '^\d+$') { [int]$_ } else { $_ }
        })) {
            Write-Host "$key - $($Options[$key].Split('|')[0])"
        }

        Write-Host "`n0 - Zurück zum vorherigen Menü"
        Write-Host "X - Komplett beenden"
        Write-Host ""

        $choice = Read-Host "Bitte Auswahl eingeben"

        # Beenden
        if ($choice -match '^(x|X)$') {
            Write-Host "`n👋 Programm wird beendet ..." -ForegroundColor Yellow
            Write-MenuLog -MenuTitle $MenuTitle -Selection "X" -Action "Programm beendet"
            try { Set-DebugMode -Value $false } catch {}
            Start-Sleep -Seconds 1
            exit
        }

        # Zurück
        if ($choice -eq "0" -or $choice -eq "z") {
            Pop-MenuStack
            Write-MenuLog -MenuTitle $MenuTitle -Selection "0" -Action "Zurück"
            return "0"
        }

        # Auswahl ausführen
        if ($Options.ContainsKey($choice)) {
            $action = $Options[$choice].Split('|')[1]
            if ($debugMode) { Write-Host "→ Ausführung: $action" -ForegroundColor DarkGray }

            # ------------------------------------------------------------
            # 🔍 Erweiterung: verschachtelte Menüs automatisch erkennen
            # ------------------------------------------------------------
            if ($action -match '^Show-SubMenu') {
                try {
                    $entry = $Options[$choice]
                    $parts = $entry.Split('|')
                    $menuTitleMatch = [regex]::Match($parts[1], "-MenuTitle\s+'([^']+)'")

                    if ($menuTitleMatch.Success) {
                        $subTitle = $menuTitleMatch.Groups[1].Value
                        $realOptions = Get-Variable | Where-Object { $_.Value -is [hashtable] -and $_.Name -like 'options*' } | Select-Object -First 1

                        if ($null -ne $realOptions) {
                            & (Get-Command Show-SubMenu) -MenuTitle $subTitle -Options $realOptions.Value
                            Write-MenuLog -MenuTitle $MenuTitle -Selection $choice -Action "Untermenü geöffnet: $($realOptions.Name)"
                            continue
                        }
                    }
                }
                catch {
                    Write-Host "⚠️ Fehler beim Öffnen des Untermenüs: $($_.Exception.Message)" -ForegroundColor Red
                }
            }

            # ------------------------------------------------------------
            # Standardaktion ausführen
            # ------------------------------------------------------------
            try {
                Write-MenuLog -MenuTitle $MenuTitle -Selection $choice -Action $action
                Invoke-Expression $action
            }
            catch {
                Write-Host "❌ Fehler beim Ausführen von '$action': $($_.Exception.Message)" -ForegroundColor Red
                Write-MenuLog -MenuTitle $MenuTitle -Selection $choice -Action "Fehler: $($_.Exception.Message)"
            }

            Pause
            if ($ReturnAfterAction) {
                Pop-MenuStack
                return $choice
            }
        }
        else {
            Write-Host "⚠️ Ungültige Eingabe. Bitte erneut versuchen." -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
