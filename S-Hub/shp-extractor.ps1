<#

>>==SCRIPT PARAMETERS==<<
$s_Path                     - path to .shp package
$s_RMSettingsFolder         - path to rainmeter settings folder

#>

param(
    [Parameter(Mandatory=$true)][Alias("path")][ValidateNotNullOrEmpty()][string]$s_Path,
    [Parameter(Mandatory=$true)][Alias("rmpath")][ValidateNotNullOrEmpty()][string]$s_RMSettingsFolder,
    [Alias("dev")][switch]$o_noAction
) 

$ErrorActionPreference = 'SilentlyContinue'

# ---------------------------------------------------------------------------- #
#                                   Functions                                  #
# ---------------------------------------------------------------------------- #

# -------------------------------- Write-Host -------------------------------- #

function Write-Task ([string] $Text) {
  Write-Host $Text -NoNewline
}

function Write-Done {
  Write-Host " > " -NoNewline
  Write-Host "OK" -ForegroundColor "Green"
}

function Write-Emphasized ([string] $Text) {
  Write-Host $Text -NoNewLine -ForegroundColor "Cyan"
}

function Write-Info ([string] $Text) {
  Write-Host $Text -ForegroundColor "Yellow"
}

function Write-Fail ([string] $Text) {
  Write-Host $Text -ForegroundColor "Red"
}

function debug ([string] $Text) {
  Write-Host $Text
}

# ------------------------------------ Ini ----------------------------------- #

function Get-IniContent ($filePath) {
    $ini = [ordered]@{}
    if (![System.IO.File]::Exists($filePath)) {
        throw "$filePath invalid"
    }
    # $section = ';ItIsNotAFuckingSection;'
    # $ini.Add($section, [ordered]@{})

    foreach ($line in [System.IO.File]::ReadLines($filePath)) {
        if ($line -match "^\s*\[(.+?)\]\s*$") {
            $section = $matches[1]
            $secDup = 1
            while ($ini.Keys -contains $section) {
                $section = $section + '||ps' + $secDup
            }
            $ini.Add($section, [ordered]@{})
        }
        elseif ($line -match "^\s*;.*$") {
            $notSectionCount = 0
            while ($ini[$section].Keys -contains ';NotSection' + $notSectionCount) {
                $notSectionCount++
            }
            $ini[$section][';NotSection' + $notSectionCount] = $matches[1]
        }
        elseif ($line -match "^\s*(.+?)\s*=\s*(.+?)$") {
            $key, $value = $matches[1..2]
            $ini[$section][$key] = $value
        }
        else {
            $notSectionCount = 0
            while ($ini[$section].Keys -contains ';NotSection' + $notSectionCount) {
                $notSectionCount++
            }
            $ini[$section][';NotSection' + $notSectionCount] = $line
        }
    }

    return $ini
}

function Set-IniContent($ini, $filePath) {
    $str = @()
    foreach ($section in $ini.GetEnumerator()) {
        if ($section -ne ';ItIsNotAFuckingSection;') {
            $str += "[" + ($section.Key -replace '\|\|ps\d+$', '') + "]"
        }
        foreach ($keyvaluepair in $section.Value.GetEnumerator()) {
            if ($keyvaluepair.Key -match "^;NotSection\d+$") {
                $str += $keyvaluepair.Value
            }
            else {
                $str += $keyvaluepair.Key + "=" + $keyvaluepair.Value
            }
        }
    }
    $finalStr = $str -join [System.Environment]::NewLine
    $finalStr | Out-File -filePath $filePath -Force -Encoding unicode
}

# ----------------------------------- Copy ----------------------------------- #

function Copy-Path {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]$Source,

        [Parameter(Position = 1)]
        [string]$Destination,

        [string[]]$ExcludeFolders = $null,
        [switch]$IncludeEmptyFolders
    )
    $Source      = $Source.TrimEnd("\")
    $Destination = $Destination.TrimEnd("\")

    Get-ChildItem -Path $Source -Recurse | ForEach-Object {
        if ($_.PSIsContainer) {
            # it's a folder
            if ($ExcludeFolders.Count) {
                if ($ExcludeFolders -notcontains $_.Name -and $IncludeEmptyFolders) {
                    # create the destination folder, even if it is empty
                    $target = Join-Path -Path $Destination -ChildPath $_.FullName.Substring($Source.Length)
                    if (!(Test-Path $target -PathType Container)) {
                        # Write-Verbose "Create folder $target"
                        New-Item -ItemType Directory -Path $target | Out-Null
                    }
                }
            }
        }
        else {
            # it's a file
            $copy = $true
            if ($ExcludeFolders.Count) {
                # get all subdirectories in the current file path as array
                $subs = $_.DirectoryName.Replace($Source,"").Trim("\").Split("\")
                # check each sub folder name against the $ExcludeFolders array
                foreach ($folderName in $subs) {
                    if ($ExcludeFolders -contains $folderName) { $copy = $false; break }
                }
            }

            if ($copy) {
                # create the destination folder if it does not exist yet
                $target = Join-Path -Path $Destination -ChildPath $_.DirectoryName.Substring($Source.Length)
                if (!(Test-Path $target -PathType Container)) {
                    # Write-Verbose "Create folder $target"
                    New-Item -ItemType Directory -Path $target | Out-Null
                }
                # Write-Verbose "Copy file $($_.FullName) to $target"
                $_ | Copy-Item -Destination $target -Force
            }
        }
    }
}

# --------------------------------- Wallpaper -------------------------------- #

Function Set-WallPaper($Image) {  
Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;
  
public class Params
{ 
    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
    public static extern int SystemParametersInfo (Int32 uAction, 
                                                   Int32 uParam, 
                                                   String lpvParam, 
                                                   Int32 fuWinIni);
}
"@ 
  
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
  
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
  
    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
 
}

# ---------------------------------------------------------------------------- #
#                                     Start                                    #
# ---------------------------------------------------------------------------- #

# Test: .\S-Hub\shp-extractor.ps1 "C:\Users\Jax\AppData\Roaming\JaxCore\CoreData\S-Hub\Exports\Jax's Setup.shp" -rmpath "C:\Users\Jax\AppData\Roaming\Rainmeter"
# -dev

Write-Info "SHPEXTRACTOR REF: Experimental v1"
# ---------------------------- Installer variables --------------------------- #
$s_RMINIFile = "$s_RMSettingsFolder\Rainmeter.ini"
$RMEXEloc = "$s_RMSettingsFolder\Rainmeter.exe"
# Get the set skin path
If (Test-Path $s_RMINIFile) {
    $Ini = Get-IniContent $s_RMINIFile
    $s_RMSkinFolder = $Ini["Rainmeter"]["SkinPath"]
    $Ini = $null
} else {
    Write-Fail "Unable to locate $s_RMINIFile."
    Write-Info "S-Hub packages requires Rainmeter to be installed at the moment."
    Return
}

Write-Info "Getting required information..."
# -------------------------------- Get rm bit -------------------------------- #
If (Get-Process Rainmeter -ErrorAction SilentlyContinue) {
    $rmprocess_object = Get-Process Rainmeter
    $rmprocess_id = $rmprocess_object.id
    Write-Task "Getting Rainmeter bitness..."
    $bit = '32bit'
    Get-Process -Id $rmprocess_id | Foreach {
        $modules = $_.modules
        foreach($module in $modules) {
            $file = [System.IO.Path]::GetFileName($module.FileName).ToLower()
            if($file -eq "wow64.dll") {
                $bit = "32bit"
                Break
            } else {
                $bit = "64bit"
            }
        }
    }
} else {
    Write-Fail "S-Hub extractor requires Rainmeter running in the background to get the appropriate bit for plugins."
    Return
}
Write-Done
# ---------------------------------- Screen ---------------------------------- #
Write-Task "Getting screen sizes"
$vc = Get-WmiObject -class "Win32_VideoController"
$saw = $vc.CurrentHorizontalResolution
$sah = $vc.CurrentVerticalResolution
Write-Done
# ---------------------------- Create cache folder --------------------------- #
$s_cache_location = "$s_RMSkinFolder..\CoreData\S-Hub\Import_Cache"
If (!($o_noAction)) {
    If (Test-Path -Path "$s_cache_location") {
        Remove-Item "$s_cache_location" -Recurse -Force
    }
    New-Item -Path "$s_cache_location" -ItemType "Directory" > $null
}
# ------------------------------- Unzip pacakge ------------------------------ #
Write-Task "Expanding $s_Path to $s_cache_location"
If (!($o_noAction) -or !(Test-Path "$s_cache_location\SHP-data.ini")) {
    Copy-Item -Path "$s_Path" -Destination "$s_cache_location\$($s_Path | Split-Path -Leaf).zip"
    $ProgressPreference = 'SilentlyContinue'
    Expand-Archive -Path "$s_cache_location\$($s_Path | Split-Path -Leaf).zip" -DestinationPath "$s_cache_location" -Force
    Remove-Item "$s_cache_location\$($s_Path | Split-Path -Leaf).zip"
} 
Write-Done
# --------------------------------- SHP data --------------------------------- #
$Ini = Get-IniContent "$s_cache_location\SHP-data.ini"
$s_SHPdataini = $Ini
$shp_name = $s_SHPdataini["Data"]["SetupName"]
If ($shp_name -eq $null) {
    Write-Fail "Invalid SHP package file."
    Return
}
# ------------------------------- Start extract ------------------------------ #
Write-Info "Starting extraction..."
debug "-----------------"
debug "SetupDir: $s_Path"
debug "SetupName: $shp_name"
debug "RainmeterPluginsBit: $bit"
debug "RainmeterPath: $s_RMSettingsFolder"
debug "RainmeterExePath: $RMEXEloc"
debug "RainmeterSkinsPath: $s_RMSkinFolder"
debug "ScreenAreaSizes: $saw x $sah"
debug "-----------------"
# ---------------------------- Read shup-data.ini ---------------------------- #
If (Test-Path -Path "$s_cache_location\RainmeterSkins\*") {
    Write-Info "Rainmeter found in package"
    Write-Task "Moving Rainmeter skins & layouts"
    # Move Rainmeter layout
    If (!($o_noAction)) {
        New-Item -Path "$s_RMSettingsFolder\Layouts\$shp_name" -ItemType "Directory" > $null
        Move-Item -Path "$s_cache_location\Rainmeter.ini" -Destination "$s_RMSettingsFolder\Layouts\$shp_name" -Force
        Move-Item -Path "$s_cache_location\RainmeterSkins\*" -Destination "$s_RMSkinFolder" -Force
    } else {
        New-Item -Path "$s_RMSettingsFolder\Layouts\$shp_name" -ItemType "Directory" -WhatIf
        Move-Item -Path "$s_cache_location\Rainmeter.ini" -Destination "$s_RMSettingsFolder\Layouts\$shp_name" -Force -WhatIf
        Move-Item -Path "$s_cache_location\RainmeterSkins\*" -Destination "$s_RMSkinFolder" -Force -WhatIf
    }
    # Move Rainmeter skins
    Write-Done
}
# --------------------------------- Spicetify -------------------------------- #
If (Test-Path -Path "$s_cache_location\AppSkins\Spicetify\*") {
    Write-Info "Spicetify found in package (pre)"
    try {spicetify.exe > $null}
    catch {$spicetify_detected = $false}

    If ($spicetify_detected -ne $false) {
        Write-Info 'Spicetify found in local (set)'
        $spicetifyconfig_path = spicetify.exe -c
        $spicetify_path = "$spicetifyconfig_path\..\"

        If (!($o_noAction)) {
            # Get-Process 'Spotify' | Stop-Process

            debug "Applying settings"
            spicetify.exe config current_theme $s_SHPdataini["Spicetify"]["current_theme"]
            spicetify.exe config color_scheme $s_SHPdataini["Spicetify"]["color_scheme"]
            
            debug "Copying theme assets to themes folder"
            New-Item -Path "$spicetify_path\Themes\$($s_SHPdataini["Spicetify"]["current_theme"])" -Type "Directory"
            Move-Item -Path "$s_cache_location\AppSkins\Spicetify\*" -Destination "$($spicetify_path)Themes\$($s_SHPdataini["Spicetify"]["current_theme"])"

            debug "Applying spicetify theme"
            ECHO Y | spicetify.exe apply
        }

        Write-Task "Spicetify"
        Write-Done
    } else {
        Write-Info 'Spicetify not found in local (nil)'
    }
}
# ------------------------------- BetterDiscord ------------------------------ #
If (Test-Path -Path "$s_cache_location\AppSkins\BetterDiscord\*") {
    Write-Info "BetterDiscord found in package (pre)"
    $bd_path = "$env:APPDATA\BetterDiscord"
    If (Test-Path -Path $bd_path) {
        Write-Info 'BetterDiscord found in local (set)'
        $bd_data_folders = Get-ChildItem -Path "$bd_path\data" -Directory

        If (!($o_noAction)) {
            If ($bd_data_folders.Count -eq 1) {
                $bd_selected_folder = $bd_data_folders
            } else {
                $bd_selected_folder = $bd_data_folders[0]
            }
            debug "Found bd:$bd_selected_folder"
            $option_bdtheme = "$($s_SHPdataini["BetterDiscord"]["themename"])"

            Get-Process | Where-Object -Property ProcessName -match "^Discord.*" | Stop-Process

            $bd_themes = Get-Content -Path "$bd_path\data\$($bd_selected_folder)\themes.json" | ConvertFrom-Json
            $bd_themes | Add-Member -NotePropertyName "$option_bdtheme" -NotePropertyValue $true -Force
            $bd_themes | ConvertTo-Json -depth 2 | Out-File "$bd_path\data\$($bd_selected_folder)\themes.json" -Force
            
            Move-Item -Path "$s_cache_location\AppSkins\BetterDiscord\*" -Destination "$bd_path\themes\" -Force
        }

        Write-Task "BetterDiscord"
        Write-Done
    } else {
        Write-Info 'BetterDiscord not found in local (nil)'
    }
}
# ---------------------------------- Firefox --------------------------------- #
If (Test-Path -Path "$s_cache_location\AppSkins\Firefox\*") {
    Write-Info "Firefox found in package (pre)"
    $ff_path = "$env:APPDATA\Mozilla\Firefox\"
    $ffconfig_path = "$($ff_path)profiles.ini"
    If (Test-Path -Path $ffconfig_path) {
        Write-Info 'Firefox found in local (set)'
        If (!($o_noAction)) {
            # $Ini = Get-IniContent $ffconfig_path
            # $ff_currentuserprofile = $Ini[0]["Default"]
            # $ff_newprofile = "Profiles/JaxCore_SHP.$shp_name"
            # for ($i = 1;$i -le 20; $i++) {
            #     If ($Ini["Profile$i"].Count -eq 0) {
            #         debug "Creating new section `"Profile$i`""
            #         $Ini["Profile$i"] = @{Name = "$shp_name"; IsRelative = 1; Path = "$ff_newprofile"}
            #         Break
            #     }
            # }
            # $Ini[0]["Default"] = $ff_newprofile
            # Set-IniContent $Ini $ffconfig_path

            Get-Process 'Firefox' | Stop-Process

            # New-Item -Path "$($ff_path)$ff_newprofile" -Type "Directory"
            # debug "Copying current user profile as base, might take a while..."
            # Copy-Path -Source "$($ff_path)$ff_currentuserprofile" -Destination "$($ff_path)$ff_newprofile\"
            debug "Moving userChrome.css"
            New-Item -Path "$($ff_path)$ff_newprofile\chrome" -Type "Directory" > $null
            Move-Item -Path "$s_cache_location\AppSkins\Firefox\userChrome.css" -Destination "$($ff_path)$ff_newprofile\chrome" -Force
        }

        Write-Task "Firefox"
        Write-Done
    } else {
        Write-Info 'Firefox not found in local (nil)'
    }
}

# --------------------------------- Wallpaper -------------------------------- #

Write-Info "Applying wallpaper..."
$wallpaper_name = Get-Item "$s_cache_location\Wallpaper\*" | Select-Object Name
Write-Task "Moving and setting wallpaper from `"$s_cache_location\Wallpaper\$($wallpaper_name.Name)`""
If (!($o_noAction)) {
    Move-Item -Path "$s_cache_location\Wallpaper\$($wallpaper_name.Name)" -Destination "C:\Users\$env:UserName\Pictures" -Force
    Set-WallPaper "C:\Users\$env:UserName\Pictures\$($wallpaper_name.Name)"
}
Write-Done

# ------------------------------------ .. ------------------------------------ #
Write-Info "Finalizing"
Write-Task "Clearing cache and applying changes"
If (!($o_noAction)) {
    & "$RMEXEloc" [!LoadLayout "$shp_name"]
    If (Test-Path -Path $ffconfig_path) {
        Start-Process Firefox
    }
    # If ($spicetify_detected -ne $false) {
    #     $spotifyPath = spicetify.exe config spotify_path
    #     Start-Process "$spotifyPath\Spotify.exe"
    # }
    Remove-Item -Path "$s_cache_location\*" -Recurse
}
Write-Done