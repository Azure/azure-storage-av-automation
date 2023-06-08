using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System.IO;
using System;

namespace ScanUploadedBlobFunction
{
    public static class ScanUploadedBlob
    {
        
        [FunctionName("ScanUploadedBlob")]
        public static void Run([BlobTrigger("%targetContainerName%/{name}", Connection = "windefenderstorage")] Stream myBlob, string name, ILogger log)
        {
            log.LogInformation($"C# Blob trigger ScanUploadedBlob function Processing blob Name:{name} Size: {myBlob.Length} Bytes");

            var scannerHost = Environment.GetEnvironmentVariable("windowsdefender_host");
            var scannerPort = Environment.GetEnvironmentVariable("windowsdefender_port");

            var scanner = new ScannerProxy(log, scannerHost);
            var scanResults = scanner.Scan(myBlob, name);
            if (scanResults == null)
            {
                return;
            }
            log.LogInformation($"Scan Results - {scanResults.ToString(", ")}");
            log.LogInformation($"Handling Scan Results for {name}");
            var action = new Remediation(scanResults, log);
            action.Start();
            log.LogInformation($"ScanUploadedBlob function done Processing blob Name: {name} Size: {myBlob.Length} Bytes");
        }
    }
}
