using HttpMultipartParser;
using Newtonsoft.Json;
using Serilog;
using Serilog.Exceptions;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Threading.Tasks;
using System.Reflection;
using System.Linq;

namespace ScanHttpServer
{
    public class ScanHttpServer
    {

        private enum requestType { SCAN }

        public static async Task HandleRequestAsync(HttpListenerContext context)
        {
            var request = context.Request;
            var response = context.Response;

            Log.Information("Got new request {requestUrl}", request.Url);
            Log.Information("Raw URL: {requestRawUrl}", request.RawUrl);
            Log.Information("request.ContentType: {requestContentType}", request.ContentType);

            var requestTypeTranslation = new Dictionary<string, requestType>
            {
                { "/scan", requestType.SCAN }
            };

            requestType type = requestTypeTranslation[request.RawUrl];

            switch (type)
            {
                case requestType.SCAN:
                    ScanRequest(request, response);
                    break;
                default:
                    Log.Information("No valid request type");
                    break;
            }
            Log.Information("Done Handling Request {requestUrl}", request.Url);
        }

        public static void ScanRequest(HttpListenerRequest request, HttpListenerResponse response)
        {
            if (!request.ContentType.StartsWith("multipart/form-data", StringComparison.OrdinalIgnoreCase))
            {
                Log.Error("Wrong request Content-type for scanning, {requestContentType}", request.ContentType);
                return;
            };

            /* Commented out the following code as it was reading the entire blob into memory, which was failing if the file size was >2GB
            var parser = MultipartFormDataParser.Parse(request.InputStream);
            var fileName = parser.Files.First();
            Log.Information("filename: {fileName}", file.FileName);

            string tempFileName = FileUtilities.SaveToTempFile(file.Data);
            */

            // Stream the blob contents directly to a tempfile rather than loading the whole blob into memory, allowing us to process very large files (>2GB).
            //var stream = request.InputStream;
            string filenameInRequest;
            string tempFileName = FileUtilities.SaveToTempfileStreaming(request.InputStream, out filenameInRequest);

            if (tempFileName == null)
            {
                Log.Error("Can't save the file received in the request");
                return;
            }

            var scanner = new WindowsDefenderScanner();
            var result = scanner.Scan(tempFileName);

            if (result.isError)
            {
                Log.Error($"Error while scanning {tempFileName} - Error message:{result.errorMessage}");

                var data = new
                {
                    ErrorMessage = result.errorMessage,
                };

                SendResponse(response, HttpStatusCode.InternalServerError, data);
                return;
            }

            var responseData = new
            {
                FileName = filenameInRequest, //file.FileName,
                isThreat = result.isThreat,
                ThreatType = result.threatType
            };

            SendResponse(response, HttpStatusCode.OK, responseData);

            try
            {
                File.Delete(tempFileName);
                Log.Information($"Delete tempfile: {tempFileName}");
            }
            catch (Exception e)
            {
                Log.Error(e, "Exception caught when trying to delete temp file:{tempFileName}.", tempFileName);
            }
        }

        private static void SendResponse(
            HttpListenerResponse response,
            HttpStatusCode statusCode,
            object responseData)
        {
            response.StatusCode = (int)statusCode;
            string responseString = JsonConvert.SerializeObject(responseData);
            byte[] buffer = System.Text.Encoding.UTF8.GetBytes(responseString);
            response.ContentLength64 = buffer.Length;
            var responseOutputStream = response.OutputStream;
            try
            {
                responseOutputStream.Write(buffer, 0, buffer.Length);
            }
            finally
            {
                Log.Information("Sending response, {statusCode}:{responseString}", statusCode, responseString);
                responseOutputStream.Close();
            }
        }

        public static void SetUpLogger(string logFileName)
        {
            string runDirPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string logFilePath = Path.Combine(runDirPath, "log", logFileName);
            Log.Logger = new LoggerConfiguration()
                .Enrich.WithExceptionDetails()
                .WriteTo.File(logFilePath)
                .WriteTo.Console()
                .MinimumLevel.Debug()
                .CreateLogger();
        }

        public static void Main(string[] args)
        {
            int port = 443;
            string[] prefix = {
                $"https://+:{port}/"
            };

            SetUpLogger("ScanHttpServer.log");
            var listener = new HttpListener();

            foreach (string s in prefix)
            {
                listener.Prefixes.Add(s);
            }

            listener.Start();
            Log.Information("Starting ScanHttpServer");

            while (true)
            {
                Log.Information("Waiting for requests...");
                var context = listener.GetContext();
                Task.Run(() => HandleRequestAsync(context));
            }
        }
    }
}
