#.ExternalHelp psKeePass.Help.xml
function Get-KPEntry
{
    # http://technet.microsoft.com/en-us/library/hh847872.aspx
     [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false
                  #HelpUri = 'http://www.microsoft.com/',
                  #ConfirmImpact='Medium'
                  )]
     #[OutputType([String])]

    param(
            [Parameter(Mandatory=$False, Position = 1, HelpMessage="Use managedServer name.")]
                [string]$KeyPassFile,
            [Parameter(Mandatory=$False, HelpMessage="Use filter EntryKeys.", ParameterSetName='EntryKeys')]
                [EntryKeys[]]$Key,
            [Parameter(Mandatory=$False, HelpMessage="Use filter Value.", ParameterSetName='EntryKeys')]
                [string]$Value,
            [Parameter(Mandatory=$False, HelpMessage="Use to filter by GroupPath.")]
                [string]$GroupPath,
            [Parameter(Mandatory=$False, HelpMessage="Use KeePassLib.PwUuid object.", ParameterSetName='Uuid')]
                [KeePassLib.PwUuid]$Uuid,
            [Parameter(Mandatory=$False)]
                [Security.SecureString]$MasterPassword=(Get-KPSecurePassword -Alias Default).MasterPassword,
            [Parameter(Mandatory=$False, HelpMessage="Use managedServer name.")]
                [Switch]$ForcePlainText,
            [Parameter(Mandatory=$False, HelpMessage="Use managedServer name.")]
                [Switch]$IncludeRecycleBin,
            [Parameter(Mandatory=$False,DontShow)]
                [KeePassLib.Keys.CompositeKey]$CompositeKey,
            [Parameter(Mandatory=$False,DontShow)]
                [KeePassLib.Serialization.IOConnectionInfo]$ConnectionInfo
    )

    BEGIN
    {
        # http://keepass.info/help/v2_dev/scr_sc_index.html#getentrystring
        # http://it-by-doing.blogspot.com.br/2014/10/accessing-keepass-with-powershell.html

        function Get-ParentGroups ($item)
        {
            if ($item)
            {
                try
                {
                    $item = $item.ParentGroup
                    $pGroups = New-Object -TypeName System.Collections.ArrayList
                    While($item)
                    {
                        $pGroups.Add($item)
                        $item = $item.ParentGroup
                    }
                    return $pGroups
                }
                catch [Exception]
                {
                    return $null
                }
            }
        }


        $currentMethod = (Get-PSCallStack)[0].Command
        if (-not $MasterPassword)
        {
            do
            {
                $MasterPassword = Read-Host -Prompt "Type the Master Password to KeepPass Database `n$($KeyPassFile)" -AsSecureString
            }While(-not $MasterPassword)
        }

        $kpDatabase = new-object KeePassLib.PwDatabase
        $statusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger

        if (-not $CompositeKey)
        {
            $compositeKey = new-object KeePassLib.Keys.CompositeKey
            #$m_pKey.AddUserKey((New-Object KeePassLib.Keys.KcpUserAccount))
            $compositeKey.AddUserKey((New-Object KeePassLib.Keys.KcpPassword($MasterPassword | ConvertTo-KPPlainText)));
        }
        
        if (-not $ConnectionInfo)
        {
            if (Test-Path $KeyPassFile)
            {
                $connectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
                $connectionInfo.Path = $KeyPassFile
                New-KPParamHistory -Function $currentMethod -Parameter KeyPassFile -Content $KeyPassFile
            }
            else
            {
                Write-Host File $KeyPassFile not found. -ForegroundColor Red
                break;
            }
        }

        try
        {
            $kpDatabase.Open($connectionInfo,$compositeKey,$statusLogger)
            if ($Uuid)
            {
                $kpItems = $kpDatabase.RootGroup.FindEntry($Uuid,$true)
            }
            else
            {
                $kpItems = $kpDatabase.RootGroup.GetObjects($true, $true)


                if (-not $IncludeRecycleBin.IsPresent)
                {
                    $kpItems = $kpItems | ? {
                        $pGroups = Get-ParentGroups $_
                        $pGroups.Uuid -notcontains $kpDatabase.RecycleBinUuid
                        #$_.ParentGroup.Uuid -ne $kpDatabase.RecycleBinUuid
                    }
                }

            }
        }
        catch [KeePassLib.Keys.InvalidCompositeKeyException]
        {
            Write-Host Incorrect password. $($_.Exception.Message) -ForegroundColor Red
            break;
        }
        catch [Exception]
        {
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-KPLog -message $_ -Level EXCEPTION
            break;
        }

        try
        {
            $kpDatabase.Close()
        }
        catch [Exception]
        {
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-KPLog -message $_ -Level EXCEPTION
        }


        if ([String]::IsNullOrEmpty($key))
        {
            $Key = [System.Enum]::GetValues('EntryKeys')
        }
        if (-not $Value)
        {
            $Value = '*'
        }

    }#BEGIN
    
    PROCESS
    {
        # GroupPath option
        if ($kpItems)
        {
            $kpItems | % {
                $pNames = (Get-ParentGroups $_).name
                [Array]::Reverse($pNames)
                $gPath = $pNames -join '\'
                try
                {
                    Add-Member -InputObject $_ -MemberType NoteProperty -Name GroupPath -Value "\$($gPath)"
                }
                catch [Exception]
                {
                    Write-KPLog -message $_ -Level EXCEPTION
                }
            }

            if ($GroupPath)
            {
                $kpItems = $kpItems | ? {$_.GroupPath -like $GroupPath}
            }
        }


        foreach($kpItem in $kpItems)
        {

            foreach ($k in $key)
            {
                $val = $kpItem.Strings.ReadSafe($K)

                if ( $val -and ($val -like $Value) )
                {
                    $item = Format-KpPwEntry -PwEntry $kpItem -CompositeKey $CompositeKey -ConnectionInfo $ConnectionInfo -ForcePlainText:$ForcePlainText.IsPresent
                    if ($item)
                    {
                        Set-KPStandardMembers -MyObject $item -DefaultProperties UserName,Password,Title,GroupPath
                        Write-Output $item
                    }
                    break

               }#if
                $secPassword = $null
            }
        } 
    }#PROCESS
    END
    {}#END

}