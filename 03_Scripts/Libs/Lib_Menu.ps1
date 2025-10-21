# ============================================================
# Library: Lib_Menu.ps1
# Version: LIB_V1.0.5
# Zweck:   Einheitliche Menüführung mit Rückkehrfunktion + X-Beenden
# Autor:   Herbert Schrotter
# Datum:   19.10.2025
# ============================================================

function Show-SubMenu {
    <#
        .SYNOPSIS
            Zeigt ein Untermenü mit beliebigen Optionen an.

        .PARAMETER MenuTitle
            Überschrift des Menüs (Zeilenumbruch mit `n möglich).

        .PARAMETER Options
            Hashtable: "Taste" = "Beschriftung|Aktion"

        .PARAMETER ReturnAfterAction
            Wenn gesetzt: Nach Ausführen EINER Aktion zurückkehren,
            damit der Aufrufer Daten neu berechnen und das Menü neu
            zeichnen kann (z. B. Statuszeile aktualisieren).

        .OUTPUTS
            Gibt die getroffene Auswahl zurück (z. B. "1") oder "0"/"z" bei Zurück.
    #>

    param(
        [Parameter(Mandatory)][string]$MenuTitle,
        [Parameter(Mandatory)][hashtable]$Options,
        [switch]$ReturnAfterAction
    )

    # ------------------------------------------------------------
    # 🧠 Systeminfo & DebugMode laden
    # ------------------------------------------------------------
    try {
        . "$PSScriptRoot\Lib_Systeminfo.ps1"
        $debugMode = Get-DebugMode
    }
    catch { $debugMode = $false }

    # ------------------------------------------------------------
    # 🔁 Hauptmenü-Schleife
    # ------------------------------------------------------------
    while ($true) {
        Clear-Host
        try { $debugMode = Get-DebugMode } catch { $debugMode = $false }

        Write-Host "============================================="
        Write-Host ("        " + ($MenuTitle -replace '^\s+', ''))
        Write-Host "============================================="
        if ($debugMode) { Write-Host "🪲 DEBUG-MODE AKTIVIERT`n" -ForegroundColor DarkYellow }

        foreach ($key in ($Options.Keys | Sort-Object {
            if ($_ -match '^\d+$') { [int]$_ } else { $_ }
            })) {
            Write-Host "$key - $($Options[$key].Split('|')[0])"
    }


        Write-Host "`n0 - Zurück zum vorherigen Menü"
        Write-Host "X - Komplett beenden"
        Write-Host ""

        # ------------------------------------------------------------
        # 📥 Eingabe abfragen (einfach & stabil)
        # ------------------------------------------------------------
        $choice = Read-Host "Bitte Auswahl eingeben"

        # 🔚 Beenden mit X oder x
        if ($choice -match '^(x|X)$') {
            Write-Host "`n👋 Programm wird beendet ..." -ForegroundColor Yellow
            try { Set-DebugMode -Value $false } catch {}
            Start-Sleep -Seconds 1
            exit
        }

        # 🔙 Zurück zum vorherigen Menü
        if ($choice -eq "0" -or $choice -eq "z") { return "0" }

        # ✅ Option ausführen
        if ($Options.ContainsKey($choice)) {
            $action = $Options[$choice].Split('|')[1]
            if ($debugMode) { Write-Host "→ Ausführung: $action" -ForegroundColor DarkGray }

            try { Invoke-Expression $action }
            catch {
                Write-Host "❌ Fehler beim Ausführen von '$action': $($_.Exception.Message)" -ForegroundColor Red
            }

            Pause
            if ($ReturnAfterAction) { return $choice }
        }
        else {
            Write-Host "⚠️ Ungültige Eingabe. Bitte erneut versuchen." -ForegroundColor Red
            Start-Sleep 1
        }
    }
}
