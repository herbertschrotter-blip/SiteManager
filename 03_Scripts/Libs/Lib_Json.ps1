# ============================================================
# Library: Lib_Json.ps1
# Version: LIB_V1.1.0
# Zweck:   Universelle JSON-Lese-, Schreib- und Erstellfunktionen
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Get-JsonFile, Save-JsonFile, Add-JsonEntry, Update-JsonValue, Remove-JsonEntry
#   Description: Universelle JSON-Bibliothek mit optionaler Integration des PathManagers für zentrale Pfade
#   Category: Core
#   Tags: JSON, Data, Config, Logging, Framework, PathManager
#   Dependencies: (optional) Lib_PathManager.ps1
# ============================================================

# ------------------------------------------------------------
# ⚙️ Optional: PathManager laden (wenn vorhanden)
# ------------------------------------------------------------
try {
    $pathManager = "$PSScriptRoot\..\Libs\Lib_PathManager.ps1"
    if (Test-Path $pathManager) {
        . $pathManager
        $paths = Get-PathMap
        $defaultLog = Join-Path $paths.Logs "Json_Log.txt"
    }
    else {
        $paths = $null
        $defaultLog = Join-Path $PSScriptRoot "Json_Log.txt"
    }
}
catch {
    $paths = $null
    $defaultLog = Join-Path $PSScriptRoot "Json_Log.txt"
}

# ------------------------------------------------------------
# 📖 Funktion: Get-JsonFile
# Zweck:   Liest eine JSON-Datei und gibt deren Inhalt als Objekt zurück.
# ------------------------------------------------------------
function Get-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CreateIfMissing
    )

    try {
        if (-not (Test-Path $Path)) {
            if ($CreateIfMissing) {
                @() | ConvertTo-Json -Depth 4 | Set-Content -Path $Path -Encoding utf8
            }
            else {
                throw "Datei nicht gefunden: ${Path}"
            }
        }

        $content = Get-Content $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) { return @() }

        $json = $content | ConvertFrom-Json -ErrorAction Stop
        return ,$json
    }
    catch {
        Write-Host "❌ Fehler beim Lesen von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# ------------------------------------------------------------
# 💾 Funktion: Save-JsonFile
# Zweck:   Speichert ein beliebiges Objekt als JSON-Datei.
# ------------------------------------------------------------
function Save-JsonFile {
    param(
        [Parameter(Mandatory)][object]$Data,
        [Parameter(Mandatory)][string]$Path
    )

    try {
        # Sicherstellen, dass Zielverzeichnis existiert
        $dir = Split-Path $Path
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        # Speichern mit UTF8 (ohne BOM)
        $Data | ConvertTo-Json -Depth 8 | Set-Content -Path $Path -Encoding utf8
    }
    catch {
        Write-Host "❌ Fehler beim Schreiben von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ➕ Funktion: Add-JsonEntry
# Zweck:   Fügt einen neuen Datensatz zu einer JSON-Datei hinzu.
# ------------------------------------------------------------
function Add-JsonEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object]$Entry
    )

    try {
        $jsonData = Get-JsonFile -Path $Path -CreateIfMissing

        if (-not ($jsonData -is [System.Collections.IEnumerable]) -or ($jsonData -is [string])) {
            $jsonData = @($jsonData)
        }
        if ($jsonData.Count -eq 0 -or ($jsonData.Count -eq 1 -and -not $jsonData[0])) {
            $jsonData = @()
        }

        $jsonData += $Entry
        Save-JsonFile -Data $jsonData -Path $Path
    }
    catch {
        Write-Host "❌ Fehler beim Hinzufügen zu ${Path}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# 🔄 Funktion: Update-JsonValue
# Zweck:   Aktualisiert gezielt einen Wert in einer JSON-Datei.
# Beispiel: Update-JsonValue -Path $p -Key "DebugMode" -Value $false
# ------------------------------------------------------------
function Update-JsonValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][object]$Value
    )

    try {
        $json = Get-JsonFile -Path $Path -CreateIfMissing
        if ($null -eq $json) { $json = @{} }

        if ($json.PSObject.Properties.Name -contains $Key) {
            $json.$Key = $Value
        }
        else {
            Add-Member -InputObject $json -NotePropertyName $Key -NotePropertyValue $Value
        }

        Save-JsonFile -Data $json -Path $Path
    }
    catch {
        Write-Host "❌ Fehler beim Aktualisieren von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ❌ Funktion: Remove-JsonEntry
# Zweck:   Löscht Einträge in JSON-Arrays anhand eines Feldwerts.
# Beispiel: Remove-JsonEntry -Path $p -Key "Projektname" -Value "Testprojekt"
# ------------------------------------------------------------
function Remove-JsonEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value
    )

    try {
        $jsonData = Get-JsonFile -Path $Path -CreateIfMissing
        if (-not ($jsonData -is [System.Collections.IEnumerable])) {
            Write-Host "⚠️ JSON-Datei enthält keine Liste: ${Path}" -ForegroundColor Yellow
            return
        }

        $beforeCount = $jsonData.Count
        $jsonData = $jsonData | Where-Object { $_.$Key -ne $Value }
        $afterCount = $jsonData.Count

        Save-JsonFile -Data $jsonData -Path $Path
    }
    catch {
        Write-Host "❌ Fehler beim Entfernen aus ${Path}: $($_.Exception.Message)" -ForegroundColor Red
    }
}
