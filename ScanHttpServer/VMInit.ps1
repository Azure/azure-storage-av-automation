#Init
$ScanHttpServerFolder = "C:\ScanHttpServer\bin"

Start-Transcript -Path C:\VmInit.log
New-Item -ItemType Directory C:\ScanHttpServer
New-Item -ItemType Directory $ScanHttpServerFolder

if($args.Count -gt 0){
    if(-Not (Test-Path $ScanHttpServerFolder\vminit.config)){
        New-Item $ScanHttpServerFolder\vminit.config
    }
    Set-Content $ScanHttpServerFolder\vminit.config $args[0]
}

$ScanHttpServerBinZipUrl = Get-Content $ScanHttpServerFolder\vminit.config

# Download Http Server bin files
Invoke-WebRequest $ScanHttpServerBinZipUrl -OutFile $ScanHttpServerFolder\ScanHttpServer.zip
Expand-Archive $ScanHttpServerFolder\ScanHttpServer.zip -DestinationPath $ScanHttpServerFolder\ -Force

cd $ScanHttpServerFolder

Wrtie-Host Scheduling task for startup
&schtasks /create /tn StartScanHttpServer /sc onstart /tr "powershell.exe C:\ScanHttpServer\bin\runLoop.ps1"  /NP /DELAY 0001:00 /RU SYSTEM

#Adding firewall rules to enable traffic
Write-Host adding firewall rules
netsh http add urlacl url="http://+:4151/" user=everyone
New-NetFirewallRule -DisplayName "allowing port 4151" -Direction Inbound -LocalPort 4151 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "allowing port 4151" -Direction Outbound -LocalPort 4151 -Protocol TCP -Action Allow

#Updating antivirus Signatures
Write-Host Updating Signatures for the antivirus
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate

#Running the App
Write-Host Starting Run-Loop
start-process powershell -verb runas -ArgumentList "$ScanHttpServerFolder\runLoop.ps1"
Stop-Transcript