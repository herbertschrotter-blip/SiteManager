# ============================================================
# 🧪 TESTTOOL – SystemScanner
# Version: TEST_V1.0.0
# Zweck:   Führt den SystemScan aus, zeigt Ergebnisse und prüft Registry & Log
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧩 ManifestHint:
#   ExportFunctions: Invoke-SystemScannerTest
#   Description: Testmodul zur Überprüfung des SystemScanner-Moduls.
#                 Ruft Invoke-SystemScan auf, zeigt Ergebnisse und prüft Dateien.
#   Category: Test
#   Tags: System, Scan, Registry, Log, Diagnostics
#   Dependencies: Lib_SystemScanner, Lib_PathManager, Lib_Json
# ============================================================

function Invoke-SystemScannerTest {
    [CmdletBinding()]
    param (
        [switch]$Silent
    )

    try {
        Write-Host "`n🧩 Starte Testlauf für SystemScanner..." -ForegroundColor Cyan

        # ------------------------------------------------------------
        # 📦 Library-Pfade bestimmen
        # ------------------------------------------------------------
        $libScanner = Join-Path $PSScriptRoot "..\\..\\Libs\\Lib_SystemScanner.ps1"
        $libPathMgr = Join-Path $PSScriptRoot "..\\..\\Libs\\Lib_PathManager.ps1"
        $libJson    = Join-Path $PSScriptRoot "..\\..\\Libs\\Lib_Json.ps1"

        $libsToLoad = @($libPathMgr, $libJson, $libScanner)

        foreach ($lib in $libsToLoad) {
            if (Test-Path $lib) {
                . $lib
                Write-Host "✅ Geladen: $(Split-Path $lib -Leaf)" -ForegroundColor Green
            }
            else {
                Write-Host "⚠️ Nicht gefunden: $lib" -ForegroundColor Yellow
            }
        }

        # ------------------------------------------------------------
        # 📁 Pfade prüfen
        # ------------------------------------------------------------
        $paths = Get-PathMap
        if (-not $paths) {
            Write-Host "❌ Keine gültige Pfadstruktur erkannt." -ForegroundColor Red
            return
        }

        $registryPath = Join-Path $paths.Root "00_Info\\Module_Registry.json"
        $logPath      = Join-Path $paths.Logs "System_ScanLog.txt"

        # ------------------------------------------------------------
        # 🧠 SystemScan ausführen
        # ------------------------------------------------------------
        Write-Host "`n🚀 Starte Invoke-SystemScan..." -ForegroundColor Cyan
        Invoke-SystemScan -Silent:$Silent

        # ------------------------------------------------------------
        # 📄 Registry anzeigen
        # ------------------------------------------------------------
        if (Test-Path $registryPath) {
            Write-Host "`n📄 Registry-Datei gefunden:" -ForegroundColor Green
            Write-Host "   $registryPath"
            Write-Host "─────────────────────────────────────────────"

            try {
                $registry = Get-Content $registryPath -Raw | ConvertFrom-Json
                $table = foreach ($key in $registry.PSObject.Properties.Name) {
                    $item = $registry.$key
                    [PSCustomObject]@{
                        Modulname  = $key
                        Version    = $item.Version
                        Kategorie  = $item.Category
                        Status     = $item.Status
                        Funktionen = ($item.ExportFunctions -join ', ')
                    }
                }

                $table | Sort-Object Modulname | Format-Table Modulname, Version, Kategorie, Status, Funktionen -AutoSize
            }
            catch {
                Write-Host "❌ Fehler beim Lesen der Registry: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "⚠️ Keine Registry-Datei gefunden unter: $registryPath" -ForegroundColor Yellow
        }

        # ------------------------------------------------------------
        # 🪵 Log-Datei prüfen
        # ------------------------------------------------------------
        if (Test-Path $logPath) {
            Write-Host "`n🪵 Log-Datei gefunden: $logPath" -ForegroundColor Green
            $lastLines = Get-Content $logPath | Select-Object -Last 5
            Write-Host "─────────────────────────────────────────────"
            $lastLines | ForEach-Object { Write-Host $_ }
        }
        else {
            Write-Host "⚠️ Keine Log-Datei gefunden unter: $logPath" -ForegroundColor Yellow
        }

        # ------------------------------------------------------------
        # 📊 Zusammenfassung
        # ------------------------------------------------------------
        Write-Host "`n📊 TEST-ZUSAMMENFASSUNG:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────────────"
        Write-Host "Registry vorhanden : $((Test-Path $registryPath) -as [string])"
        Write-Host "Log vorhanden      : $((Test-Path $logPath) -as [string])"
        Write-Host "─────────────────────────────────────────────"

        Write-Host "`n✅ Testlauf abgeschlossen." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Schwerer Fehler im SystemScanner-Test: $($_.Exception.Message)" -ForegroundColor Red
    }
}
# ------------------------------------------------------------
# ⚙️ AUTOMATISCHER START BEIM DIREKTAUFRUF
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -eq "&" -or
    ($MyInvocation.MyCommand.Path -eq $PSCommandPath -and
     $MyInvocation.InvocationName -notmatch "Invoke-SystemScannerTest")) {

    Write-Host "`n⚙️  Auto-Start erkannt – führe SystemScanner-Test aus..." -ForegroundColor DarkGray
    Invoke-SystemScannerTest
}
