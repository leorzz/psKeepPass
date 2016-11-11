#Convert a text from the DOS format to the UNIX format.
#The format is different in the last character of each line. 
#The DOS format ends with a carriage return (Cr) line feed (Lf) 
#character whereas the UNIX format uses the line feed (Lf) character.
function ConvertTo-Unix
{
    begin
    {}
    process
    {
        ($_ | Out-String) -replace "`r`n","`n"
    }
    end
    {}
}

#Convert a text from the UNIX format to the DOS format.
#The format is different in the last character of each line. 
#The DOS format ends with a carriage return (Cr) line feed (Lf) 
#character whereas the UNIX format uses the line feed (Lf) character.
function ConvertFrom-Unix
{
    begin
    {}
    process
    {
        ($_ | Out-String) -replace "`n","`r`n"
    }
    end
    {}
}


function Set-StandardMembers
{
    # http://stackoverflow.com/questions/1369542/can-you-set-an-objects-defaultdisplaypropertyset-in-a-powershell-v2-script/1891215#1891215
    Param([PSObject]$MyObject,[String[]]$DefaultProperties)
        try
        {
            $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultProperties)
            $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
            $MyObject | Add-Member MemberSet PSStandardMembers $PSStandardMembers -Force
        }
        catch [Exception]
        {
            Write-Log -message $_ -Level EXCEPTION
            Write-Debug $_.Exception.Message
        }
}


# Teste Write permissions
function Test-Write {
    [CmdletBinding()]
    param (
        [parameter()] [ValidateScript({[IO.Directory]::Exists($_.FullName)})]
        [IO.DirectoryInfo] $Path
    )
    try {
        $testPath = Join-Path $Path ([IO.Path]::GetRandomFileName())
        [IO.File]::Create($testPath, 1, 'DeleteOnClose') > $null
        # Or...
        <# New-Item -Path $testPath -ItemType File -ErrorAction Stop > $null #>
        return $true
    } catch {
        return $false
    } finally {
        Remove-Item $testPath -ErrorAction SilentlyContinue -WhatIf:$false
    }
}
#.ExternalHelp ..\psKeePass.Help.xml
function New-ParamHistory
{
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)] 
            [String]$Function,
        [parameter(Mandatory=$true)] 
            [String]$Parameter,
        [parameter(Mandatory=$true)] 
            [String]$Content
    )
    try 
    {
        [Array]$paramHistory = Get-ParamHistory | select -First 5
        if (-not ($paramHistory | ? {($_.Parameter -eq $Parameter) -and ($_.Content -eq $Content)}) )
        {
            $item = "" | Select Function,Parameter,Content,DateTime
            $item.Function = $Function
            $item.Parameter = $Parameter
            $item.Content = $Content
            $item.DateTime = (Get-Date).DateTime
            $paramHistory += $item
            $null = New-Item -Path  (Join-Path -Path $Script:parent_appdata -ChildPath enviroment) -Name history.json -ItemType File -Value ($paramHistory | ConvertTo-Json) -Force
        }
    }
    catch [Exception]
    {
        Write-Log -message $_ -Level EXCEPTION
    }
}
#.ExternalHelp ..\psKeePass.Help.xml
function Get-ParamHistory
{
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$False)] 
            [String]$Function,
        [parameter(Mandatory=$False)] 
            [String]$Parameter
    )
    try 
    {
        $path = (Join-Path -Path $Script:parent_appdata -ChildPath enviroment/history.json)
        if (Test-Path -LiteralPath $path)
        {
            $output = Get-Content $path | ConvertFrom-Json
            $output = $output | sort -Property DateTime -Descending

            if ($Function)
            {
                $output = $output | ? {$_.Function -like $Function}
            }
            if ($Parameter)
            {
                $output = $output | ? {$_.Parameter -like $Parameter}
            }
            return $output
        }
        else
        {
            return $null
        }
    }
    catch [Exception]
    {
        Write-Log -message $_ -Level EXCEPTION
    }
}


Function Get-RandomPassword 
{
    Param($Length = 15, [Switch]$Complex)
    $chars = $letters = 65..90 + 97..122
    if ($Complex.IsPresent)
    {
        $chars += $punc = 33..33 + 35..38 + 40..43 + 45..46
        $chars += $digits = 48..57
    }
    # Thanks to
    # https://blogs.technet.com/b/heyscriptingguy/archive/2012/01/07/use-pow
    $password = get-random -count $length -input ($chars) | % `
            -begin { $aa = $null } `
            -process {$aa += [char]$_} `
            -end {$aa}

    return $password
}

