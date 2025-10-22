# ============================================================
# 🧩 Library: Lib_SystemScanner.ps1
# Version: LIB_V1.1.0
# Zweck:   Scannt alle Libraries & Module, liest ManifestHints aus,
#          erstellt Registry und Logdatei (kein Manifest-Export)
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# 🧩 ManifestHint:
#   ExportFunctions: Invoke-SystemScan
#   Description: Scannt alle Libraries und Module des SiteManagers,
#                 liest ManifestHints aus und erstellt System-Registry & Log.
#   Category: Utility
#   Tags: Scan, Registry, Manifest, Log, Framework
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
        # 🧠 SCAN STARTEN
        # ------------------------------------------------------------
        $files = Get-ChildItem -Path $paths.Scripts -Recurse -Include "Lib_*.ps1","Mod_*.ps1","Core_*.ps1" -File |
                 Sort-Object FullName
        if ($files.Count -eq 0) {
            Write-Host "⚠️ Keine Module oder Libraries gefunden." -ForegroundColor Yellow
            return
        }

        $startTime = Get-Date
        Add-Content -Path $logPath -Value "`n[$startTime] 🧩 Starte neuen SystemScan ($($files.Count) Dateien gefunden)"

        $scanResults = @()
        foreach ($file in $files) {
            $info = [ordered]@{
                Name            = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                Path            = $file.FullName
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

                # ManifestHint-Block suchen (Unicode-tolerant & variabel lang)
                $hintIndex = ($content | Select-String -Pattern "#\s*ManifestHint" -SimpleMatch).LineNumber

                if ($hintIndex -and $hintIndex.Count -ge 1) {
                    $startLine = $hintIndex[0]
                    # Alle folgenden Zeilen bis zu einer Trennlinie oder leerer Zeile lesen
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

                }

                # Version aus Header lesen
                $verLine = $content | Select-String -Pattern "Version:" | Select-Object -First 1
                if ($verLine) {
                    $info.Version = ($verLine.ToString() -split "Version:")[1].Trim()
                }

                $scanResults += [PSCustomObject]$info
            }
            catch {
                $info.Status = "❌ Fehler: $($_.Exception.Message)"
                $scanResults += [PSCustomObject]$info
            }
        }

        # ------------------------------------------------------------
        # 💾 REGISTRY SCHREIBEN
        # ------------------------------------------------------------
        try {
            $registryData = @{}
            foreach ($item in $scanResults) {
                $registryData[$item.Name] = @{
                    Version         = $item.Version
                    Category        = $item.Category
                    Description     = $item.Description
                    ExportFunctions = $item.ExportFunctions
                    Dependencies    = $item.Dependencies
                    Tags            = $item.Tags
                    Status          = $item.Status
                }
            }

            if (Get-Command -Name Save-JsonFile -ErrorAction SilentlyContinue) {
                Save-JsonFile -Path $registryPath -Data $registryData
            }
            else {
                $registryData | ConvertTo-Json -Depth 5 | Out-File -FilePath $registryPath -Encoding utf8 -Force
            }

            Write-Host "`n📄 Registry aktualisiert: $registryPath" -ForegroundColor Green
            Add-Content -Path $logPath -Value "Registry aktualisiert: $registryPath"
        }
        catch {
            Write-Host "❌ Fehler beim Schreiben der Registry: $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $logPath -Value "❌ Fehler beim Schreiben der Registry: $($_.Exception.Message)"
        }

        # ------------------------------------------------------------
        # 📊 ZUSAMMENFASSUNG
        # ------------------------------------------------------------
        $total     = $scanResults.Count
        $withHint  = ($scanResults | Where-Object { $_.Status -eq 'OK' }).Count
        $noHint    = ($scanResults | Where-Object { $_.Status -match 'ManifestHint' }).Count
        $errors    = ($scanResults | Where-Object { $_.Status -match 'Fehler' }).Count

        Write-Host "`n📊 Scan-Zusammenfassung:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────────────"
        Write-Host ("Gesamtdateien     : {0}" -f $total)
        Write-Host ("Mit ManifestHint  : {0}" -f $withHint)
        Write-Host ("Ohne ManifestHint : {0}" -f $noHint)
        Write-Host ("Fehlerhafte Dateien: {0}" -f $errors)
        Write-Host "─────────────────────────────────────────────"
        Write-Host "🪵 Log-Datei: $logPath" -ForegroundColor DarkGray

        Add-Content -Path $logPath -Value "Scan abgeschlossen – $total Dateien, $withHint mit Hint, $errors Fehler."
        Write-Host "`n✅ SystemScan abgeschlossen." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Schwerer Fehler im SystemScan: $($_.Exception.Message)" -ForegroundColor Red
    }
}
