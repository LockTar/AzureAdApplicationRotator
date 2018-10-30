using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent.Models;
using Microsoft.Azure.WebJobs.Host;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Rest.Azure;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    internal class RotatorWorker
    {
        private const string ApplicationObjectIdTagName = "ApplicationObjectId";

        private readonly ILogger _log;
        private readonly KeyVaultClient _keyVaultClient;
        private readonly string _keyVaultUrl;

        internal RotatorWorker(ILogger log, KeyVaultClient keyVaultClient, string keyVaultUrl)
        {
            _log = log;
            _keyVaultClient = keyVaultClient;
            _keyVaultUrl = keyVaultUrl;
        }

        internal async Task Rotate(IActiveDirectoryApplication application, string keyName)
        {
            var secrets = await GetAllSecretsFromKeyVault();
            var secret = GetSecretByApplicationObjectId(application.Id, secrets);

            if (secret == null)
            {
                _log.LogError($"No secret found in the KeyVault that belongs by the application with ObjectId '{application.Id}'. Key rotation for this application will be skipped. Add a secret to the KeyVault for this application to start key rotation.");
            }
            else
            {
                string key = GenerateSecretKey();
                await AddSecretToActiveDirectoryApplication(application, keyName, key);

                var tags = secret.Tags;
                _log.LogDebug($"Set new value for secret '{secret.Identifier.Name}' in KeyVault");
                await _keyVaultClient.SetSecretAsync(_keyVaultUrl, secret.Identifier.Name, key, tags);
                _log.LogInformation($"Updated the secret '{secret.Identifier.Name}' with a new value in the KeyVault");
            }
        }

        private async Task<List<SecretItem>> GetAllSecretsFromKeyVault()
        {
            _log.LogInformation("Get all secrets from KeyVault");
            List<SecretItem> allSecrets = new List<SecretItem>();

            _log.LogDebug($"Get secrets from '{_keyVaultUrl}'");
            var secretsPage = await _keyVaultClient.GetSecretsAsync(_keyVaultUrl);
            allSecrets.AddRange(secretsPage.ToList());

            while (!string.IsNullOrWhiteSpace(secretsPage.NextPageLink))
            {
                _log.LogDebug($"Found another page with secrets. Get secrets from '{secretsPage.NextPageLink}'");
                secretsPage = await _keyVaultClient.GetSecretsAsync(secretsPage.NextPageLink);
                allSecrets.AddRange(secretsPage.ToList());
            }

            _log.LogDebug($"Found in total {allSecrets.Count} secret(s)");
            return allSecrets;
        }

        private SecretItem GetSecretByApplicationObjectId(string applicationObjectId, List<SecretItem> secrets)
        {
            _log.LogDebug($"Get secret with the tag '{ApplicationObjectIdTagName}' and value '{applicationObjectId}'");

            var secretItem = secrets.SingleOrDefault(s =>
                   s.Tags != null &&
                   s.Tags.Keys.Contains(ApplicationObjectIdTagName) &&
                   s.Tags[ApplicationObjectIdTagName] == applicationObjectId);

            if (secretItem == null)
            {
                _log.LogInformation($"No secret found with the tag '{ApplicationObjectIdTagName}' and value '{applicationObjectId}'");
            }
            else
            {
                _log.LogInformation($"Found secret '{secretItem.Identifier.Name}' by Application ObjectId '{applicationObjectId}' in the KeyVault");
            }

            return secretItem;
        }

        private async Task AddSecretToActiveDirectoryApplication(IActiveDirectoryApplication application, string keyName, string key)
        {
            _log.LogDebug($"Add new secret to application with Id '{application.Id}'");
                        
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

                _log.LogInformation($"Added new key with name '{availableKeyName}' to application with id '{application.Id}' that is valid from UTC '{utcNow}' with a duraction of '{keyDurationInMinutes}' minutes");
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    _log.LogError($"Forbidden to set key for active directory application with id '{application.Id}'");
                    _log.LogDebug($"Extra info for application with id '{application.Id}': '{ex.Response.Content}'.");
                }
                else
                {
                    _log.LogError(ex.Response.Content);
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

        private string GenerateSecretKey()
        {
            _log.LogDebug("Generate a new secret");

            var bytes = new byte[32];
            using (var provider = new RNGCryptoServiceProvider())
            {
                provider.GetBytes(bytes);
            }

            var secret = Convert.ToBase64String(bytes);

            return secret;
        }

        internal async Task RotateAll()
        {
            var secrets = await GetAllSecretsFromKeyVault();

            foreach (var secret in secrets)
            {
                if (secret.Tags != null && secret.Tags.Keys.Contains(ApplicationObjectIdTagName))
                {
                    // Get application

                    // Rotate secret for application and store in key vault
                }
            }
        }
    }
}
