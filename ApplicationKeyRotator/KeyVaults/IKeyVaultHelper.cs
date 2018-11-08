using Microsoft.Azure.KeyVault;

namespace ApplicationKeyRotator.KeyVaults
{
    public interface IKeyVaultHelper
    {
        string GetKeyVaultUrl();

        KeyVaultClient GetKeyVaultClient();
    }
}