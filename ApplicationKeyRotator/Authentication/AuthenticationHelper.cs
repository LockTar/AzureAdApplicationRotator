using ApplicationKeyRotator.Configuration.Logging;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Extensions.Logging;
using Microsoft.Rest;
using System;
using System.Threading.Tasks;

namespace ApplicationKeyRotator.Authentication
{
    public class AuthenticationHelper : IAuthenticationHelper
    {
        private Azure.IAuthenticated _azure = null;

        public ILogger Log { get; set; }

        public async Task<Azure.IAuthenticated> GetAzureConnection()
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
                Log.LogDebug($"AppId: {localDevSp.AppId}, TenantId: {localDevSp.TenantId}");

                credentials = SdkContext
                    .AzureCredentialsFactory
                    .FromServicePrincipal(localDevSp.AppId, clientSecret, localDevSp.TenantId, AzureEnvironment.AzureGlobalCloud);
            }
            else
            {
                Log.LogDebug($"Get the MSI credentials");

                // Because MSI isn't really nicely supported in this nuget package disable it for now and user workaround
                ////credentials = SdkContext
                ////     .AzureCredentialsFactory
                ////     .FromMSI(new MSILoginInformation(MSIResourceType.AppService), AzureEnvironment.AzureGlobalCloud);

                try
                {
                    // START workaround until MSI in this package is really supported
                    string tenantId = Environment.GetEnvironmentVariable("TenantId", EnvironmentVariableTarget.Process);
                    Log.LogDebug($"TenantId: {tenantId}");
                    
                    AzureServiceTokenProvider astp = new AzureServiceTokenProvider();
                    string graphToken = await astp.GetAccessTokenAsync("https://graph.windows.net/", tenantId);
                    AzureServiceTokenProvider astp2 = new AzureServiceTokenProvider();
                    string rmToken = await astp2.GetAccessTokenAsync("https://management.azure.com/", tenantId);

                    Log.LogDebug("Logging with tokens from Token Provider");

                    AzureCredentials customTokenProvider = new AzureCredentials(
                        new TokenCredentials(rmToken),
                        new TokenCredentials(graphToken),
                        tenantId,
                        AzureEnvironment.AzureGlobalCloud);

                    RestClient client = RestClient
                        .Configure()
                        .WithEnvironment(AzureEnvironment.AzureGlobalCloud)
                        .WithLogLevel(HttpLoggingDelegatingHandler.Level.Basic)
                        //.WithRetryPolicy(new RetryPolicy(new HttpStatusCodeErrorDetectionStrategy(), new IncrementalRetryStrategy(2, TimeSpan.FromSeconds(30), TimeSpan.FromMinutes(1))))
                        .WithCredentials(customTokenProvider)
                        .Build();

                    return Azure.Authenticate(client, tenantId);
                    // END workaround until MSI in this package is really supported
                }
                catch (Exception ex)
                {
                    Log.LogError(ex, ex.Message);
                    if (ex.InnerException != null)
                    {
                        Log.LogError(ex.InnerException, ex.InnerException.Message);
                    }
                    throw;
                }
            }

            ServiceClientTracing.AddTracingInterceptor(new MicrosoftExtensionsLoggingTracer(Log));
            ServiceClientTracing.IsEnabled = true;

            _azure = Azure
                .Configure()
                .WithDelegatingHandler(new HttpLoggingDelegatingHandler())
                .WithLogLevel(HttpLoggingDelegatingHandler.Level.None)
                .Authenticate(credentials);

            return _azure;
        }
    }
}
