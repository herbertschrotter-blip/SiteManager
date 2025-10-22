# ============================================================
# 🧩 TOOL – Script-Backup (PathManager + Config + ZIP)
# Version: TOOL_V1.4.1
# Zweck:   Liest Backup_Config.json und erstellt ZIPs für alle aktivierten Ordner (Default: inaktiv).
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: Update-BackupConfig, Run-BackupFromConfig
#   Description: Erstellt ZIP-Backups basierend auf Backup_Config.json (Default = inaktiv, PathManager + Get-PathSubDirs).
#   Category: Tools
#   Tags: Backup, Config, Zip, PathManager, Recursive, Selective
#   Dependencies: Lib_PathManager
# ============================================================

# ------------------------------------------------------------
# 🔹 PathManager laden
# ------------------------------------------------------------
try {
    $pathManagerPath = "$PSScriptRoot\..\Libs\Lib_PathManager.ps1"
    if (-not (Test-Path $pathManagerPath)) {
        $pathManagerPath = "$PSScriptRoot\..\..\Libs\Lib_PathManager.ps1"
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
        Root      = "$PSScriptRoot\..\.."
        Config    = "$PSScriptRoot\..\..\01_Config"
        Templates = "$PSScriptRoot\..\..\02_Templates"
        Scripts   = "$PSScriptRoot\..\..\03_Scripts"
        Logs      = "$PSScriptRoot\..\..\04_Logs"
        Backup    = "$PSScriptRoot\..\..\05_Backup"
    }
}

# ------------------------------------------------------------
# ⚙️ Funktion: Backup_Config.json aktualisieren (Default = false)
# ------------------------------------------------------------
function Update-BackupConfig {
    param([string]$ConfigPath = (Join-Path $pathMap.Config "Backup_Config.json"))

    Write-Host "`n🧩 Erstelle/aktualisiere Backup_Config.json (Default = inaktiv)..." -ForegroundColor Cyan
    try {
        if (-not $pathMap.Root -or -not (Test-Path $pathMap.Root)) {
            throw "Root-Pfad konnte nicht ermittelt werden."
        }

        $config = [ordered]@{
            Version     = "CFG_V1.2.2"
            ErstelltAm  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Root        = $pathMap.Root
            Ordner      = @()
        }

        # Hauptordner hinzufügen
        foreach ($prop in $pathMap.PSObject.Properties) {
            $key = $prop.Name
            $folderPath = $prop.Value
            if ($key -eq "Root") { continue }
            if (-not (Test-Path $folderPath)) { continue }

            $entry = [ordered]@{
                Kategorie = $key
                Pfad      = Split-Path $folderPath -Leaf
                Vollpfad  = (Resolve-Path $folderPath).Path
                Ebene     = "Hauptordner"
                Aktiv     = $false   # Standard: deaktiviert
            }
            $config.Ordner += $entry
        }

        # Unterordner hinzufügen
        if (Get-Command Get-PathSubDirs -ErrorAction SilentlyContinue) {
            $subDirs = Get-PathSubDirs -BasePath $pathMap.Root
            foreach ($dir in $subDirs) {
                $relPath = $dir.Substring($pathMap.Root.Length).TrimStart('\','/')
                if ([string]::IsNullOrWhiteSpace($relPath)) { continue }

                $entry = [ordered]@{
                    Kategorie = "SubDir"
                    Pfad      = $relPath
                    Vollpfad  = (Resolve-Path $dir).Path
                    Ebene     = "Unterordner"
                    Aktiv     = $false   # Standard: deaktiviert
                }
                $config.Ordner += $entry
            }
        }

        $config | ConvertTo-Json -Depth 6 | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
        Write-Host "✅ Backup_Config.json gespeichert unter:`n   $ConfigPath" -ForegroundColor Green
        Write-Host ("📦 {0} Einträge hinzugefügt (Default = inaktiv)." -f $config.Ordner.Count) -ForegroundColor White
    }
    catch {
        Write-Host ("❌ Fehler beim Erstellen der Config: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🔹 Funktion: Run-BackupFromConfig – ZIPs erstellen
# ------------------------------------------------------------
function Run-BackupFromConfig {
    param(
        [string]$ConfigPath = (Join-Path $pathMap.Config "Backup_Config.json"),
        [string]$TargetPath = $pathMap.Backup
    )

    Write-Host "`n🗂️  Starte ZIP-Backup anhand der Config ..." -ForegroundColor Yellow

    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Host "⚠️ Keine Config gefunden – wird neu erstellt." -ForegroundColor DarkYellow
            Update-BackupConfig
        }

        $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
        if (-not $config.Ordner) {
            throw "Config enthält keine Ordner-Einträge."
        }

        if (-not (Test-Path $TargetPath)) {
            New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
        }

        $ok = 0; $skipped = 0; $errors = 0

        foreach ($entry in $config.Ordner) {
            if (-not $entry.Aktiv) {
                Write-Host ("⏸️  Überspringe inaktiven Ordner: {0}" -f $entry.Pfad) -ForegroundColor DarkGray
                $skipped++
                continue
            }

            $folder = $entry.Vollpfad
            if (-not (Test-Path $folder)) { continue }

            $rel = $entry.Pfad -replace '^[\\/]+','' -replace '[\\/]+','__'
            $zipPath = Join-Path $TargetPath ($rel + ".zip")

            $files = Get-ChildItem -Path $folder -File -Recurse -ErrorAction SilentlyContinue
            if (-not $files -or $files.Count -eq 0) {
                Write-Host ("⏭️  Überspringe leeren Ordner: {0}" -f $entry.Pfad) -ForegroundColor DarkGray
                $skipped++
                continue
            }

            Write-Host ("`n📦 Archiviere {0} → {1}" -f $entry.Pfad, $zipPath) -ForegroundColor White

            try {
                if (Test-Path $zipPath) {
                    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                }
                Compress-Archive -Path (Join-Path $folder "*") -DestinationPath $zipPath -Force
                Write-Host ("✅ Archiv erstellt: {0}" -f (Split-Path $zipPath -Leaf)) -ForegroundColor Green
                $ok++
            }
            catch {
                Write-Host ("❌ Fehler beim Archivieren von {0}: {1}" -f $entry.Pfad, $_.Exception.Message) -ForegroundColor Red
                $errors++
            }
        }

        Write-Host "`n✅ Backup abgeschlossen." -ForegroundColor Green
        Write-Host ("📊 Ergebnis: {0} erstellt, {1} übersprungen, {2} Fehler" -f $ok, $skipped, $errors) -ForegroundColor White
    }
    catch {
        Write-Host ("❌ Unerwarteter Fehler im Backup: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🧭 Automatischer Start
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -eq ".") {
    Run-BackupFromConfig
}
