#.ExternalHelp psKeePass.Help.xml
function New-KPEntry
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
            [Parameter(Mandatory=$true, Position = 1, HelpMessage="Use path to KeePass database.")]
                [string]$KeyPassFile,
            [Parameter(Mandatory=$false,HelpMessage='Use MasterPassword to KeePass database.')]
                [Security.SecureString]$MasterPassword=(Get-KPSecurePassword -Alias Default).MasterPassword,
            [Parameter(Mandatory=$false,HelpMessage='Use to set Title the new entry.')]
                [String]$EntryTitle,
            [Parameter(Mandatory=$False,HelpMessage='Use to set Username the new entry.')]
                [String]$EntryUserName,
            [Parameter(Mandatory=$False, ParameterSetName="EntryPassword",HelpMessage='Use to set Password the new entry.')]
                [String]$EntryPassword,
            [Parameter(Mandatory=$False, ParameterSetName="AutoPassword",HelpMessage='Use to define the password length.')]
                [int]$EntryPasswordLenght=20,
            [Parameter(Mandatory=$False, ParameterSetName="AutoPassword",HelpMessage='Use to generate password.')]
                [Switch]$EntryPasswordComplex,
            [Parameter(Mandatory=$False,HelpMessage='Use to Url the new entry.')]
                [String]$EntryUrl,
            [Parameter(Mandatory=$False,HelpMessage='Use to set Tags the new entry.')]
                [String[]]$Tags,
            [Parameter(Mandatory=$False,HelpMessage='Use to set Notes the new entry.')]
                [String]$EntryNotes,
            [Parameter(Mandatory=$False,HelpMessage='Use to set logical path to the new entry.')]
                [String]$GroupPath,
            [Parameter(Mandatory=$False,HelpMessage='Use to output the new entry.')]
                [Switch]$PassThru

    )



    BEGIN
    {
        $currentMethod = (Get-PSCallStack)[0].Command
        if (-not $MasterPassword)
        {
            do
            {
                $MasterPassword = Read-Host -Prompt "Type the Master Password to KeepPass Database `n$($KeyPassFile)" -AsSecureString
            }While(-not $MasterPassword)
        }


        if (Test-Path $KeyPassFile)
        {
            if (-not $ConnectionInfo)
            {
                $connectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
                $connectionInfo.Path = $KeyPassFile
                New-KPParamHistory -Function $currentMethod -Parameter KeyPassFile -Content $KeyPassFile
            }
        }
        else
        {
            Write-Host File $KeyPassFile not found. -ForegroundColor Red
            break;
        }

        $kpDatabase = new-object KeePassLib.PwDatabase

        $compositeKey = new-object KeePassLib.Keys.CompositeKey
        #$m_pKey.AddUserKey((New-Object KeePassLib.Keys.KcpUserAccount))
        $compositeKey.AddUserKey((New-Object KeePassLib.Keys.KcpPassword($MasterPassword | ConvertTo-KPPlainText)));
        $StatusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger

        try
        {
            $kpDatabase.Open($connectionInfo,$compositeKey,$StatusLogger)
        }
        catch [KeePassLib.Keys.InvalidCompositeKeyException]
        {
            Write-Host Incorrect password. $($_.Exception.Message) -ForegroundColor Red
            break;
        }
        catch [Exception]
        {
            Write-Host $_.Exception.Message
            Write-KPLog -message $_ -Level EXCEPTION
            break;
        }

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
        try
        {
            $rootGroup = $kpDatabase.RootGroup
            $PwGroup = Get-PwGroup $rootGroup $GroupPath


            # The $True arguments allow new UUID and timestamps to be created automatically:
            $PwEntry = New-Object -TypeName KeePassLib.PwEntry( $PwGroup[0], $True, $True )
 

            if (-not $EntryPassword)
            {
                $EntryPassword = Get-KPRandomPassword -Length $EntryPasswordLenght -Complex:$EntryPasswordComplex.IsPresent
            }

            $EntryNotes += "`n#New entry by psKeePass"
    
            # Protected strings are encrypted in memory:
            $pTitle = New-Object KeePassLib.Security.ProtectedString($True, $EntryTitle)
            $pUser = New-Object KeePassLib.Security.ProtectedString($True, $EntryUserName)
            $pPW = New-Object KeePassLib.Security.ProtectedString($True, $EntryPassword)
            $pURL = New-Object KeePassLib.Security.ProtectedString($True, $EntryUrl)
            $pNotes = New-Object KeePassLib.Security.ProtectedString($True, $EntryNotes)
 
            $PwEntry.Strings.Set("Title", $pTitle)
            $PwEntry.Strings.Set("UserName", $pUser)
            $PwEntry.Strings.Set("Password", $pPW)
            $PwEntry.Strings.Set("URL", $pURL)
            $PwEntry.Strings.Set("Notes", $pNotes)
        
            $Tags | % { $null = $PwEntry.AddTag($_) }

            $PwGroup[0].AddEntry($PwEntry, $True)
 
            # Notice that the database is automatically saved here!
            #$StatusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger
            $kpDatabase.Save($StatusLogger)


            if ($PassThru.IsPresent)
            {
                Get-KPEntry -ConnectionInfo $connectionInfo -CompositeKey $compositeKey -Uuid $PwEntry.Uuid
            }
        }
        catch [Exception]
        {
            Write-Host $_.Exception.Message
            Write-KPLog -message $_ -Level EXCEPTION
        }

 
    }
    END
    {
        if ($kpDatabase.IsOpen)
        {
            $kpDatabase.Close()
        }
    }
}


 

