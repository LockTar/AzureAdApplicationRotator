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

namespace SpRotator
{
    internal class RotatorWorker
    {
        private readonly TraceWriter _log;

        internal RotatorWorker(TraceWriter log)
        {
            _log = log;
        }

        internal async Task Rotate(IActiveDirectoryApplication application, string keyName)
        {
            string key = GenerateSecretKey();

            await AddSecretToActiveDirectoryApplication(application, keyName, key);
        }

        private async Task AddSecretToActiveDirectoryApplication(IActiveDirectoryApplication application, string keyName, string key)
        {
            _log.Verbose($"Add new secret to application with Id '{application.Id}'");
                        
            string availableKeyName = GetAvailableKeyName(application, keyName, 1);
            int keyDurationInMinutes = 5;
            var duration = new TimeSpan(0, keyDurationInMinutes, 0);
            DateTime utcNow = DateTime.UtcNow;
            
            try
            {
                // Remove all existing keys... https://github.com/Azure/azure-libraries-for-net/issues/414
                await application
                    .Update()
                        .DefinePasswordCredential(availableKeyName)
                        .WithPasswordValue(key)
                        .WithStartDate(utcNow)
                        .WithDuration(duration)
                        .Attach()
                    .ApplyAsync();

                _log.Info($"Added new key with name '{availableKeyName}' to application with id '{application.Id}' that is valid from UTC '{utcNow}' with a duraction of '{keyDurationInMinutes}' minutes");
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    _log.Error($"Forbidden to set key for active directory application with id '{application.Id}'");
                    _log.Verbose($"Extra info for application with id '{application.Id}': '{ex.Response.Content}'.");
                }
                else
                {
                    _log.Error(ex.Response.Content);
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
            _log.Verbose("Generate a new secret");

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

        }
    }
}
