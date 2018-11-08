using System;
using System.Security.Cryptography;

namespace ApplicationKeyRotator.Helpers
{
    internal static class SecretHelper
    {
        internal static string GenerateSecretKey()
        {
            var bytes = new byte[32];
            using (var provider = new RNGCryptoServiceProvider())
            {
                provider.GetBytes(bytes);
            }

            var secret = Convert.ToBase64String(bytes);

            return secret;
        }
    }
}
