function Add-CoreProtocol{
    $root = $($RmAPI.VariableStr('@')) + "CoreInstaller"
    Start-Process powershell -ArgumentList "& `"$root\Helpers\CoreInstaller\CoreInstallerWebSupport.ps1`" `"$root\Helpers\CoreInstaller\CoreInstaller.exe`"" -Verb RunAs
}