using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent.Models;
using System;
using System.Linq;
using System.Collections.Generic;
using System.Net;
using System.Security.Cryptography;
using System.Threading.Tasks;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
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

            var allSecrets = await _keyVaultService.GetAllSecretsFromKeyVault();

            foreach (var secret in allSecrets)
            {
                if (secret.Tags != null && secret.Tags.Keys.Contains(ApplicationObjectIdTagName))
                {
                    string applicationObjectId = secret.Tags[ApplicationObjectIdTagName];

                    var application = await _applicationService.GetApplication(applicationObjectId);
                    await Rotate(application);
                }
            }
        }

        public async Task Rotate(IActiveDirectoryApplication application, string keyName = "RotatedKey")
        {
            _keyVaultService.Log = Log;
            _applicationService.Log = Log;

            var allSecrets = await _keyVaultService.GetAllSecretsFromKeyVault();
            var secret = GetSecretByApplicationObjectId(allSecrets, application.Id);

            if (secret == null)
            {
                Log.LogWarning($"No secret found in the KeyVault that belongs by the application with ObjectId '{application.Id}'. Key rotation for this application will be skipped. Add a secret to the KeyVault for this application to start key rotation.");
            }
            else
            {
                string key = SecretHelper.GenerateSecretKey();

                await _applicationService.AddSecretToActiveDirectoryApplication(application, keyName, key);
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
