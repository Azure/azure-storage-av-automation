#Init
$ScanHttpServerFolder = "C:\ScanHttpServer\bin"
$runLoopPath = "$ScanHttpServerFolder\runLoop.ps1"

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

Write-Host Scheduling task for startup

&schtasks /create /tn StartScanHttpServer /sc onstart /tr "powershell.exe C:\ScanHttpServer\bin\runLoop.ps1"  /NP /DELAY 0001:00 /RU SYSTEM

Write-Host Creating and adding certificate

$cert = New-SelfSignedCertificate -DnsName ScanServerCert -CertStoreLocation "Cert:\LocalMachine\My"
$thumb = $cert.Thumbprint
$appGuid = '{'+[guid]::NewGuid().ToString()+'}'

Write-Host successfully created new certificate $cert

netsh http delete sslcert ipport=0.0.0.0:443
netsh http add sslcert ipport=0.0.0.0:443 appid=$appGuid certhash="$thumb"

Write-Host Adding firewall rules
New-NetFirewallRule -DisplayName "ServerFunctionComunicationIn" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "ServerFunctionComunicationOut" -Direction Outbound -LocalPort 443 -Protocol TCP -Action Allow

#Updating antivirus Signatures
Write-Host Updating Signatures for the antivirus
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate
#Running the App
Write-Host Starting Run-Loop
start-process powershell -verb runas -ArgumentList $runLoopPath

Stop-Transcript