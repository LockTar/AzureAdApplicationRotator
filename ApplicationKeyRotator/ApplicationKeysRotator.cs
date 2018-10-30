using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent.Models;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Rest;
using System;
using System.Net;
using System.Threading.Tasks;
using Willezone.Azure.WebJobs.Extensions.DependencyInjection;

namespace ApplicationKeyRotator
{
    public static class ApplicationKeysRotator
    {
        private static ILogger _log;

        [FunctionName("AllApplicationIds")]
        public static async Task<IActionResult> RunAllApplicationIds([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]HttpRequest req, ILogger log, [Inject] IKeyVaultHelper keyVaultHelper, [Inject] IRotatorWorker worker)
        {
            _log = log;
            worker._log = _log;
            
            await worker.RotateAll();

            return new OkResult();
        }

        [FunctionName("ByApplicationObjectId")]
        public static async Task<IActionResult> RunByApplicationObjectId([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]HttpRequest req, ILogger log, [Inject] IKeyVaultHelper keyVaultHelper, [Inject] IRotatorWorker worker)
        {
            _log = log;
            worker._log = _log;

            string id = req.Query["id"];

            if (string.IsNullOrWhiteSpace(id))
            {
                const string message = "No id parameter found in querystring";
                _log.LogDebug(message);
                return new BadRequestObjectResult(message);
            }
            else
            {
                _log.LogInformation($"Found id '{id}' in querystring to rotate");
            }

            var azure = GetAzureConnection();
            var application = await GetApplication(azure, id);

            if (application == null)
            {
                return new NotFoundResult();
            }

            const string keyName = "RotatedKey";
            await worker.Rotate(application, keyName);

            return new OkResult();
        }

        private static async Task<IActiveDirectoryApplication> GetApplication(IAzure azure, string id)
        {
            _log.LogDebug($"Searching for active directory application resource id '{id}'");
            
            try
            {
                ////string name = "test";
                ////var application = azure.AccessManagement.ActiveDirectoryApplications
                ////.Define(name)
                ////    .WithSignOnUrl("https://github.com/Azure/azure-sdk-for-java/" + name)
                ////    // password credentials definition
                ////    .DefinePasswordCredential("password")
                ////        .WithPasswordValue("P@ssw0rd")
                ////        .WithDuration(TimeSpan.FromDays(700))
                ////        .Attach()
                ////    .Create();

                var application = await azure.AccessManagement.ActiveDirectoryApplications.GetByIdAsync(id);

                if (application == null)
                {
                    _log.LogInformation($"No active directory application found by id '{id}'");
                }
                else
                {
                    _log.LogInformation($"Found active directory application '{application.Name}' by id '{application.Id}' and applicationId '{application.ApplicationId}'");
                }

                return application;
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    _log.LogError($"Forbidden to get active directory application with id '{id}'");
                }
                else if (ex.Response.StatusCode == HttpStatusCode.NotFound)
                {
                    _log.LogError($"Can't find active directory application with id '{id}'");
                }
                else
                {
                    _log.LogError(ex.Response.Content);
                }

                return null;
            }
        }

        private static IAzure GetAzureConnection()
        {
            AzureCredentials credentials;
            string localDevelopment = Environment.GetEnvironmentVariable("LocalDevelopment", EnvironmentVariableTarget.Process);

            if (!string.IsNullOrEmpty(localDevelopment) &&
                string.Equals(localDevelopment, "true", StringComparison.InvariantCultureIgnoreCase))
            {
                _log.LogDebug($"Get the local service principal for local login");                
                var localDevSp = new Principal
                {
                    UserPrincipalName = "LocalLogin",
                    AppId = Environment.GetEnvironmentVariable("ClientId", EnvironmentVariableTarget.Process),
                    TenantId = Environment.GetEnvironmentVariable("TenantId", EnvironmentVariableTarget.Process)
                };
                string clientSecret = Environment.GetEnvironmentVariable("ClientSecret", EnvironmentVariableTarget.Process);

                _log.LogDebug($"Get the local sp credentials");
                credentials = SdkContext
                    .AzureCredentialsFactory
                    .FromServicePrincipal(localDevSp.AppId, clientSecret, localDevSp.TenantId, AzureEnvironment.AzureGlobalCloud);
            }
            else
            {
                _log.LogDebug($"Get the MSI credentials");
                credentials = SdkContext
                     .AzureCredentialsFactory
                     .FromMSI(new MSILoginInformation(MSIResourceType.AppService), AzureEnvironment.AzureGlobalCloud);
            }

            ServiceClientTracing.AddTracingInterceptor(new MicrosoftExtensionsLoggingTracer(_log));
            ServiceClientTracing.IsEnabled = true;
            
            _log.LogDebug($"Construct the Azure object");
            var azure = Azure
                .Configure()
                .WithDelegatingHandler(new HttpLoggingDelegatingHandler())
                .WithLogLevel(HttpLoggingDelegatingHandler.Level.Basic)
                .Authenticate(credentials)
                .WithDefaultSubscription();

            return azure;
        }
    }
}
