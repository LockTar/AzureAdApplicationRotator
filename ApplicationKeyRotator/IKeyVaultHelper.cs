using Microsoft.Azure.KeyVault;

namespace ApplicationKeyRotator
{
    public interface IKeyVaultHelper
    {
        string GetKeyVaultUrl();

        KeyVaultClient GetKeyVaultClient();
    }
}