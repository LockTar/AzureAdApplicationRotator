using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public interface IKeyVaultService
    {
        ILogger Log { get; set; }

        Task<List<SecretItem>> GetAllSecretsFromKeyVault();

        Task SetSecret(SecretItem secret, string secretValue, IDictionary<string, string> tags);
    }
}