#region PSTip Storing of credentials
# http://www.powershellmagazine.com/2012/10/30/pstip-storing-of-credentials/

    #.ExternalHelp ..\psKeePass.Help.xml
    function New-SecurePassword
    {
        [CmdletBinding()]
 
        param(
            [Parameter(Mandatory = $true, Position = 1)]
                [string]$Alias,
            [Parameter(Mandatory = $false)]
                #[String]$Path = (Join-Path -Path $env:LOCALAPPDATA -ChildPath "$($Script:mInfo.Name)\security"),
                [String]$Path = (Join-Path -Path $Script:parent_appdata -ChildPath security),
                [Switch]$Force
        )


 
        if ((Get-SecurePassword -Alias $Alias) -and (-not $Force.IsPresent))
        {
            Write-Host "Aborted. This SecurePassword Alias '$($Alias)' already exists. Use '-Force' switch to overwrite." -ForegroundColor Cyan
            return
        }
 
        # get credentials for given username
        $cred = Read-Host -AsSecureString -Prompt "Type Master Password to KeePass Database.`nStore at $(Join-Path -Path $Path -ChildPath $Alias)"

        # and save encrypted text to a file
        if ($cred)
        {
            if (-not (Test-Path $Path))
            {
                $null = New-Item -Path $Path -ItemType directory -Force
            }
            $credentials = "" | select MasterPassword
            $credentials.MasterPassword = $cred | ConvertFrom-SecureString
            $credentials | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $Path -ChildPath $Alias)
            Remove-Variable -Name cred
            Remove-Variable -Name credentials
            return Get-SecurePassword -Alias $Alias
        }
    }
 
    #.ExternalHelp ..\psKeePass.Help.xml
    function Get-SecurePassword
    {
        [CmdletBinding()]
        param(
            #[Parameter(Mandatory = $false)]
            #[string]$UserName,
            [Parameter(Mandatory = $false,Position = 1)]
            [string]$Alias = $null,
            [Parameter(Mandatory = $false)]
            #[String]$Path = (Join-Path -Path $Script:mInfo.ModuleBase -ChildPath security)
            [String]$Path = (Join-Path -Path $Script:parent_appdata -ChildPath security)
        )
        try
        {
            #$credentials_files = Get-ChildItem -Path $Path -Filter $Alias -ErrorAction SilentlyContinue
            if ($Alias)
            {
                $credentials_files = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | ? { $_.Name -like $Alias }
            }
            else
            {
                $credentials_files = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
            }
        }
        catch [Exception]
        {
            Write-Log -message $_ -Level EXCEPTION
            Write-Host $_.Exception.Message -ForegroundColor Red
            return $null
        }

        $credentials_files | % {
            try
            {
                $credentials = (Get-Content -Path $_.FullName) -join "`n" | ConvertFrom-Json
                $credentials.MasterPassword = $credentials.MasterPassword | ConvertTo-SecureString
                Add-Member -InputObject $credentials -Name Alias -MemberType NoteProperty -Value $_.Name
                Add-Member -InputObject $credentials -Name CreationTime -MemberType NoteProperty -Value $_.CreationTime
                Write-Output $credentials
                Remove-Variable -Name credentials
            }
            catch
            {
                Write-Log -message $_ -Level EXCEPTION
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
    }
 
    #.ExternalHelp ..\psKeePass.Help.xml
    function Remove-SecurePassword
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$True, Position = 1)]
            [string]$Alias = $null,
            [Parameter(Mandatory = $false)]
            #[String]$Path = (Join-Path -Path $Script:mInfo.ModuleBase -ChildPath security)
            [String]$Path = (Join-Path -Path $Script:parent_appdata -ChildPath security)
        )
        Get-ChildItem -Path $Path -Filter $Alias | Remove-Item
    }

    #.ExternalHelp ..\psKeePass.Help.xml
    function Show-SecurePassword
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
                [System.Management.Automation.PSObject]$InputObject
            )
        BEGIN{}
        PROCESS
        {
            # Just to see password in clear text
            $InputObject | % {
                $_.MasterPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_.MasterPassword))
                Write-Output $_
            }
        }
        END{}
    }


    # Taking a secure password and converting to plain text
    function ConvertTo-PlainText 
    {
        Param(
            [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
                [security.securestring]$SecureString
        )
        $marshal = [Runtime.InteropServices.Marshal]
        $marshal::PtrToStringAuto( $marshal::SecureStringToBSTR($SecureString) )
    }
#endregion PSTip Storing of credentials