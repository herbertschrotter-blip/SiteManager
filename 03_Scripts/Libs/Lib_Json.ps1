# ============================================================
# Library: Lib_Json.ps1
# Version: LIB_V1.4.0
# Zweck:   JSON-Funktionen mit automatischer Erstellung einer Standardkonfiguration
# Autor:   Herbert Schrotter
# Datum:   23.10.2025
# ============================================================
# ManifestHint:
#   ExportFunctions: Get-JsonFile, Save-JsonFile, Add-JsonEntry, Update-JsonValue, Remove-JsonEntry
#   Description: JSON-Bibliothek mit konfigurierbarem Verhalten und automatischer Erstellung von Json_Config.json
#   Category: Core
#   Tags: JSON, Config, IO, PathManager, Logging, AutoCreate
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
        $defaultConfigPath = Join-Path $paths.Config "Json_Config.json"
        $defaultLog = Join-Path $paths.Logs "Json_Log.txt"
    } else {
        $paths = $null
        $defaultConfigPath = Join-Path $PSScriptRoot "Json_Config.json"
        $defaultLog = Join-Path $PSScriptRoot "Json_Log.txt"
    }
}
catch {
    $paths = $null
    $defaultConfigPath = Join-Path $PSScriptRoot "Json_Config.json"
    $defaultLog = Join-Path $PSScriptRoot "Json_Log.txt"
}

# ------------------------------------------------------------
# ⚙️ Standardwerte definieren
# ------------------------------------------------------------
$DefaultJsonConfig = @{
    CreateIfMissing = $true
    WaitTimeMs      = 200
    WaitLoopMax     = 10
    DefaultDepth    = 8
    EnableLogging   = $false
    LogFile         = $defaultLog
}

# ------------------------------------------------------------
# 📘 Konfiguration laden oder neu erstellen
# ------------------------------------------------------------
$JsonConfig = @{}

if (Test-Path $defaultConfigPath) {
    try {
        $userConfig = Get-Content -Path $defaultConfigPath -Raw | ConvertFrom-Json
        foreach ($key in $DefaultJsonConfig.Keys) {
            if ($userConfig.PSObject.Properties.Name -contains $key) {
                $JsonConfig[$key] = $userConfig.$key
            } else {
                $JsonConfig[$key] = $DefaultJsonConfig[$key]
            }
        }
        Write-Host "⚙️ JSON-Konfiguration geladen aus $defaultConfigPath" -ForegroundColor Gray
    }
    catch {
        Write-Host "⚠️ Fehler beim Laden der Json_Config.json – Standardwerte werden verwendet." -ForegroundColor Yellow
        $JsonConfig = $DefaultJsonConfig
    }
} 
else {
    Write-Host "⚠️ Keine Json_Config.json gefunden – Standarddatei wird erstellt." -ForegroundColor Yellow

    # Ordner ggf. anlegen
    $configDir = Split-Path $defaultConfigPath
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # Standarddatei schreiben
    $DefaultJsonConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath $defaultConfigPath -Encoding utf8
    $JsonConfig = $DefaultJsonConfig

    Write-Host "✅ Standardkonfiguration erstellt unter: $defaultConfigPath" -ForegroundColor Green
}

# ------------------------------------------------------------
# 📖 Funktion: Get-JsonFile
# ------------------------------------------------------------
function Get-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$CreateIfMissing
    )

    try {
        if (-not (Test-Path $Path)) {
            if ($CreateIfMissing -or $JsonConfig.CreateIfMissing) {
                @() | ConvertTo-Json -Depth $JsonConfig.DefaultDepth | Set-Content -Path $Path -Encoding utf8
                Start-Sleep -Milliseconds $JsonConfig.WaitTimeMs
            } else {
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

        # Schreiben mit UTF8
        $Data | ConvertTo-Json -Depth $JsonConfig.DefaultDepth | Out-File -FilePath $Path -Encoding utf8 -Force

        # Warte-Loop aus Config
        $maxWait = $JsonConfig.WaitLoopMax
        while (-not (Test-Path $Path) -and $maxWait -gt 0) {
            Start-Sleep -Milliseconds $JsonConfig.WaitTimeMs
            $maxWait--
        }

        if (-not (Test-Path $Path)) {
            throw "Datei konnte nicht erstellt werden: $Path"
        }

        if ($JsonConfig.EnableLogging) {
            Add-Content -Path $JsonConfig.LogFile -Value ("[{0}] WRITE → {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Path)
        }

    }
    catch {
        Write-Host "❌ Fehler beim Schreiben von ${Path}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ------------------------------------------------------------
# ➕ Funktion: Add-JsonEntry
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
