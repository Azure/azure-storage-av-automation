using System;
using System.IO;
using HttpMultipartParser;
using Serilog;

namespace ScanHttpServer
{
    public static class FileUtilities
    {
       public static string SaveToTempFile(Stream fileData)
        {
            string tempFileName = Path.GetTempFileName();
            Log.Information("tmpFileName: {tempFileName}", tempFileName);
            try
            {
                using (var fileStream = File.OpenWrite(tempFileName))
                {
                    fileData.CopyTo(fileStream);
                }
                Log.Information("File created Successfully");
                return tempFileName;
            }
            catch (Exception e)
            {
                Log.Error(e, "Exception caught when trying to save temp file {tempFileName}.", tempFileName);
                return null;
            }
        }
        public static string SaveToTempfileStreaming(Stream fileData, out string filenameInRequest)
        {
            var parser = new StreamingMultipartFormDataParser(fileData);
            string blobFilename = string.Empty;
            string tempFileName = tempFileName = Path.GetTempFileName();
            Log.Information($"Creating: {tempFileName}");

            try
            {
                using (var fileStream = File.OpenWrite(tempFileName))
                {
                    parser.FileHandler += (name, fileName, type, disposition, buffer, bytes, partNumber, additionalProperties) =>
                    {
                        // Write the part of the file we've received to a file stream.
                        fileStream.Write(buffer, 0, bytes);
                        blobFilename = fileName;
                    };
                    parser.Run();
                }
                Log.Information($"Temp file created successfully for {blobFilename}: {tempFileName}");
                filenameInRequest = blobFilename;
                return tempFileName;
            }
            catch (Exception e)
            {
                Log.Error(e, $"Exception caught when trying to save temp file {tempFileName}.");
                filenameInRequest = blobFilename;
                return null;
            }
        }

    }
}
