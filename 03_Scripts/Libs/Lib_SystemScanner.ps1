# ============================================================
# 🧩 Library: Lib_SystemScanner.ps1
# Version: LIB_V1.3.2
# Zweck:   Scannt alle Libraries & Module, liest ManifestHints aus,
#          erstellt Registry & Log, inkl. Gruppenzuordnung & Statistikdaten
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧩 ManifestHint:
#   ExportFunctions: Invoke-SystemScan
#   Description: Scannt alle Libraries und Module des SiteManagers,
#                 liest ManifestHints aus, erstellt Registry & Log inkl. Gruppen und Abhängigkeitsnetz.
#   Category: Utility
#   Tags: Scan, Registry, Manifest, Log, Framework, Relations, Grouping
#   Dependencies: Lib_PathManager, Lib_Json
# ============================================================

function Invoke-SystemScan {
    [CmdletBinding()]
    param (
        [string]$ScanRoot = (Join-Path $PSScriptRoot ".."),
        [switch]$Silent
    )

    try {
        Write-Host "`n📦 Starte SystemScan unter: $ScanRoot" -ForegroundColor Cyan

        # ------------------------------------------------------------
        # 🔧 PATHMANAGER LADEN
        # ------------------------------------------------------------
        $pathManager = Join-Path $PSScriptRoot "Lib_PathManager.ps1"
        if (!(Test-Path $pathManager)) {
            Write-Host "❌ Lib_PathManager nicht gefunden unter: $pathManager" -ForegroundColor Red
            return
        }
        . $pathManager
        $paths = Get-PathMap
        if (-not $paths) { throw "PathManager konnte Pfade nicht ermitteln." }

        # ------------------------------------------------------------
        # 🔧 JSON LIBRARY LADEN
        # ------------------------------------------------------------
        $jsonLib = Join-Path $PSScriptRoot "Lib_Json.ps1"
        if (Test-Path $jsonLib) {
            . $jsonLib
            Write-Host "✅ Lib_Json erfolgreich geladen." -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Lib_Json nicht gefunden – Fallback auf native JSON." -ForegroundColor Yellow
        }

        # ------------------------------------------------------------
        # 📁 PFAD-DEFINITIONEN
        # ------------------------------------------------------------
        $logPath      = Join-Path $paths.Logs "System_ScanLog.txt"
        $registryPath = Join-Path $paths.Root "00_Info\\Module_Registry.json"
        if (!(Test-Path $paths.Logs)) { New-Item -ItemType Directory -Path $paths.Logs -Force | Out-Null }

        # ------------------------------------------------------------
        # 🧠 SCAN STARTEN (rekursiv mit PathManager-Unterordnern)
        # ------------------------------------------------------------
        $searchPatterns = @("Lib_*.ps1", "Mod_*.ps1", "Core_*.ps1", "Test-*.ps1", "Dev-*.ps1")
        $files = @()

        try {
            if (Get-Command Get-PathSubDirs -ErrorAction SilentlyContinue) {
                Write-Host "📂 Sammle Unterordner über PathManager..." -ForegroundColor DarkGray
                $subDirs = Get-PathSubDirs -BasePath $paths.Scripts
                if (-not $subDirs -or $subDirs.Count -eq 0) {
                    Write-Host "⚠️ Keine Unterordner gefunden – verwende Standard-Scan." -ForegroundColor Yellow
                    $subDirs = @($paths.Scripts)
                }
            }
            else {
                Write-Host "⚠️ Get-PathSubDirs nicht verfügbar – verwende Standard-Scan." -ForegroundColor Yellow
                $subDirs = @($paths.Scripts)
            }

            foreach ($dir in $subDirs) {
                foreach ($pattern in $searchPatterns) {
                    $found = Get-ChildItem -Path $dir -Filter $pattern -File -ErrorAction SilentlyContinue
                    if ($found) { $files += $found }
                }
            }

            $files = $files | Sort-Object FullName -Unique
            Write-Host ("📄 {0} Dateien für Analyse vorbereitet." -f $files.Count) -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Fehler beim Sammeln der Unterordner: $($_.Exception.Message)" -ForegroundColor Red
        }

        # ------------------------------------------------------------
        # 🧩 DATEIEN ANALYSIEREN
        # ------------------------------------------------------------
        $startTime = Get-Date
        Add-Content -Path $logPath -Value "`n[$startTime] 🧩 Starte neuen SystemScan ($($files.Count) Dateien gefunden)"
        $scanResults = @()

        foreach ($file in $files) {
            $info = [ordered]@{
                Name            = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                Path            = $file.FullName
                Group           = "-"
                Version         = "-"
                Category        = "-"
                Description     = "-"
                ExportFunctions = @()
                Dependencies    = @()
                Tags            = @()
                Status          = "OK"
            }

            try {
                $content = Get-Content -Path $file.FullName -ErrorAction Stop

                # 🧩 ManifestHint-Block finden
                $hintIndex = ($content | Select-String -Pattern "ManifestHint" -SimpleMatch).LineNumber
                if ($hintIndex -and $hintIndex.Count -ge 1) {
                    $startLine = $hintIndex[0]
                    $block = @()
                    for ($i = $startLine; $i -lt $content.Count; $i++) {
                        $line = $content[$i].Trim()
                        if ($line -match "^#\s*={5,}" -or $line -eq "") { break }
                        $block += $line
                    }

                    foreach ($line in $block) {
                        if ($line -match "ExportFunctions:\s*(.*)")   { $info.ExportFunctions = $matches[1].Trim() -split ',' }
                        elseif ($line -match "Description:\s*(.*)")   { $info.Description     = $matches[1].Trim() }
                        elseif ($line -match "Category:\s*(.*)")      { $info.Category        = $matches[1].Trim() }
                        elseif ($line -match "Tags:\s*(.*)")          { $info.Tags            = $matches[1].Trim() -split ',' }
                        elseif ($line -match "Dependencies:\s*(.*)")  { $info.Dependencies    = $matches[1].Trim() -split ',' }
                    }
                }
                else {
                    $info.Status = "⚠️ Kein ManifestHint"
                }

                # 🔍 Version aus Header lesen
                $verLine = $content | Select-String -Pattern "Version:" | Select-Object -First 1
                if ($verLine) {
                    $info.Version = ($verLine.ToString() -split "Version:")[1].Trim()
                }

                # 🧩 Gruppenzuordnung anhand des Dateinamens
                $name = $info.Name
                $info.Group = if ($name -like "Lib_*") { "Libraries" }
                              elseif ($name -like "Mod_*") { "Modules" }
                              elseif ($name -like "Core_*" -or $name -like "Start_*") { "Core" }
                              elseif ($name -like "Test-*") { "Tests" }
                              elseif ($name -like "Dev-*") { "DevTools" }
                              else { "Other" }

                $scanResults += [PSCustomObject]$info
            }
            catch {
                $info.Status = "❌ Fehler: $($_.Exception.Message)"
                $scanResults += [PSCustomObject]$info
            }
        }

        # ------------------------------------------------------------
        # 🧩 BEZIEHUNGEN (Dependencies <-> UsedBy)
        # ------------------------------------------------------------
        $registryData = @{}
        foreach ($item in $scanResults) {
            $registryData[$item.Name] = @{
                Group           = $item.Group
                Version         = $item.Version
                Category        = $item.Category
                Description     = $item.Description
                ExportFunctions = $item.ExportFunctions
                Dependencies    = $item.Dependencies
                Tags            = $item.Tags
                Status          = $item.Status
                UsedBy          = @()
            }
        }

        # UsedBy aufbauen
        foreach ($key in $registryData.Keys) {
            $deps = $registryData[$key].Dependencies
            foreach ($dep in $deps) {
                $depName = $dep.Trim()
                if ($depName -and $registryData.ContainsKey($depName)) {
                    $registryData[$depName].UsedBy += $key
                }
            }
        }

        # ------------------------------------------------------------
        # 📊 STATISTIK-BLOCK
        # ------------------------------------------------------------
        $stats = [ordered]@{
            "GesamtModule"     = $registryData.Count
            "Libraries"        = ($scanResults | Where-Object { $_.Group -eq "Libraries" }).Count
            "Modules"          = ($scanResults | Where-Object { $_.Group -eq "Modules" }).Count
            "CoreModule"       = ($scanResults | Where-Object { $_.Group -eq "Core" }).Count
            "Tests"            = ($scanResults | Where-Object { $_.Group -eq "Tests" }).Count
            "DevTools"         = ($scanResults | Where-Object { $_.Group -eq "DevTools" }).Count
            "MitManifestHint"  = ($scanResults | Where-Object { $_.Status -eq 'OK' }).Count
            "OhneManifestHint" = ($scanResults | Where-Object { $_.Status -match 'ManifestHint' }).Count
            "Fehlerhafte"      = ($scanResults | Where-Object { $_.Status -match 'Fehler' }).Count
            "LetzterScan"      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }

        $registryData["__SystemInfo"] = $stats

        # ------------------------------------------------------------
        # 💾 REGISTRY SCHREIBEN
        # ------------------------------------------------------------
        try {
            if (Get-Command -Name Save-JsonFile -ErrorAction SilentlyContinue) {
                Save-JsonFile -Path $registryPath -Data $registryData
            }
            else {
                $registryData | ConvertTo-Json -Depth 6 | Out-File -FilePath $registryPath -Encoding utf8 -Force
            }

            Write-Host "`n📄 Registry aktualisiert: $registryPath" -ForegroundColor Green
            Add-Content -Path $logPath -Value "Registry aktualisiert: $registryPath"
        }
        catch {
            Write-Host "❌ Fehler beim Schreiben der Registry: $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $logPath -Value "❌ Fehler beim Schreiben der Registry: $($_.Exception.Message)"
        }

        # ------------------------------------------------------------
        # 🧾 ZUSAMMENFASSUNG
        # ------------------------------------------------------------
        Write-Host "`n📊 Scan-Zusammenfassung:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────────────"
        Write-Host ("Gesamtdateien     : {0}" -f $scanResults.Count)
        Write-Host ("Mit ManifestHint  : {0}" -f $stats.MitManifestHint)
        Write-Host ("Ohne ManifestHint : {0}" -f $stats.OhneManifestHint)
        Write-Host ("Fehlerhafte Dateien: {0}" -f $stats.Fehlerhafte)
        Write-Host "─────────────────────────────────────────────"
        Write-Host ("Libraries         : {0}" -f $stats.Libraries)
        Write-Host ("Modules           : {0}" -f $stats.Modules)
        Write-Host ("Tests             : {0}" -f $stats.Tests)
        Write-Host ("DevTools          : {0}" -f $stats.DevTools)
        Write-Host ("Core-Module       : {0}" -f $stats.CoreModule)
        Write-Host ("Letzter Scan      : {0}" -f $stats.LetzterScan)
        Write-Host "─────────────────────────────────────────────"
        Write-Host "🪵 Log-Datei: $logPath" -ForegroundColor DarkGray

        Add-Content -Path $logPath -Value "Scan abgeschlossen – $($stats.GesamtModule) Module, $($stats.MitManifestHint) mit Hint, $($stats.Fehlerhafte) Fehler."
        Write-Host "`n✅ SystemScan abgeschlossen." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Schwerer Fehler im SystemScan: $($_.Exception.Message)" -ForegroundColor Red
    }
}
