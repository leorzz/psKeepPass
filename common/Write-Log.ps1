#region Log File Management 
$logLocalAppDir = Join-Path $Script:mInfo.ModuleBase logs
$logName = "$($Script:mInfo.Name).log" 
$logFullName = Join-Path $logLocalAppDir $logName
$MaxLogFileSizeMB = 5 # After a log file reaches this size it will archive the existing and create a new one 

trap
[Exception] 
{ 
    Write-Log
    "error: $($_.Exception.GetType().Name) - $($_.Exception.Message)" 
} 

function LogFileCheck 
{
    if (Test-Path $logFullName) # 
    {
        if (((gci $logFullName).length/1MB) -gt $MaxLogFileSizeMB) # Check size of log file - to stop unweildy size, archive existing file if over limit and create fresh. 
        {
            $NewLogFile = $LogName.replace(".log", " ARCHIVED $(Get-Date -Format dd-MM-yyy-hh-mm-ss).log") 
            $log = Rename-Item $logFullName (Join-Path $LogLocalAppDir $NewLogFile) -PassThru
            Write-Host "Log $($log.fullname)" -ForegroundColor Cyan
        }
    }
    else
    {
        if (!(Test-Path $LogLocalAppDir))
        {
            mkdir $LogLocalAppDir | Out-Null
        }
        New-Item $logFullName -type file 
    }
}



function Write-Log # Send to log file 
{
    param(
            [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
                [System.String]$message,
            [ValidateSet('INFO','WARNING','ERROR','EXCEPTION','SECURITY')]            
                [System.String]$Level="INFO"
        )
    if (-not $WhatIfPreference.IsPresent -and $message)
    {
        foreach($obj in $input)
        {
            $pipeline += $obj
        }

        if (![String]::IsNullOrEmpty($pipeline))
        {
            $message = $pipeline
        }
        try
        {
            $toOutput = "$(get-date) $($env:USERDOMAIN)\$($env:USERNAME) $($Level):$($message)" | Out-File $logFullName -append -NoClobber -ErrorAction SilentlyContinue -Encoding default
        }
        catch{}
    }
}



LogFileCheck
#endregion Log File Management