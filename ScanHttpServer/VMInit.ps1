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

Write-Host Creating and adding certificate

$cert = New-SelfSignedCertificate –DnsName ScanServerCert -CertStoreLocation "Cert:\LocalMachine\My"
$thumb = $cert.Thumbprint
Write-Host successfully created new certificate $cert
$appGuid = '{'+[guid]::NewGuid().ToString()+'}'
netsh http delete sslcert ipport=0.0.0.0:443
netsh http add sslcert ipport=0.0.0.0:443 appid=$appGuid certhash="$thumb"

#Updating antivirus Signatures
Write-Host Updating Signatures for the antivirus
& "C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate

#Running the App
Write-Host Starting Run-Loop
start-process powershell -verb runas -ArgumentList "$ScanHttpServerFolder\runLoop.ps1"
Stop-Transcript