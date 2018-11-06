using System;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Extensions.Logging;
using Microsoft.Rest;

namespace ApplicationKeyRotator
{
    public class AuthenticationHelper : IAuthenticationHelper
    {
        private IAzure _azure = null;

        public ILogger Log { get; set; }

        public IAzure GetAzureConnection()
        {
            if (_azure != null)
            {
                return _azure;
            }

            AzureCredentials credentials;
            string localDevelopment = Environment.GetEnvironmentVariable("LocalDevelopment", EnvironmentVariableTarget.Process);

            if (!string.IsNullOrEmpty(localDevelopment) &&
                string.Equals(localDevelopment, "true", StringComparison.InvariantCultureIgnoreCase))
            {
                Log.LogDebug($"Get the local service principal for local login");
                var localDevSp = new Principal
                {
                    UserPrincipalName = "LocalLogin",
                    AppId = Environment.GetEnvironmentVariable("ClientId", EnvironmentVariableTarget.Process),
                    TenantId = Environment.GetEnvironmentVariable("TenantId", EnvironmentVariableTarget.Process)
                };
                string clientSecret = Environment.GetEnvironmentVariable("ClientSecret", EnvironmentVariableTarget.Process);

                Log.LogDebug($"Get the local sp credentials");
                credentials = SdkContext
                    .AzureCredentialsFactory
                    .FromServicePrincipal(localDevSp.AppId, clientSecret, localDevSp.TenantId, AzureEnvironment.AzureGlobalCloud);
            }
            else
            {
                Log.LogDebug($"Get the MSI credentials");
                credentials = SdkContext
                     .AzureCredentialsFactory
                     .FromMSI(new MSILoginInformation(MSIResourceType.AppService), AzureEnvironment.AzureGlobalCloud);
            }

            ServiceClientTracing.AddTracingInterceptor(new MicrosoftExtensionsLoggingTracer(Log));
            ServiceClientTracing.IsEnabled = true;

            Log.LogDebug($"Construct the Azure object");
            _azure = Azure
                .Configure()
                .WithDelegatingHandler(new HttpLoggingDelegatingHandler())
                .WithLogLevel(HttpLoggingDelegatingHandler.Level.Basic)
                .Authenticate(credentials)
                .WithDefaultSubscription();

            return _azure;
        }

    }
}
