# ============================================================
# 🧪 TESTTOOL – Manifest Generator
# Version: TEST_V1.4.0
# Zweck:   Testet PathManager-Integration, erkennt Libraries und listet sie mit Status auf
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧩 ManifestHint:
#   ExportFunctions: Invoke-ManifestTest
#   Description: Testmodul zur Überprüfung der ManifestGenerator-Integration.
#                 Prüft Pfade, Systeminfos und erkennt Libraries (.ps1).
#   Category: Test
#   Tags: Manifest, Test, PathManager, Diagnostics, LibraryScan
#   Dependencies: Lib_PathManager, Lib_ManifestGenerator
# ============================================================

function Invoke-ManifestTest {
    # ------------------------------------------------------------
    # 🔧 PathManager laden
    # ------------------------------------------------------------
    try {
        $PathManager = Join-Path $PSScriptRoot "..\..\Libs\Lib_PathManager.ps1"
        if (!(Test-Path $PathManager)) {
            Write-Host "❌ PathManager nicht gefunden unter: $PathManager" -ForegroundColor Red
            exit
        }

        . $PathManager
        Write-Host "✅ Lib_PathManager erfolgreich geladen." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Fehler beim Laden des PathManagers: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }

    # ------------------------------------------------------------
    # 🧭 Pfade abrufen und anzeigen
    # ------------------------------------------------------------
    try {
        $paths = Get-PathMap
        if (-not $paths) {
            Write-Host "⚠️ Keine Pfade vom PathManager erhalten." -ForegroundColor Yellow
            exit
        }

        Write-Host "`n📦 ERKANNTE PFADSTRUKTUR (vom PathManager):" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────────────"
        $paths | Get-Member -MemberType NoteProperty | ForEach-Object {
            $key = $_.Name
            $value = $paths.$key
            Write-Host ("{0,-12}: {1}" -f $key, $value)
        }

        Write-Host "`n📂 Detailausgabe (PSCustomObject):" -ForegroundColor DarkGray
        $paths | Format-List
    }
    catch {
        Write-Host "❌ Fehler beim Abrufen der Pfade: $($_.Exception.Message)" -ForegroundColor Red
    }

    # ------------------------------------------------------------
    # 🧠 Aktives System ausgeben
    # ------------------------------------------------------------
    try {
        $system = Get-ActiveSystem
        if ($system) {
            Write-Host "`n🧠 AKTIVES SYSTEM:" -ForegroundColor Cyan
            Write-Host "─────────────────────────────────────────────"
            Write-Host "Benutzer : $($system.Benutzer)"
            Write-Host "Computer : $($system.Computer)"
            Write-Host "Root     : $($system.Root)"
            Write-Host "LetzteErkennung: $($system.LetzteErkennung)"
        }
        else {
            Write-Host "`n⚠️ Kein aktives System gefunden (Fallback-Modus)." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Fehler beim Abrufen des aktiven Systems: $($_.Exception.Message)" -ForegroundColor Red
    }

    # ------------------------------------------------------------
    # 📁 Dateien im Lib-Ordner erkennen (.ps1)
    # ------------------------------------------------------------
    try {
        $LibFolder = Join-Path $paths.Scripts "Libs"
        if (!(Test-Path $LibFolder)) {
            Write-Host "❌ Library-Ordner nicht gefunden: $LibFolder" -ForegroundColor Red
            exit
        }

        Write-Host "`n📚 Erkenne Libraries und Manifeste in:" -ForegroundColor Cyan
        Write-Host "$LibFolder"
        Write-Host "─────────────────────────────────────────────"

        $libs = Get-ChildItem -Path $LibFolder -Filter "*.ps1" -File | Sort-Object Name
        if ($libs.Count -eq 0) {
            Write-Host "⚠️ Keine .ps1-Dateien im Lib-Ordner gefunden." -ForegroundColor Yellow
        }
        else {
            $table = foreach ($lib in $libs) {
                $manifest = [System.IO.Path]::ChangeExtension($lib.FullName, ".psd1")
                $hasManifest = Test-Path $manifest
                $status = if ($hasManifest) {
                    $libTime = (Get-Item $lib.FullName).LastWriteTime
                    $manTime = (Get-Item $manifest).LastWriteTime
                    if ($manTime -ge $libTime) { "✅ Aktuell" } else { "⚠️ Veraltet" }
                } else { "❌ Fehlt" }

                [PSCustomObject]@{
                    Modulname     = $lib.BaseName
                    Manifest      = if ($hasManifest) { "Ja" } else { "Nein" }
                    Status        = $status
                    LibDatum      = (Get-Item $lib.FullName).LastWriteTime
                    ManifestDatum = if ($hasManifest) { (Get-Item $manifest).LastWriteTime } else { "-" }
                }
            }

            $table | Format-Table Modulname, Manifest, Status, LibDatum, ManifestDatum -AutoSize
        }
    }
    catch {
        Write-Host "❌ Fehler beim Erkennen der Libraries: $($_.Exception.Message)" -ForegroundColor Red
    }

    # ------------------------------------------------------------
    # ✅ Abschlussmeldung
    # ------------------------------------------------------------
    Write-Host "`n✅ Testlauf abgeschlossen – keine Dateien wurden verändert oder erstellt." -ForegroundColor Green
}
