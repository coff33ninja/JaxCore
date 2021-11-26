$skinsList = @('ModularClocks', 'IdleStyle')

$api = "https://api.github.com/repos/Jax-Core/{skin}/releases/latest"

$root = $RmAPI.VariableStr("@") + "CoreInstaller"
$resources = $RmAPI.VariableStr('@')
$skinsPath = $RmAPI.VariableStr('SKINSPATH')

$coreinstaller = $RmAPI.VariableStr('CURRENTCONFIG')

function Get-Skin {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $skin
    )

    Lock-Buttons

    if ($skinsList -notcontains $skin) {
        $RmAPI.LogError("CoreInstaller: Skin name `"$skin`" invalid (Error: 1)")
        return
    }

    $releaseInfo = (Invoke-WebRequest -Uri "$($api -replace '{skin}', $skin)" -UseBasicParsing).Content | ConvertFrom-Json

    $downloadUri = ''
    $releaseInfo.assets | ForEach-Object {
        if ($_.name -match "^$skin.zip$"){
            $downloadUri = $_.browser_download_url
        }
    }

    $RmApi.Bang("!SetClip $downloadUri")

    debug("Parsed download url: `"$downloadUri`"")
    
    New-Cache # reset the cache folder

    Get-Webfile $downloadUri "$root\cache\$skin.zip"

    debug("CoreInstaller: Successfully downloaded `"$skin.zip`"")

    $RmAPI.Bang("[!SetVariable Progress `"0`"][!SetVariable InstallText `"Extracting files`"][!UpdateMeterGroup Progress][!Redraw]")

    Expand-Archive -LiteralPath "$root\cache\$skin.zip" -DestinationPath "$root\cache\$skin"

    $intermediateFolderName = ''
    Get-ChildItem "$root\cache\Raw$skin" -Directory | ForEach-Object{
        $intermediateFolderName = $_.Name
    }

    Start-Sleep -Milliseconds 200
    # Move the skins

    &"$root\Helpers\InstallVariables.ps1" -skin $skin

    $RmAPI.Bang("[!SetVariable Progress `"70`"][!SetVariable InstallText `"Installing skin`"][!UpdateMeterGroup Progress][!Redraw]")

    Remove-Item -LiteralPath "$skinsPath\$skin" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath "$root\cache\$skin\Skins" -Destination "$skinsPath$skin" -Recurse -Force

    Start-Sleep -Milliseconds 200

    $RmAPI.Bang("[!SetVariable Progress `"90`"][!SetVariable InstallText `"Installing plugins`"][!UpdateMeterGroup Progress][!Redraw]")

    $RmAPI.Bang('[!WriteKeyValue Rainmeter OnRefreshAction "[!Hide]"]')

    Start-Sleep -Milliseconds 500

    $osbits = "32-bit"
    if ([Environment]::Is64BitOperatingSystem){ $osbits = "64-bit" }

    $pluginsDir = "`"$root\cache\$skin\Plugins`""
    $rmPluginsDir = "`"$($RmAPI.VariableStr('SETTINGSPATH'))Plugins`""
    $rmPath = "`"$($RmAPI.VariableStr('PROGRAMPATH'))Rainmeter.exe`""
    $postBang = "`"[!CommandMeasure DelayedBanger \`"finalize('$skin')\`" \`"$coreinstaller\`"]`""

    Start-Process "$root\Helpers\PluginsInstaller\$osbits\PluginsInstaller.exe" "--pluginsDir $pluginsDir --rmPluginsDir $rmPluginsDir --rmPath $rmPath --postBangs $postBang --bangDelay 500"
}

function Finalize-Installation{
    param(
        [Parameter()]
        [string]
        $skin
    )
    
    New-Cache
    $RmAPI.Bang("[!WriteKeyvalue Variables Skin.Name $skin `"$($resources)SecVar.inc`"][!WriteKeyvalue Variables Skin.Set_Page Info `"$($resources)SecVar.inc`"][!ActivateConfig `"#JaxCore\Main`" `"Settings.ini`"]")
    $RmAPI.Bang('[!WriteKeyValue Rainmeter OnRefreshAction "[!Hide][!SetWindowPosition 50% 50% 50% 50%][!Show]"]')
    $RmAPI.Bang("!DeactivateConfig")
}
function Lock-Buttons{
    $RmAPI.Bang("[!SetVariable TextColor 373737][!SetVariable ButtonColor 909090][!DisableMouseAction Install `"LeftMouseUpAction`"][!Update]")
}
function New-Cache {
    [System.IO.Directory]::CreateDirectory("$root\cache") | Out-Null
    Get-ChildItem "$root\cache" | ForEach-Object {
        Remove-Item $_.FullName -Force -Recurse
    }
}

function debug {
    param(
        [Parameter()]
        [string]
        $message
    )

    $RmAPI.Bang("[!Log `"`"`"CoreInstaller: " + $message + "`"`"`" Debug]")
}
function warning {
    param(
        [Parameter()]
        [string]
        $message
    )

    $RmAPI.Bang("[!Log `"`"`"CoreInstaller: " + $message + "`"`"`" Warning]")
}
function error {
    param(
        [Parameter()]
        [string]
        $message
    )

    $RmAPI.Bang("[!Log `"`"`"CoreInstaller: " + $message + "`"`"`" Error]")
}
function notice {
    param(
        [Parameter()]
        [string]
        $message
    )

    $RmAPI.Bang("[!Log `"`"`"CoreInstaller: " + $message + "`"`"`"]")
}

function Get-Webfile ($url, $dest)
{
    debug "Downloading $url`n"
    $uri=New-Object "System.Uri" "$url"
    $request=[System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(5000)
    $response=$request.GetResponse()
    $length=$response.get_ContentLength()
    $responseStream=$response.GetResponseStream()
    $destStream=New-Object -TypeName System.IO.FileStream -ArgumentList $dest, Create
    $buffer=New-Object byte[] 100KB
    $count=$responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes=$count

    while ($count -gt 0)
    {
        $RmAPI.Bang("[!SetVariable Progress `"$([System.Math]::Round(($downloadedBytes / $length) * 100,0))`"][!SetVariable InstallText `"Downloading [#Progress]%`"][!UpdateMeterGroup Progress][!Redraw]")
        $destStream.Write($buffer, 0, $count)
        $count=$responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes+=$count
    }

    debug "`nDownload of `"$dest`" finished."
    $destStream.Flush()
    $destStream.Close()
    $destStream.Dispose()
    $responseStream.Dispose()
}