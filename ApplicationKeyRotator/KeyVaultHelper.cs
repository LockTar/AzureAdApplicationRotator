using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.Services.AppAuthentication;

namespace ApplicationKeyRotator
{
    public class KeyVaultHelper : IKeyVaultHelper
    {
        public string GetKeyVaultUrl()
        {
            const string KeyVaultEnvironmentVariableName = "KeyVaultUrl";
            string keyVaultUrl = Environment.GetEnvironmentVariable(KeyVaultEnvironmentVariableName, EnvironmentVariableTarget.Process);

            if (string.IsNullOrWhiteSpace(keyVaultUrl))
            {
                throw new ApplicationException($"Missing environment variable '{KeyVaultEnvironmentVariableName}' with as value the url of the KeyVault");
            }

            return keyVaultUrl;
        }

        public KeyVaultClient GetKeyVaultClient()
        {
            var azureServiceTokenProvider = new AzureServiceTokenProvider();
            var keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback));

            return keyVaultClient;
        }

    }
}
