# ============================================================
# 🧩 MANIFEST HINT
# ExportFunctions: Get-ManifestHint, New-ModuleManifestFromHint, Invoke-ManifestScan
# Description: Automatische Erstellung und Pflege von PowerShell Modulmanifesten (.psd1)
# Category: Library
# Tags: SiteManager, Manifest, Generator, Automation
# Dependencies: Lib_Pathmanager, Lib_Json
# ============================================================

# ============================================================
# 🧭 Lib_ManifestGenerator.ps1
# Version: LIB_V1.1.0
# Zweck:   Erstellt und aktualisiert Modulmanifeste (.psd1) und pflegt Module_Registry.json
# Autor:   Herbert Schrotter
# Datum:   22.10.2025
# ============================================================

# ------------------------------------------------------------
# ⚙️ Globale Standardpfade
# ------------------------------------------------------------
$Global:ManifestRoot = "$PSScriptRoot"                             # Speicherort der Libs
$Global:InfoRoot     = Join-Path $PSScriptRoot "..\..\00_Info"     # Registry & Status
$Global:LogRoot      = Join-Path $PSScriptRoot "..\..\04_Logs"     # Scan-Logs
$Global:RegistryPath = Join-Path $InfoRoot "Module_Registry.json"  # zentrale Registry-Datei
$Global:StatusPath   = Join-Path $InfoRoot "Module_Status.md"      # Statusbericht

# ------------------------------------------------------------
# 🧠 MANIFEST HINT-BLOCK PARSEN
# ------------------------------------------------------------
function Get-ManifestHint {
    <#
        .SYNOPSIS
            Liest den MANIFEST HINT Block aus einer Moduldatei (.ps1 oder .psm1)
        .PARAMETER Path
            Pfad zur Quelldatei (z. B. Lib_Json.psm1)
        .OUTPUTS
            Hashtable mit allen gefundenen Werten
    #>
    param([Parameter(Mandatory)][string]$Path)

    if (!(Test-Path $Path)) {
        Write-Warning "❌ Datei nicht gefunden: $Path"
        return $null
    }

    $content = Get-Content $Path -Raw
    $pattern = '(?s)#\s*🧩 MANIFEST HINT(.*?)#\s*={10,}'
    $match = [regex]::Match($content, $pattern)

    if (-not $match.Success) {
        Write-Warning "⚠️ Kein ManifestHint-Block in $Path gefunden."
        return $null
    }

    $block = $match.Groups[1].Value -split "`n"
    $hint = @{}
    foreach ($line in $block) {
        if ($line -match '#\s*(\w+):\s*(.*)') {
            $key = $matches[1]
            $value = $matches[2].Trim()
            $hint[$key] = $value
        }
    }
    return $hint
}

# ------------------------------------------------------------
# 🧱 MANIFESTDATEI ERSTELLEN ODER AKTUALISIEREN
# ------------------------------------------------------------
function New-ModuleManifestFromHint {
    <#
        .SYNOPSIS
            Erstellt oder aktualisiert eine .psd1-Datei auf Basis des MANIFEST HINT
        .PARAMETER Path
            Pfad zur Quelldatei (.ps1 oder .psm1)
        .OUTPUTS
            Pfad der erstellten oder aktualisierten .psd1-Datei
    #>
    param([Parameter(Mandatory)][string]$Path)

    try {
        $hint = Get-ManifestHint -Path $Path
        if (-not $hint) { return }

        $moduleName   = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $manifestPath = [System.IO.Path]::ChangeExtension($Path, ".psd1")

        # Zeitvergleich: nur aktualisieren, wenn Modul neuer als Manifest
        $modTime  = (Get-Item $Path).LastWriteTime
        $psdTime  = if (Test-Path $manifestPath) { (Get-Item $manifestPath).LastWriteTime } else { [datetime]::MinValue }

        if ($modTime -le $psdTime) {
            Write-Host "✅ Manifest aktuell: $moduleName"
            return
        }

        $guid = if (Test-Path $manifestPath) {
            try { (Import-PowerShellDataFile $manifestPath).GUID } catch { [guid]::NewGuid().ToString() }
        } else { [guid]::NewGuid().ToString() }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $psd1 = @{
            RootModule        = "$moduleName.psm1"
            ModuleVersion     = "1.0.0"
            GUID              = $guid
            Author            = "Herbert Schrotter"
            LastWrite         = $timestamp
            Description       = $hint["Description"]
            Category          = $hint["Category"]
            Tags              = @($hint["Tags"] -split ',\s*')
            FunctionsToExport = @($hint["ExportFunctions"] -split ',\s*')
            RequiredModules   = @($hint["Dependencies"] -split ',\s*')
            PowerShellVersion = "7.3"
        }

        $psd1 | Out-File -FilePath $manifestPath -Encoding UTF8
        Write-Host "🔄 Manifest aktualisiert: $moduleName"

        # Update Registry
        Update-ModuleRegistry -ModuleName $moduleName -Manifest $psd1 -Path $Path
        return $manifestPath
    }
    catch {
        Write-Warning "❌ Fehler beim Erstellen/Aktualisieren des Manifests: $_"
    }
}

# ------------------------------------------------------------
# 🧩 MODULE REGISTRY PFLEGEN
# ------------------------------------------------------------
function Update-ModuleRegistry {
    <#
        .SYNOPSIS
            Aktualisiert oder erstellt die zentrale Module_Registry.json
        .PARAMETER ModuleName
            Name des Moduls (z. B. Lib_Json)
        .PARAMETER Manifest
            Hashtable mit Manifestdaten
        .PARAMETER Path
            Pfad zur Quelldatei (.psm1)
    #>
    param(
        [string]$ModuleName,
        [hashtable]$Manifest,
        [string]$Path
    )

    # Registry laden oder neu anlegen
    $registry = @{}
    if (Test-Path $Global:RegistryPath) {
        try { $registry = Get-Content $Global:RegistryPath -Raw | ConvertFrom-Json } catch { $registry = @{} }
    }

    $entry = @{
        Version       = $Manifest.ModuleVersion
        GUID          = $Manifest.GUID
        LastWrite     = (Get-Item $Path).LastWriteTime
        Dependencies  = $Manifest.RequiredModules
        Description   = $Manifest.Description
        Category      = $Manifest.Category
    }

    $registry[$ModuleName] = $entry
    $json = $registry | ConvertTo-Json -Depth 4
    $json | Out-File -FilePath $Global:RegistryPath -Encoding UTF8

    Write-Host "🗂️ Registry aktualisiert: $ModuleName → $($Global:RegistryPath)"
}

# ------------------------------------------------------------
# 🔍 MANIFEST-SCAN FÜR EINEN ORDNER
# ------------------------------------------------------------
function Invoke-ManifestScan {
    <#
        .SYNOPSIS
            Scannt ein Verzeichnis nach Modulen und erstellt/aktualisiert .psd1 + Registry
        .PARAMETER Path
            Pfad zum Modulverzeichnis (z. B. 03_Scripts\Libs)
    #>
    param([Parameter(Mandatory)][string]$Path)

    if (!(Test-Path $Path)) {
        Write-Warning "❌ Pfad nicht gefunden: $Path"
        return
    }

    Write-Host "`n📦 Starte Manifest-Scan in: $Path`n"

    $modules = Get-ChildItem $Path -Filter "*.psm1"
    foreach ($m in $modules) {
        New-ModuleManifestFromHint -Path $m.FullName
    }

    Write-Host "`n✅ Manifest-Scan abgeschlossen. Registry: $($Global:RegistryPath)`n"
}
