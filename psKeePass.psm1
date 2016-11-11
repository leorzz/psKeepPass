$Script:mInfo = $MyInvocation.MyCommand.ScriptBlock.Module
$Script:mInfo.Description = "Author: Leonardo Rizzi"

# Store generic config retrieve from parameters.json
#$Script:config = (Get-Content -LiteralPath $(Join-Path $PSScriptRoot enviroment\parameters.json) -ErrorAction Stop) -join "`n" | ConvertFrom-Json

Import-Module (Join-Path $PSScriptRoot common\common.psm1) -Prefix KP 

#Load all .NET binaries in the folder
$pathToKeePassFolder = Join-Path $PSScriptRoot bin

###########################################################################
#
# Load the classes from KeePass.exe:
#
###########################################################################
$KeePassEXE = (Join-Path $pathToKeePassFolder KeePass.exe)
if (Test-Path $KeePassEXE)
{
    try
    {
        [Reflection.Assembly]::LoadFile($KeePassEXE)
    }
    catch [Exception]
    {
        Write-Host $_ -ForegroundColor Red
        break
    }
}
else
{
    Write-Host "Assembly $($KeePassEXE) is not found."
    break
}



Enum EntryKeys
{
    UserName
    Title
    URL
    Notes
    Password
}



#region Include
    . (Join-Path $PSScriptRoot TabExpansion.ps1)
    . (Join-Path $PSScriptRoot Get-KPEntry.ps1)
    . (Join-Path $PSScriptRoot New-KPEntry.ps1)
    . (Join-Path $PSScriptRoot Set-KPEntry.ps1)
    . (Join-Path $PSScriptRoot Remove-KPEntry.ps1)
#endregion Include



# Common Module
Export-ModuleMember -Function New-KPSecurePassword
Export-ModuleMember -Function Get-KPSecurePassword
Export-ModuleMember -Function Remove-KPSecurePassword
# KeePass Module
Export-ModuleMember -Function Get-KPEntry
Export-ModuleMember -Function New-KPEntry
Export-ModuleMember -Function Set-KPEntry
Export-ModuleMember -Function Remove-KPEntry
