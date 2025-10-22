# ============================================================
# 🧩 TOOL – Script-Backup (PathManager + Merge + Backup-Fix)
# Version: TOOL_V1.5.6
# Zweck:   Erstellt und pflegt hierarchische Backup_Config.json und
#          erstellt ZIP-Backups aller aktivierten Ordner (Default = false).
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================

# ManifestHint:
#   ExportFunctions: Update-BackupConfig, Run-BackupFromConfig
#   Description: Vollständiges Script-Backup mit Merge-Modus und funktionierendem ZIP-Backup.
#   Category: Tools
#   Tags: Backup, Config, Merge, Hierarchy, PathManager, Recursive, PSCustomObject
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
# 🔧 Helper: PSCustomObject → Hashtable
# ------------------------------------------------------------
function ConvertTo-Hashtable {
    param([Parameter(Mandatory)] $obj)

    $hash = @{}
    if ($obj -is [pscustomobject]) {
        foreach ($prop in $obj.PSObject.Properties) {
            $hash[$prop.Name] = $prop.Value
        }
    }
    elseif ($obj -is [hashtable]) {
        $hash = $obj
    }
    return $hash
}


# ------------------------------------------------------------
# 🔧 Helper: Hierarchische Struktur aufbauen
# ------------------------------------------------------------
function Build-FolderTree {
    param([string]$BasePath)

    $result = @{}

    $folders = Get-ChildItem -Path $BasePath -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $folders) {
        $subTree = Build-FolderTree -BasePath $folder.FullName
        $result[$folder.Name] = [ordered]@{
            Pfad        = $folder.FullName
            Aktiv       = $false
            Unterordner = $subTree
        }
    }
    return $result
}


# ------------------------------------------------------------
# 🔧 Merge-Funktion mit Pfad-Vergleich
# ------------------------------------------------------------
function Merge-FolderTree {
    param(
        [Parameter(Mandatory)] $newTree,
        [Parameter(Mandatory)] $oldTree
    )

    $newTree = ConvertTo-Hashtable $newTree
    $oldTree = ConvertTo-Hashtable $oldTree

    foreach ($key in $newTree.Keys) {
        $newItem = $newTree[$key]
        $matched = $null

        # 🔍 Vergleich über Pfad
        foreach ($oldKey in (ConvertTo-Hashtable $oldTree).Keys) {
            $oldItem = $oldTree[$oldKey]
            if ($null -ne $oldItem.Pfad -and $oldItem.Pfad -eq $newItem.Pfad) {
                $matched = $oldItem
                break
            }
        }

        if ($null -ne $matched) {
            # ✅ Aktiv übernehmen
            $newTree[$key].Aktiv = $matched.Aktiv

            # 🔁 Unterordner rekursiv abgleichen
            if ($newTree[$key].Unterordner.Count -gt 0 -or $matched.Unterordner.Count -gt 0) {
                $newTree[$key].Unterordner = Merge-FolderTree $newTree[$key].Unterordner $matched.Unterordner
            }
        }
    }

    return $newTree
}


# ------------------------------------------------------------
# ⚙️ Funktion: Backup_Config.json (Merge-Modus)
# ------------------------------------------------------------
function Update-BackupConfig {
    param([string]$ConfigPath = (Join-Path $pathMap.Config "Backup_Config.json"))

    Write-Host "`n🧩 Aktualisiere Backup_Config.json (Merge-Modus)..." -ForegroundColor Cyan

    try {
        if (-not (Test-Path $pathMap.Root)) {
            throw "Root-Pfad konnte nicht ermittelt werden."
        }

        # Alte Config laden, falls vorhanden
        $oldConfig = $null
        if (Test-Path $ConfigPath) {
            try {
                $oldConfig = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
                Write-Host "📄 Alte Config geladen – Merge wird durchgeführt." -ForegroundColor DarkGray
            }
            catch {
                Write-Host "⚠️ Alte Config konnte nicht gelesen werden – wird neu erstellt." -ForegroundColor DarkYellow
            }
        }

        # Neue Struktur erstellen
        $rootTree = @{}
        foreach ($prop in $pathMap.PSObject.Properties) {
            $key = $prop.Name
            $folderPath = $prop.Value
            if ($key -eq "Root" -or -not (Test-Path $folderPath)) { continue }

            Write-Host ("📁 Erfasse Struktur: {0}" -f $folderPath) -ForegroundColor DarkGray
            $rootTree[(Split-Path $folderPath -Leaf)] = [ordered]@{
                Pfad        = (Resolve-Path $folderPath).Path
                Aktiv       = $false
                Unterordner = (Build-FolderTree -BasePath $folderPath)
            }
        }

        # Merge durchführen
        if ($oldConfig -and $oldConfig.Ordner) {
            $rootTree = Merge-FolderTree $rootTree $oldConfig.Ordner
        }

        # Speichern
        $config = [ordered]@{
            Version     = "CFG_V1.3.2"
            ErstelltAm  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Root        = (Resolve-Path $pathMap.Root).Path
            Ordner      = $rootTree
        }

        $config | ConvertTo-Json -Depth 15 | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
        Write-Host "✅ Backup_Config.json synchronisiert (Merge abgeschlossen)." -ForegroundColor Green
    }
    catch {
        Write-Host ("❌ Fehler beim Aktualisieren der Config: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}


# ------------------------------------------------------------
# 🔹 Funktion: Run-BackupFromConfig – ZIP-Backup
# ------------------------------------------------------------
function Run-BackupFromConfig {
    param(
        [string]$ConfigPath = (Join-Path $pathMap.Config "Backup_Config.json"),
        [string]$TargetPath = $pathMap.Backup
    )

    Write-Host "`n🗂️  Starte ZIP-Backup anhand Config ..." -ForegroundColor Yellow

    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Host "⚠️ Keine Config vorhanden – wird erstellt." -ForegroundColor DarkYellow
            Update-BackupConfig
        }

        $config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
        $folders = New-Object System.Collections.Generic.List[string]

        # --------------------------------------------------------
        # Rekursive Suche nach aktiven Pfaden (beliebig tief)
        # --------------------------------------------------------
        function Collect-ActivePaths {
            param($Node)

            if ($Node -is [pscustomobject] -or $Node -is [hashtable]) {
                foreach ($prop in $Node.PSObject.Properties) {
                    $item = $prop.Value
                    if ($item -is [pscustomobject] -or $item -is [hashtable]) {
                        if ($item.Aktiv -eq $true -and $item.Pfad) {
                            $folders.Add($item.Pfad)
                        }
                        if ($null -ne $item.Unterordner -and $item.Unterordner.PSObject.Properties.Count -gt 0) {
                            Collect-ActivePaths $item.Unterordner
                        }
                    }
                }
            }
            elseif ($Node -is [System.Collections.IEnumerable]) {
                foreach ($sub in $Node) {
                    Collect-ActivePaths $sub
                }
            }
        }

        Collect-ActivePaths $config.Ordner

        if ($folders.Count -eq 0) {
            Write-Host "⚠️ Keine aktiven Ordner gefunden – nichts zu sichern." -ForegroundColor DarkYellow
            return
        }

        Write-Host ("📦 {0} aktive Ordner erkannt – beginne Backup..." -f $folders.Count) -ForegroundColor Cyan

        if (-not (Test-Path $TargetPath)) {
            New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
        }

        $ok = 0; $skipped = 0; $errors = 0

        foreach ($folder in $folders) {
            if (-not (Test-Path $folder)) {
                Write-Host ("⚠️  Ungültiger Pfad übersprungen: {0}" -f $folder) -ForegroundColor DarkYellow
                continue
            }

            $rel = $folder.Substring($config.Root.Length).TrimStart('\','/') -replace '[\\/]+','__'
            $zipPath = Join-Path $TargetPath ($rel + ".zip")

            $files = Get-ChildItem -Path $folder -File -Recurse -ErrorAction SilentlyContinue
            if (-not $files -or $files.Count -eq 0) {
                Write-Host ("⏭️  Leerer Ordner übersprungen: {0}" -f $folder) -ForegroundColor DarkGray
                $skipped++
                continue
            }

            Write-Host ("📦 Archiviere {0}" -f $rel) -ForegroundColor White

            try {
                if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
                Compress-Archive -Path (Join-Path $folder "*") -DestinationPath $zipPath -Force
                Write-Host ("✅ Archiv erstellt: {0}" -f (Split-Path $zipPath -Leaf)) -ForegroundColor Green
                $ok++
            }
            catch {
                Write-Host ("❌ Fehler beim Archivieren von {0}: {1}" -f $folder, $_.Exception.Message) -ForegroundColor Red
                $errors++
            }
        }

        Write-Host "`n✅ Backup abgeschlossen." -ForegroundColor Green
        Write-Host ("📊 Ergebnis: {0} erstellt, {1} übersprungen, {2} Fehler" -f $ok, $skipped, $errors) -ForegroundColor White
    }
    catch {
        Write-Host ("❌ Fehler im Backup: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}


# ------------------------------------------------------------
# 🧭 Automatischer Start
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -eq ".") {
    Run-BackupFromConfig
}
