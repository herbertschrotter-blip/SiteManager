# ============================================================
# 🧩 TOOL – Script-Backup (PathManager + Root Config)
# Version: TOOL_V1.3.2
# Zweck:   Erstellt Backup_Config.json mit allen Hauptordnern der Projektstruktur.
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: Update-BackupConfig, Backup-ScriptFolders
#   Description: Erstellt Backup_Config.json mit allen Hauptordnern aus PathManager.
#   Category: Tools
#   Tags: Backup, Config, PathManager, Root, FolderMap
#   Dependencies: Lib_PathManager
# ============================================================

# ------------------------------------------------------------
# 🔹 PathManager-Integration
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
# ⚙️ Funktion: Backup_Config.json mit Root-Ordnern erzeugen
# ------------------------------------------------------------
function Update-BackupConfig {
    param(
        [string]$ConfigPath = (Join-Path $pathMap.Config "Backup_Config.json")
    )

    Write-Host "`n🧩 Erstelle Backup_Config.json (nur Hauptordner)..." -ForegroundColor Cyan

    try {
        # 🔍 Prüfen, ob Pfade gültig sind
        if (-not $pathMap.Root -or -not (Test-Path $pathMap.Root)) {
            throw "Root-Pfad konnte nicht ermittelt werden."
        }

        $config = [ordered]@{
            Version     = "CFG_V1.1.0"
            ErstelltAm  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Root        = $pathMap.Root
            Ordner      = @()
        }

        foreach ($key in $pathMap.Keys) {
            if ($key -eq "Root") { continue }
            $folderPath = $pathMap[$key]
            if (Test-Path $folderPath) {
                $entry = [ordered]@{
                    Kategorie = $key
                    Pfad      = Split-Path $folderPath -Leaf
                    Vollpfad  = (Resolve-Path $folderPath).Path
                    Aktiv     = $true
                }
                $config.Ordner += $entry
            }
        }

        # Datei schreiben
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
        Write-Host "✅ Backup_Config.json gespeichert unter:`n   $ConfigPath" -ForegroundColor Green
        Write-Host ("📦 {0} Hauptordner eingetragen." -f $config.Ordner.Count) -ForegroundColor White
    }
    catch {
        Write-Host ("❌ Fehler beim Erstellen der Backup_Config.json: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🔹 Bestehende Backup-Funktion (optional, bleibt ungenutzt)
# ------------------------------------------------------------
function Backup-ScriptFolders {
    Write-Host "`n🗂️  (Platzhalter) Script-Backup unverändert – nur Config wird aktuell erzeugt." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# 🧭 Automatischer Start
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -eq ".") {
    Update-BackupConfig
}
