using Microsoft.Extensions.Logging;
using Microsoft.Rest;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace ApplicationKeyRotator
{
    public class MicrosoftExtensionsLoggingTracer : IServiceClientTracingInterceptor
    {
        private readonly ILogger _logger;

        public MicrosoftExtensionsLoggingTracer(ILogger logger)
        {
            _logger = logger;
        }

        public void Information(string message)
        {
            _logger.LogInformation(message);
        }

        public void TraceError(string invocationId, Exception exception)
        {
            _logger.LogError(exception, $"Exception with id: {invocationId}");
        }

        public void ReceiveResponse(string invocationId, HttpResponseMessage response)
        {
            _logger.LogTrace($"Response with id: {invocationId} response: {response}");
        }

        public void SendRequest(string invocationId, HttpRequestMessage request)
        {
            _logger.LogTrace($"Request with id: {invocationId} request: {request}");
        }

        public void Configuration(string source, string name, string value)
        {
            _logger.LogTrace($"Configuration of source: {source} with name: {name} and value: {value}");
        }

        public void EnterMethod(string invocationId, object instance, string method, IDictionary<string, object> parameters)
        {
            _logger.LogTrace($"EnterMethod with id: {invocationId} instance: {instance} method: {method}");
        }

        public void ExitMethod(string invocationId, object returnValue)
        {
            _logger.LogTrace($"ExitMethod with id {invocationId}: {returnValue}");
        }
    }
}
