$ScanHttpServerFolder = "C:\ScanHttpServer\bin"
$ExePath = "$ScanHttpServerFolder\ScanHttpServer.dll"
$JobName = "StartRunLoopScanHttpServer"

cd $ScanHttpServerFolder
# Install .net 5 sdk + runtime
if (-Not (Test-Path $ScanHttpServerFolder\dotnet-install.ps1)){
    Invoke-WebRequest "https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.ps1" -OutFile $ScanHttpServerFolder\dotnet-install.ps1
}

#instaling runtime
.\dotnet-install.ps1 -Channel Current -Runtime dotnet

if((Get-ScheduledJob -Name $JobName -ErrorAction SilentlyContinue).Length -lt 1){
    #Adding VMInit.ps1 as startup job
    $trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
    Register-ScheduledJob -Trigger $trigger -FilePath "$PSScriptRoot\runLoop.ps1" -Name $JobName
}

Write-Host Starting Process $ExePath
while($true){
    $process = Start-Process dotnet -ArgumentList $ExePath -PassThru -Wait
    
    if($process.ExitCode -ne 0){
        Write-Host Process Exited with errors, please check the logs in $ScanHttpServerFolder\log
    }
    else {
        Write-Host Proccess Exited with no errors
    }

    Write-Host Restarting Process $ExePath
}