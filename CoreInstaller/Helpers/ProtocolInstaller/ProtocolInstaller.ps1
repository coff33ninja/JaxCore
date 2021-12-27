function Add-CoreProtocol{
    $root = $RmAPI.VariableStr('ROOTCONFIGPATH') + 'CoreInstaller'
    Start-Process powershell -ArgumentList "`$ePol = Get-ExecutionPolicy -Scope CurrentUser; Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; & '$root\Helpers\CoreInstaller\CoreInstallerWebSupport.ps1' '$root\Helpers\CoreInstaller\CoreInstaller.exe' '$($RmAPI.VariableStr('@'))WebSupportEnabled.inc'; Set-ExecutionPolicy `$ePol -Scope CurrentUser -Force;" -Verb RunAs
}
function Remove-Protocol {
    Start-Process powershell -ArgumentList "`$ePol = Get-ExecutionPolicy -Scope CurrentUser; Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; & '$root\Helpers\CoreInstaller\CoreInstallerWebSupport.ps1' '' '$($RmAPI.VariableStr('@'))WebSupportEnabled.inc' 'T'; Set-ExecutionPolicy `$ePol -Scope CurrentUser -Force;" -Verb RunAs    
}