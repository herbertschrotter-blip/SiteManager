# ============================================================
# 🧪 Modul: Test-PathManager.ps1
# Version: DEV_V1.2.1
# Zweck:   Automatischer Test aller Endpunkte aus Lib_PathManager.ps1
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧩 ManifestHint:
#   ExportFunctions: Test-PathManager
#   Description: Automatischer Meta-Test für Lib_PathManager.ps1 – liest ManifestHint, prüft Funktionen und ruft parameterlose Endpunkte auf.
#   Category: Dev
#   Tags: Path, Test, Framework, Structure, Automation, Meta
#   Dependencies: Lib_PathManager.ps1
# ============================================================


# ------------------------------------------------------------
# 🧩 Hilfsfunktion: Show-Result
# ------------------------------------------------------------
function Show-Result {
    param([string]$Label, [string]$Message, [ConsoleColor]$Color = "Gray")
    Write-Host ("   " + $Label.PadRight(25) + ": " + $Message) -ForegroundColor $Color
}

# ------------------------------------------------------------
# 🧠 Hauptfunktion: Test-PathManager
# ------------------------------------------------------------
function Test-PathManager {
    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "🧩 AUTOMATISCHER TEST DER LIB_PATHMANAGER.PS1" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan

    try {
        # ------------------------------------------------------------
        # 📦 Library laden
        # ------------------------------------------------------------
        $libPath = "$PSScriptRoot\..\..\Libs\Lib_PathManager.ps1"

        if (-not (Test-Path $libPath)) {
            Write-Host "❌ Library nicht gefunden unter: $libPath" -ForegroundColor Red
            return
        }

        . $libPath
        Write-Host "✅ Lib_PathManager.ps1 erfolgreich geladen." -ForegroundColor Green

        # ------------------------------------------------------------
        # 🔍 ManifestHint lesen
        # ------------------------------------------------------------
        $content = Get-Content -Path $libPath -Raw -ErrorAction Stop
        $lines   = $content -split "`r?`n"

        # ExportFunctions parsen und von Kommentaren/Leerzeichen befreien
        $exportLine = ($lines | Where-Object { $_ -match "ExportFunctions:" }) -replace ".*ExportFunctions:\s*", ""
        $functions  = ($exportLine -split ",") | ForEach-Object { $_.Trim() -replace '^[#\s]+', '' } | Where-Object { $_ -ne "" }

        if (-not $functions -or $functions.Count -eq 0) {
            Write-Host "⚠️ Keine Funktionen im ManifestHint gefunden." -ForegroundColor Yellow
            return
        }

        Write-Host "`n📄 Gefundene ExportFunctions laut ManifestHint:" -ForegroundColor Yellow
        foreach ($fn in $functions) { Write-Host "   • $fn" -ForegroundColor DarkGray }

        # ------------------------------------------------------------
        # 🔬 Existenz prüfen
        # ------------------------------------------------------------
        Write-Host "`n🔍 Überprüfe Existenz & Aufrufbarkeit..." -ForegroundColor Cyan

        $results = @()
        foreach ($fn in $functions) {
            $name = $fn.Trim()
            $cmd  = Get-Command $name -ErrorAction SilentlyContinue
            if ($cmd) {
                Show-Result $name "✅ Gefunden" Green
                $results += [PSCustomObject]@{ Name=$name; Exists=$true; Parameters=$cmd.Parameters.Count }
            }
            else {
                Show-Result $name "❌ Nicht gefunden" Red
                $results += [PSCustomObject]@{ Name=$name; Exists=$false; Parameters=0 }
            }
        }

        # ------------------------------------------------------------
        # ▶️ Automatische Aufrufe aller Funktionen (sichtbar, kein Überspringen)
        # ------------------------------------------------------------
        Write-Host "`n▶️ Starte automatische Aufrufe aller Funktionen..." -ForegroundColor Cyan

        foreach ($item in $results | Where-Object { $_.Exists }) {
            $fn  = $item.Name
            $cmd = Get-Command $fn -ErrorAction SilentlyContinue

            if (-not $cmd) {
                Write-Host "❌ $fn() konnte nicht gefunden werden." -ForegroundColor Red
                continue
            }

            # Prüfen, ob Pflichtparameter existieren
            $mandatoryParams = @($cmd.Parameters.Values | Where-Object { -not $_.IsOptional })
            $hasMandatory = $mandatoryParams.Count -gt 0

            if (-not $hasMandatory) {
                # ✅ Funktion hat keine Pflichtparameter – direkt aufrufen
                Write-Host "   ▶️  $fn()" -ForegroundColor DarkGray
                try {
                    $result = & $fn
                    if ($result) {
                        $out = ($result | Out-String).Trim() -replace "`r?`n", "; "
                        if ($out.Length -gt 120) { $out = $out.Substring(0,120) + "..." }
                        Show-Result "   ↳ Rückgabe" $out DarkGray
                    }
                    else {
                        Show-Result "   ↳ Rückgabe" "<leer>" DarkGray
                    }
                }
                catch {
                    Show-Result "   ↳ Fehler" $_.Exception.Message Yellow
                }
            }
            else {
                # ⚠️ Funktion hat Pflichtparameter – nicht ausführen, aber anzeigen
                Write-Host "   ⚠️  $fn() benötigt Pflichtparameter:" -ForegroundColor Yellow
                foreach ($param in $mandatoryParams) {
                    Write-Host ("      • " + $param.Name + " [" + $param.ParameterType.Name + "]") -ForegroundColor DarkGray
                }
            }
        }

        # ------------------------------------------------------------
        # 📊 Zusammenfassung
        # ------------------------------------------------------------
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "📊 TEST-ZUSAMMENFASSUNG:" -ForegroundColor Yellow
        Write-Host "──────────────────────────────────────────────" -ForegroundColor DarkGray

        $okCount   = ($results | Where-Object { $_.Exists }).Count
        $failCount = ($results | Where-Object { -not $_.Exists }).Count
        Show-Result "Gefundene Funktionen" $okCount.ToString() Green
        $color = if ($failCount -eq 0) { "Green" } else { "Red" }
        Show-Result "Fehlende Funktionen"  $failCount.ToString() $color
        Write-Host "============================================" -ForegroundColor Cyan

        Write-Host "`n✅ Test-PathManager abgeschlossen." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Schwerer Fehler im Auto-Test: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ⚙️ Automatischer Start beim Direktruf
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -eq "&" -or
    ($MyInvocation.MyCommand.Path -eq $PSCommandPath -and
     $MyInvocation.InvocationName -notmatch "Test-PathManager")) {

    Write-Host "`n⚙️  Auto-Start erkannt – führe Test-PathManager aus..." -ForegroundColor DarkGray
    Test-PathManager
}
