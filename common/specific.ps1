#.ExternalHelp ..\psKeePass.Help.xml
function Format-PwEntry
{
    Param
    (
        [Parameter(Mandatory=$false,ValueFromPipeline=$True)]
            $PwEntry,
            [Switch]$ForcePlainText,
            $CompositeKey,
            $ConnectionInfo
    )
            $PwEntry.Strings | % {
                                    try
                                    {
                                        $val = $null
                                        $val = $PwEntry.Strings.ReadSafe($_.Key)
                                        if (-not [String]::IsNullOrEmpty($val))
                                        {
                                            if ( ($_.Key -eq "Password") )
                                            {
                                                try
                                                {
                                                    $secPassword = $val | ConvertTo-SecureString -AsPlainText -Force -ErrorAction stop
                                                    if (-not $ForcePlainText.IsPresent)
                                                    {
                                                        $val = $secPassword
                                                    }
                                                }
                                                catch [Exception]
                                                {
                                                    #$val = $_.Exception.Message
                                                    $val = $null
                                                }
                                            }
                                        }
                                        else
                                        {
                                            $val = $null
                                        }
                                    }
                                    catch [Exception]
                                    {
                                        $val = $null
                                    }


                                    try
                                    {
                                        Add-Member -InputObject $PwEntry -MemberType NoteProperty -Name $_.Key -Value $val
                                    }
                                    catch [exception]
                                    {
                                        Write-Log -message $_ -Level EXCEPTION
                                    }
                                            
                                }# $kpItem.Strings

            try
            {
                if ($PwEntry.UserName -and $secPassword)
                {
                    $psCred = New-Object System.Management.Automation.PSCredential ($PwEntry.UserName, $secPassword)
                    Add-Member -InputObject $PwEntry -MemberType NoteProperty -Name PsCredential -Value $psCred
                    Add-Member -InputObject $PwEntry -MemberType NoteProperty -Name User -Value $PwEntry.UserName
                }
                #Add-Member -InputObject $kpItem -MemberType NoteProperty -Name GroupPath -Value (Get-ParentGroup $kpItem)
                Add-Member -InputObject $PwEntry -MemberType NoteProperty -Name compositeKey -Value $compositeKey
                Add-Member -InputObject $PwEntry -MemberType NoteProperty -Name connectionInfo -Value $connectionInfo

                $getHistory = {
                    Param([bool]$ForcePlainText=$false)
                    if ($this.History)
                    {
                        if ($ForcePlainText)
                        {
                            $item = $this.History  | % {Format-PwEntry -PwEntry $_ -CompositeKey $this.CompositeKey -ConnectionInfo $this.ConnectionInfo -ForcePlainText:$true}
                        }
                        else
                        {
                            $item = $this.History  | % {Format-PwEntry -PwEntry $_ -CompositeKey $this.CompositeKey -ConnectionInfo $this.ConnectionInfo}
                        }
                    }
                    Set-StandardMembers -MyObject $item -DefaultProperties LastAccessTime,UserName,Password,Title
                    return $item
                }
                Add-Member -InputObject $PwEntry -MemberType ScriptMethod -Name getHistory -Value $getHistory

                        
            }
            catch [Exception]
            {
                Write-Log -message $_ -Level EXCEPTION
            }
            
    return $PwEntry
}
