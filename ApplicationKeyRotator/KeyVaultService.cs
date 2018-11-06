using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public class KeyVaultService : IKeyVaultService
    {
        private readonly KeyVaultClient _keyVaultClient;
        private readonly string _keyVaultUrl;

        private List<SecretItem> _allSecrets;

        public ILogger Log { get; set; }

        public KeyVaultService(IKeyVaultHelper keyVaultHelper)
        {
            _keyVaultClient = keyVaultHelper.GetKeyVaultClient();
            _keyVaultUrl = keyVaultHelper.GetKeyVaultUrl();
        }

        public async Task<List<SecretItem>> GetAllSecretsFromKeyVault()
        {
            if (_allSecrets != null)
            {
                return _allSecrets;
            }

            Log.LogInformation("Get all secrets from KeyVault");
            _allSecrets = new List<SecretItem>();

            Log.LogDebug($"Get secrets from '{_keyVaultUrl}'");
            var secretsPage = await _keyVaultClient.GetSecretsAsync(_keyVaultUrl);
            _allSecrets.AddRange(secretsPage.ToList());

            while (!string.IsNullOrWhiteSpace(secretsPage.NextPageLink))
            {
                Log.LogDebug($"Found another page with secrets. Get secrets from '{secretsPage.NextPageLink}'");
                secretsPage = await _keyVaultClient.GetSecretsAsync(secretsPage.NextPageLink);
                _allSecrets.AddRange(secretsPage.ToList());
            }

            Log.LogDebug($"Found in total {_allSecrets.Count} secret(s)");
            return _allSecrets;
        }

        public async Task SetSecret(SecretItem secret, string secretValue, IDictionary<string, string> tags)
        {
            Log.LogDebug($"Set new value for secret '{secret.Identifier.Name}' in KeyVault");
            await _keyVaultClient.SetSecretAsync(_keyVaultUrl, secret.Identifier.Name, secretValue, tags);
            Log.LogInformation($"Updated the secret '{secret.Identifier.Name}' with a new value in the KeyVault");
        }
    }
}
