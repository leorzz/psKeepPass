#.ExternalHelp psKeePass.Help.xml
function Set-KPEntry
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
            [Parameter(Mandatory=$false,ValueFromPipeline=$True,DontShow)]
                [KeePassLib.PwEntry]$InputObject,
            [Parameter(Mandatory=$False)]
                [String]$EntryTitle,
            [Parameter(Mandatory=$False)]
                [String]$EntryUserName,
            [Parameter(Mandatory=$False, ParameterSetName="EntryPassword")]
                [Security.SecureString]$EntryPassword,
            [Parameter(Mandatory=$False, ParameterSetName="AutoPassword",HelpMessage='Use to define the password length.')]
                [Switch]$AutoResetPassword,
            [Parameter(Mandatory=$False, ParameterSetName="AutoPassword",HelpMessage='Use to define the password length.')]
                [int]$EntryPasswordLenght=20,
            [Parameter(Mandatory=$False, ParameterSetName="AutoPassword",HelpMessage='Use to generate password.')]
                [Switch]$EntryPasswordComplex,
            [Parameter(Mandatory=$False)]
                [String]$EntryUrl,
            [Parameter(Mandatory=$False,HelpMessage='Use to Add new Tags.')]
                [String[]]$AddTags,
            [Parameter(Mandatory=$False,HelpMessage='Use to Remove Tags.')]
                [String[]]$RemoveTags,
            [Parameter(Mandatory=$False)]
                [String]$EntryNotes,
            [Parameter(Mandatory=$False,HelpMessage='Use to move entry to group.')]
                [String]$GroupPath,
            [Parameter(Mandatory=$False)]
                [Switch]$PassThru

    )

    BEGIN
    {
        function Get-PwGroup ($RootGroup,[String]$GroupPath)
        {
            $Tree = $GroupPath -split '\\'
            if ($Tree)
            {
                #$pwGroup = $RootGroup.Groups
                $pwGroup = $RootGroup
                foreach ($groupName in $Tree)
                {
                            if (-not [String]::IsNullOrEmpty($groupName))
                            {
                                if ($groupName -in $pwGroup.Name)
                                {
                                    $pwGroup = $pwGroup | ? {$_.Name -eq $groupName}
                                    $out = $pwGroup
                                    $pwGroup = $pwGroup.Groups
                                    $isValidGroup = $True
                                }
                                else
                                {
                                    $isValidGroup = $False
                                    break
                                }
                            }
                        }
                if ($isValidGroup)
                {
                    #return [Array]$Tree | ? { -not [String]::IsNullOrEmpty($_) }
                    return $out
                }
                else
                {
                    return $null
                }
            }
            else
            {
                return $RootGroup
            }
        }
    }
    PROCESS
    {
        if ($InputObject)
        {
            $InputObject | % {
                try
                {
                    if ($_ -is [KeePassLib.PwEntry] )
                    {
                        $PwEntry = $_
                        $connectionInfo = $PwEntry.connectionInfo
                        $compositeKey = $PwEntry.compositeKey

                        #$kpDatabase = $PwEntry.kpDatabase
                        $kpDatabase = new-object KeePassLib.PwDatabase
                        $statusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger

                        $kpDatabase.open($connectionInfo,$compositeKey,$statusLogger)
                        $PwEntry = $kpDatabase.RootGroup.FindEntry($PwEntry.Uuid,$true)
                    }
                    else
                    {
                        Write-Host InputObjec is not KeePassLib.PwEntry. -ForegroundColor Red
                        break
                    }

                    # Protected strings are encrypted in memory:
                    if ( $EntryTitle -and ($PwEntry.Strings.ReadSafe('Title') -ne $EntryTitle) )
                    {
                        $pTitle = New-Object KeePassLib.Security.ProtectedString($True, $EntryTitle)
                        $PwEntry.Strings.Set("Title", $pTitle)
                    }
                    if ( $EntryUserName -and ($PwEntry.Strings.ReadSafe('UserName') -ne $EntryUserName) )
                    {
                        $pUser = New-Object KeePassLib.Security.ProtectedString($True, $EntryUserName)
                        $PwEntry.Strings.Set("UserName", $pUser)
                    }

                    if ($AutoResetPassword.IsPresent)
                    {
                        $pPW = New-Object KeePassLib.Security.ProtectedString($True, (Get-KPRandomPassword -Length $EntryPasswordLenght -Complex:$EntryPasswordComplex.IsPresent ))
                        $PwEntry.Strings.Set("Password", $pPW)
                    }

                    if ( $EntryPassword -and ($PwEntry.Strings.ReadSafe('Password') -ne (ConvertTo-PlainText -SecureString $EntryPassword)) )
                    {
                        $pPW = New-Object KeePassLib.Security.ProtectedString($True, (ConvertTo-PlainText -SecureString $EntryPassword))
                        $PwEntry.Strings.Set("Password", $pPW)
                    }

                    if ( $EntryUrl -and ($PwEntry.Strings.ReadSafe('URL') -ne $EntryUrl) )
                    {
                        $pURL = New-Object KeePassLib.Security.ProtectedString($True, $EntryUrl)
                        $PwEntry.Strings.Set("URL", $pURL)
                    }
                    if ( $EntryNotes -and ($PwEntry.Strings.ReadSafe('Notes') -ne $EntryNotes) )
                    {
                        $pNotes = New-Object KeePassLib.Security.ProtectedString($True, $EntryNotes)
                        $PwEntry.Strings.Set("Notes", $pNotes)
                    }


                    if ($AddTags)
                    {
                        $AddTags | % { 
                            if ($PwEntry.Tags -notcontains $_)
                            {
                                $null = $PwEntry.AddTag($_) 
                            }
                        }
                    }

                    if ($RemoveTags)
                    {
                        $RemoveTags | % { 
                            if ($PwEntry.Tags -contains $_)
                            {
                                $null = $PwEntry.RemoveTag($_) 
                            }
                        }

                    }

                    #if ( $GroupPath -and ($PwEntry.Strings.ReadSafe('Notes') -ne $GroupPath) )
                    if ( $GroupPath -and ($GroupPath -ne $PwEntry.GroupPath) )
                    {
                        try
                        {
                            $rootGroup = $kpDatabase.RootGroup
                            $oldPwGroup = $PwEntry.ParentGroup
                            $PwGroup = Get-PwGroup $rootGroup $GroupPath 
                            if ($PwGroup)
                            {
                                $null = $kpDatabase.MergeIn($kpDatabase,[KeePassLib.PwMergeMethod]::Synchronize,$statusLogger)
                                $null = $PwGroup[0].AddEntry($PwEntry, $True, $True)
                                $null = $oldPwGroup.Entries.Remove($PwEntry)
                            }
                            else
                            {
                                Write-Host "Group Path $($GroupPath) is invalid." -ForegroundColor Cyan
                            }
                        }
                        catch [Exception]
                        {
                            Write-KPLog -message $_ -Level EXCEPTION
                            Write-Host $($_.Exception.Message) -ForegroundColor Red
                        }
                    }

                    if ($kpDatabase.IsOpen)
                    {
                        $null = $kpDatabase.MergeIn($kpDatabase,[KeePassLib.PwMergeMethod]::Synchronize,$statusLogger)
                        $null = $PwEntry.Touch($true,$true)
                        $kpDatabase.Save($statusLogger)
                        $kpDatabase.Close()
                    }

                    if ($PassThru.IsPresent)
                    {
                        Get-KPEntry -ConnectionInfo $connectionInfo -CompositeKey $compositeKey -Uuid $PwEntry.Uuid
                    }

                }
                catch [Exception]
                {
                    Write-KPLog -message $_ -Level EXCEPTION
                    Write-Host $($_.Exception.Message) -ForegroundColor Red
                    continue
                }

            }#InputObject
        }
    }
    END
    {
        
    }
}


