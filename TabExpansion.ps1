try
{
    Import-Module -Name TabExpansionPlusPlus -ea Ignore
    if (Get-Command Register-ArgumentCompleter -Module TabExpansionPlusPlus -ea Ignore)
    {
        # http://www.powertheshell.com/dynamicargumentcompletion/
        # https://github.com/lzybkr/TabExpansionPlusPlus
        $cmdlets = @('Get-KPEntry','New-KPEntry')
        $cmdlets | % {
            #Register-ArgumentCompleter -CommandName $_ -ParameterName "KeyPassFile" -ScriptBlock {
            #    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            #    Import-Module (Join-Path $PSScriptRoot common\common.psm1) -Prefix KP 
            #    $path = Get-KPParamHistory -Function Get-KPEntry -Parameter KeyPassFile
            #    if ($path)
            #    {
            #        $path | % { New-CompletionResult -CompletionText "'$($_.Content)'" -ListItemText $($_.Content) }
            #    }
            #}

            Register-ArgumentCompleter -CommandName $_ -ParameterName "MasterPassword" -ScriptBlock {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
                Import-Module (Join-Path $PSScriptRoot common\common.psm1) -Prefix KP 
                $path = Get-KPSecurePassword
                if ($path)
                {
                    $path | % { New-CompletionResult -CompletionText ("(Get-KPSecurePassword -Alias $($_.Alias)).MasterPassword") -ListItemText $_.Alias -NoQuotes }
                }
            }
        }
    }
    elseif (Get-Command Register-ArgumentCompleter -Module Microsoft.PowerShell.Core -ea Ignore)
    {
        #https://technet.microsoft.com/en-us/library/mt631420.aspx
        $cmdlets = @('Get-KPEntry','New-KPEntry')
        $cmdlets | % {
            #Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName $_ -ParameterName "KeyPassFile" -ScriptBlock { Get-KPParamHistory -Function $_ -Parameter KeyPassFile | % {"'$($_.Content)'"} }
            Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName $_ -ParameterName "MasterPassword" -ScriptBlock { Get-KPSecurePassword | % {"(Get-KPSecurePassword -Alias $($_.Alias)).MasterPassword"} }
        }
    }
}
catch
{
    Write-KPLog -message $_ -Level EXCEPTION
}