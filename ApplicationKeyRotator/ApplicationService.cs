using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent.Models;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public class ApplicationService : IApplicationService
    {
        private readonly IAuthenticationHelper _authenticationHelper;
        
        public ILogger Log { get; set; }

        public ApplicationService(IAuthenticationHelper authenticationHelper)
        {
            _authenticationHelper = authenticationHelper;
        }

        public async Task<IActiveDirectoryApplication> GetApplication(string id)
        {
            _authenticationHelper.Log = Log;
            Log.LogDebug($"Searching for active directory application resource id '{id}'");
            
            var azure = _authenticationHelper.GetAzureConnection();

            try
            {
                var application = await azure.AccessManagement.ActiveDirectoryApplications.GetByIdAsync(id);

                if (application == null)
                {
                    Log.LogInformation($"No active directory application found by id '{id}'");
                }
                else
                {
                    Log.LogInformation($"Found active directory application '{application.Name}' by id '{application.Id}' and applicationId '{application.ApplicationId}'");
                }

                return application;
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    Log.LogError($"Forbidden to get active directory application with id '{id}'");
                }
                else if (ex.Response.StatusCode == HttpStatusCode.NotFound)
                {
                    Log.LogError($"Can't find active directory application with id '{id}'");
                }
                else
                {
                    Log.LogError(ex.Response.Content);
                }

                return null;
            }
        }

        public async Task AddSecretToActiveDirectoryApplication(IActiveDirectoryApplication application, string keyName, string key)
        {
            Log.LogDebug($"Add new secret to application with Id '{application.Id}'");

            string availableKeyName = GetAvailableKeyName(application, keyName, 1);
            int keyDurationInMinutes = 5;
            var duration = new TimeSpan(0, keyDurationInMinutes, 0);
            DateTime utcNow = DateTime.UtcNow;

            try
            {
                await application
                    .Update()
                        .DefinePasswordCredential(availableKeyName)
                        .WithPasswordValue(key)
                        .WithStartDate(utcNow)
                        .WithDuration(duration)
                        .Attach()
                    .ApplyAsync();

                Log.LogInformation($"Added new key with name '{availableKeyName}' to application with id '{application.Id}' that is valid from UTC '{utcNow}' with a duraction of '{keyDurationInMinutes}' minutes");
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    Log.LogError($"Forbidden to set key for active directory application with id '{application.Id}'");
                    Log.LogDebug($"Extra info for application with id '{application.Id}': '{ex.Response.Content}'.");
                }
                else
                {
                    Log.LogError(ex.Response.Content);
                }
            }
        }

        public async Task RemoveExpiredKeys(IActiveDirectoryApplication application)
        {
            Log.LogInformation($"Remove expired keys of application with Id '{application.Id}'");

            try
            {
                var expiredCredentials = application
                    .PasswordCredentials
                        .Where(s => s.Value.EndDate < DateTime.UtcNow)
                    .ToList();

                foreach (var expiredCredential in expiredCredentials)
                {
                    await application
                        .Update()
                            .WithoutCredential(expiredCredential.Value.Name)
                        .ApplyAsync();
                }

                Log.LogInformation($"Removed the expired keys of application with id '{application.Id}'");
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    Log.LogError($"Forbidden to remove expired keys of active directory application with id '{application.Id}'");
                    Log.LogDebug($"Extra info for application with id '{application.Id}': '{ex.Response.Content}'.");
                }
                else
                {
                    Log.LogError(ex.Response.Content);
                }
            }
        }

        private string GetAvailableKeyName(IActiveDirectoryApplication application, string keyName, int suffixNumber)
        {
            string completeKeyName = keyName + suffixNumber;

            var existingKeyNames = application.PasswordCredentials.Values.Select(p => p.Name);
            if (!existingKeyNames.Contains(completeKeyName))
            {
                return completeKeyName;
            }
            else
            {
                suffixNumber++;
                return GetAvailableKeyName(application, keyName, suffixNumber);
            }
        }
    }
}
