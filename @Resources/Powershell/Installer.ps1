function InitInstall { 
    $url = $RmAPI.VariableStr('DownloadLink')
    $name = $RmAPI.VariableStr('DownloadName')
    $RmAPI.Bang("[!CommandMeasure Func `"interactionBox('Install', '$name', '$url')`"]")
}

function debug {
    param(
        [Parameter()]
        [string]
        $message
    )

    $RmAPI.Bang("[!Log `"`"`"CoreInstaller: " + $message + "`"`"`" Debug]")
}

function Get-Webfile ($url, $dest) {
    debug "Downloading $url`n"
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(5000)
    $response = $request.GetResponse()
    $length = $response.get_ContentLength()
    $responseStream = $response.GetResponseStream()
    $destStream = New-Object -TypeName System.IO.FileStream -ArgumentList $dest, Create
    $buffer = New-Object byte[] 100KB
    $count = $responseStream.Read($buffer, 0, $buffer.length)
    $downloadedBytes = $count

    while ($count -gt 0) {
        $RmAPI.Bang("[!SetVariable Progress `"$([System.Math]::Round(($downloadedBytes / $length) * 100,0))`"][!SetVariable InstallText `"Downloading [#Progress]%`"][!UpdateMeterGroup Progress][!Redraw]")
        $destStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer, 0, $buffer.length)
        $downloadedBytes += $count
    }

    debug "`nDownload of `"$dest`" finished."
    $destStream.Flush()
    $destStream.Close()
    $destStream.Dispose()
    $responseStream.Dispose()
}

function Install {
    $url = $RmAPI.VariableStr('sec.arg2')
    $name = $RmAPI.VariableStr('sec.arg1')
    $outPath = "C:/Windows/Temp/$name.rmskin"

    Get-Webfile $url $outPath

    $RmAPI.Bang("[!SetVariable InstallText `"Running installer...`"][!UpdateMeterGroup Progress][!Redraw]")

    Start-Process -FilePath $outPath

    If ($Null -NotMatch (get-process "SkinInstaller" -ea SilentlyContinue)) {
        If ($name -notcontains 'JaxCore') {
            $wshell = New-Object -ComObject wscript.shell
            $wshell.AppActivate('Rainmeter Skin Installer')
            Start-Sleep -s 2
            $wshell.SendKeys('{TAB}')
            $wshell.SendKeys('{TAB}')
            $wshell.SendKeys('{ENTER}')
            $wshell.SendKeys('{DOWN}')
            $wshell.SendKeys('{ENTER}')
            $wshell.SendKeys('+{TAB}')
            $wshell.SendKeys(' ')
            $wshell.SendKeys('{ENTER}')
        }
        else {
            $wshell = New-Object -ComObject wscript.shell
            $wshell.AppActivate('Rainmeter Skin Installer')
            Start-Sleep -s 2
            $wshell.SendKeys('{TAB}')
            $wshell.SendKeys('{TAB}')
            $wshell.SendKeys('{ENTER}')
            $wshell.SendKeys('{DOWN}')
            $wshell.SendKeys('{ENTER}')
            $wshell.SendKeys('{ENTER}')
        }
    }
}

function GenCoreData {
    $SkinsPath = $RmAPI.VariableStr('SKINSPATH')
    $SkinName = $RmAPI.VariableStr('Skin.Name')
    $SkinVer = $RmAPI.VariableStr('Version')
    If (Test-Path -Path "$SkinsPath..\CoreData") {
        $RmAPI.Log("Found coredata in programs")

        If (Test-Path -Path "$SkinsPath$SkinName\@Resources\@Structure") {
            $RmAPI.Log("Available CoreData structure for $SkinName")
            If (-not (Test-Path -Path "$SkinsPath..\CoreData\$SkinName\$SkinVer.txt")) {
                $RmAPI.Log("Generating: Can't find $SkinVer.txt file in CoreData of $SkinName")
                Robocopy "$SkinsPath$SkinName\@Resources\@Structure" "$SkinsPath..\CoreData\$SkinName" /E /XC /XN /XO
                New-Item -Path "$SkinsPath..\CoreData\$SkinName" -Name "$SkinVer.txt" -ItemType "file"
            }
            else {
                $RmAPI.Log("CoreData for $SkinName is already generated")
            }
        }
        else {
            $RmAPI.Log("$SkinName doesn't require creation of CoreData")
        }
    }
    else {
        $RmAPI.Log("Failed to find coredata in programs, generating")
        New-Item -Path "$SkinsPath..\" -Name "CoreData" -ItemType "directory"
        $RmAPI.Bang('[!Refresh]')
    }
}

function DuplicateSkin {
    param (
        [string]$DuplicateName = 'CloneSkinName'
    )
    $SkinsPath = $RmAPI.VariableStr('SKINSPATH')
    $Resources = $RmAPI.VariableStr('@')
    $SkinName = $RmAPI.VariableStr('Sec.arg1')

    If (Test-Path -Path "$SkinsPath$DuplicateName") {
        $RmAPI.Log("Folder already exits")
    }
    else {
        $RmAPI.Log("Duplicating to $DuplicateName")
        Copy-Item -Path "$SkinsPath$SkinName\" -Destination "$SkinsPath$DuplicateName\" -Recurse
        New-Item -Path "$SkinsPath$DuplicateName\@Resources\" -Name "IsClone.txt" -ItemType "file"
    }
    $RmAPI.Bang("[!WriteKeyValue Rainmeter OnRefreshAction `"`"`"[!WriteKeyValue Rainmeter OnRefreshAction `"#*Sec.DefaultStartActions*#`"][!DeactivateConfig]`"`"`"][!WriteKeyValue Variables Skin.Name $DuplicateName `"$($Resources)SecVar.inc`"][!WriteKeyValue Variables Skin.Set_Page Info `"$($Resources)SecVar.inc`"][`"$($Resources)Addons\RestartRainmeter.exe`"]")

}

function Uninstall {
    $SkinsPath = $RmAPI.VariableStr('SKINSPATH')
    $Resources = $RmAPI.VariableStr('@')
    $SkinName = $RmAPI.VariableStr('Sec.arg1')
    If (Test-Path -Path "$SkinsPath..\CoreData\$SkinName") {
        Remove-Item -LiteralPath "$SkinsPath..\CoreData\$SkinName" -Force -Recurse
    }
    Remove-Item -LiteralPath "$SkinsPath$SkinName" -Force -Recurse
    Start-Sleep -s 1
    $RmAPI.Bang("[!WriteKeyvalue Variables Sec.variant `"Variants\Uninstalled.inc`"][!WriteKeyValue Variables Skin.Name $SkinName `"$($Resources)SecVar.inc`"][!WriteKeyValue Variables Skin.Set_Page Info `"$($Resources)SecVar.inc`"][`"$($Resources)Addons\RestartRainmeter.exe`"]")
}