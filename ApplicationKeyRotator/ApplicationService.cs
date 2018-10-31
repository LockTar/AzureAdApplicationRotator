using System.Net;
using System.Threading.Tasks;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent.Models;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public class ApplicationService : IApplicationService
    {
        public ILogger Log { get; set; }

        public async Task<IActiveDirectoryApplication> GetApplication(IAzure azure, string id)
        {
            Log.LogDebug($"Searching for active directory application resource id '{id}'");

            try
            {
                ////string name = "test";
                ////var application = azure.AccessManagement.ActiveDirectoryApplications
                ////.Define(name)
                ////    .WithSignOnUrl("https://github.com/Azure/azure-sdk-for-java/" + name)
                ////    // password credentials definition
                ////    .DefinePasswordCredential("password")
                ////        .WithPasswordValue("P@ssw0rd")
                ////        .WithDuration(TimeSpan.FromDays(700))
                ////        .Attach()
                ////    .Create();

                var application = await azure.AccessManagement.ActiveDirectoryApplications.GetByIdAsync(id);

                if (application == null)
                {
                    Log.LogInformation($"No active directory application found by id '{id}'");
                }
                else
                {
                    Log.LogInformation($"Found active directory application '{application.Name}' by id '{application.Id}' and applicationId '{application.ApplicationId}'");
                }

                return application;
            }
            catch (GraphErrorException ex)
            {
                if (ex.Response.StatusCode == HttpStatusCode.Forbidden)
                {
                    Log.LogError($"Forbidden to get active directory application with id '{id}'");
                }
                else if (ex.Response.StatusCode == HttpStatusCode.NotFound)
                {
                    Log.LogError($"Can't find active directory application with id '{id}'");
                }
                else
                {
                    Log.LogError(ex.Response.Content);
                }

                return null;
            }
        }
    }
}
