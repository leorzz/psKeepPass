$Script:mInfo = $MyInvocation.MyCommand.ScriptBlock.Module
$Script:parent_appdata = (Join-Path -Path $env:LOCALAPPDATA -ChildPath "$(Split-Path -Path (Split-Path -Path $($PSScriptRoot) -Parent) -Leaf)")
$Script:mInfo.Description = "Author: Leonardo Rizzi"

Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 | ? {$_.Name -notmatch "^_"} | % { . $_.FullName }

Export-ModuleMember -Function 'Get-*'
Export-ModuleMember -Function 'New-*'
Export-ModuleMember -Function 'Set-*'
Export-ModuleMember -Function 'Test-*'
Export-ModuleMember -Function 'Remove-*'
Export-ModuleMember -Function 'Show-*'
Export-ModuleMember -Function 'Write-*'
Export-ModuleMember -Function 'ConvertTo-*'
