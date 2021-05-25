$ScanHttpServerFolder = "C:\ScanHttpServer\bin"
$ExePath = "$ScanHttpServerFolder\ScanHttpServer.dll"
$JobName = "StartRunLoopScanHttpServer"

cd $ScanHttpServerFolder
Start-Transcript -Path runLoopStartup.log
Write-Host Install .net 5 sdk + runtime
if (-Not (Test-Path $ScanHttpServerFolder\dotnet-install.ps1)){
    Write-Host dotnet-install script doesnt exist, Downloading
    Invoke-WebRequest "https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.ps1" -OutFile $ScanHttpServerFolder\dotnet-install.ps1
}

Write-Host Installing dotnet Runtime
.\dotnet-install.ps1 -Channel Current -Runtime dotnet

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
Stop-Transcript