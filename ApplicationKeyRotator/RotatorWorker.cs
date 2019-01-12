using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ApplicationKeyRotator.Applications;
using ApplicationKeyRotator.Helpers;
using ApplicationKeyRotator.KeyVaults;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public class RotatorWorker : IRotatorWorker
    {
        private const string ApplicationObjectIdTagName = "ApplicationObjectId";
        
        private readonly IKeyVaultService _keyVaultService;
        private readonly IApplicationService _applicationService;

        public ILogger Log { get; set; }

        public RotatorWorker(IKeyVaultService keyVaultService, IApplicationService applicationService)
        {
            _keyVaultService = keyVaultService;
            _applicationService = applicationService;
        }

        public async Task RotateAll()
        {
            _keyVaultService.Log = Log;
            _applicationService.Log = Log;

            Log.LogInformation("Get all secrets from KeyVault because RotateAll function triggered");
            var allSecrets = await _keyVaultService.GetAllSecretsFromKeyVault();

            if (allSecrets.Any())
            {
                Log.LogInformation($"Found {allSecrets.Count} secret(s) to rotate");

                foreach (var secret in allSecrets)
                {
                    Log.LogDebug($"Check if secret '{secret.Identifier.Name}' has the tag '{ApplicationObjectIdTagName}'");

                    if (secret.Tags != null && secret.Tags.Keys.Contains(ApplicationObjectIdTagName))
                    {                        
                        string applicationObjectId = secret.Tags[ApplicationObjectIdTagName];
                        Log.LogInformation($"Secret '{secret.Identifier.Name}' belongs to application '{applicationObjectId}'. Let's rotate.");

                        var application = await _applicationService.GetApplication(applicationObjectId);
                        await Rotate(application);
                    }
                    else
                    {
                        Log.LogInformation($"Secret '{secret.Identifier.Name}' has no or not the right tag so skip rotation");
                    }
                }
            }
            else
            {
                Log.LogInformation("No secrets found in the KeyVault to rotate");
            }

            Log.LogInformation($"All {allSecrets.Count} secret(s) finished with rotating");
        }

        public async Task Rotate(IActiveDirectoryApplication application, string keyName = null, int keyDurationInMinutes = 0)
        {
            _keyVaultService.Log = Log;
            _applicationService.Log = Log;

            if (string.IsNullOrWhiteSpace(keyName))
            {                
                keyName = Environment.GetEnvironmentVariable("DefaultKeyName", EnvironmentVariableTarget.Process);
                Log.LogDebug($"No custom keyname so use default keyname '{keyName}'");
            }

            var allSecrets = await _keyVaultService.GetAllSecretsFromKeyVault();
            var secret = GetSecretByApplicationObjectId(allSecrets, application.Id);

            if (secret == null)
            {
                Log.LogWarning($"No secret found in the KeyVault that belongs by the application with ObjectId '{application.Id}'. Key rotation for this application will be skipped. Add a secret to the KeyVault for this application to start key rotation.");
            }
            else
            {
                string key = SecretHelper.GenerateSecretKey();

                await _applicationService.AddSecretToActiveDirectoryApplication(application, keyName, key, keyDurationInMinutes);
                await _keyVaultService.SetSecret(secret, key, secret.Tags);
            }

            await _applicationService.RemoveExpiredKeys(application);
        }
        
        private SecretItem GetSecretByApplicationObjectId(List<SecretItem> secrets, string applicationObjectId)
        {
            Log.LogDebug($"Get secret with the tag '{ApplicationObjectIdTagName}' and value '{applicationObjectId}'");

            var secretItem = secrets.SingleOrDefault(s =>
                   s.Tags != null &&
                   s.Tags.Keys.Contains(ApplicationObjectIdTagName) &&
                   s.Tags[ApplicationObjectIdTagName] == applicationObjectId);

            if (secretItem == null)
            {
                Log.LogInformation($"No secret found with the tag '{ApplicationObjectIdTagName}' and value '{applicationObjectId}'");
            }
            else
            {
                Log.LogInformation($"Found secret '{secretItem.Identifier.Name}' by Application ObjectId '{applicationObjectId}' in the KeyVault");
            }

            return secretItem;
        }
    }
}
