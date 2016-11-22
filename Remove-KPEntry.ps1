#.ExternalHelp psKeePass.Help.xml
function Remove-KPEntry
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
                [Switch]$Permanent,
            [Parameter(Mandatory=$False)]
                [Switch]$PassThru
    )

    BEGIN
    {
        # http://stackoverflow.com/questions/20690347/c-sharp-delete-group-from-keepass-database
        $kpDatabase = new-object KeePassLib.PwDatabase
        $statusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger
    }
    PROCESS
    {
        #Write-Output $InputObject
        if ($InputObject)
        {
            $InputObject | % {
                try
                {
                    if ($_ -is [KeePassLib.PwEntry] )
                    {
                        try
                        {
                            $PwEntry = $_
                            $connectionInfo = $PwEntry.connectionInfo
                            $compositeKey = $PwEntry.compositeKey
                            $kpDatabase.open($connectionInfo,$compositeKey,$statusLogger)

                            $pwDeletedObject = New-Object KeePassLib.PwDeletedObject
                            $pwDeletedObject.Uuid = $PwEntry.Uuid
                            $pwDeletedObject.DeletionTime = Get-Date
                            $kpDatabase.DeletedObjects.Add($pwDeletedObject)
                            $kpDatabase.MergeIn($kpDatabase,[KeePassLib.PwMergeMethod]::Synchronize,$statusLogger)

                            if ($kpDatabase.RecycleBinEnabled -and (-not $Permanent.IsPresent))
                            {
                                $pwGroupRecycleBin = $kpDatabase.RootGroup.FindGroup($kpDatabase.RecycleBinUuid,$true)
                                $pwGroupRecycleBin.AddEntry($PwEntry, $true, $true)
                            }

                            $PwEntry.Touch($true,$true)
                            $kpDatabase.Save($statusLogger)
                            $kpDatabase.Close()
                        }
                        catch [Exception]
                        {
                            Write-KPLog -message $_ -Level EXCEPTION
                            Write-Host $($_.Exception.Message) -ForegroundColor Red
                        }

                    }
                    else
                    {
                        Write-Host InputObjec is not KeePassLib.PwEntry. -ForegroundColor Red
                        break
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


