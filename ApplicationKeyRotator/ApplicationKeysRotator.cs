using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Willezone.Azure.WebJobs.Extensions.DependencyInjection;

namespace ApplicationKeyRotator
{
    public static class ApplicationKeysRotator
    {
        [FunctionName("AllApplicationIds")]
        public static async Task<IActionResult> RunAllApplicationIds([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]HttpRequest req, ILogger log, 
            [Inject] IAuthenticationHelper authenticationHelper, 
            [Inject] IKeyVaultHelper keyVaultHelper, 
            [Inject] IRotatorWorker worker)
        {
            authenticationHelper.Log = log;
            worker.Log = log;

            await worker.RotateAll();

            return new OkResult();
        }

        [FunctionName("ByApplicationObjectId")]
        public static async Task<IActionResult> RunByApplicationObjectId([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]HttpRequest req, ILogger log, 
            [Inject] IAuthenticationHelper authenticationHelper, 
            [Inject] IKeyVaultHelper keyVaultHelper, 
            [Inject] IRotatorWorker worker, 
            [Inject] IApplicationService applicationService)
        {
            authenticationHelper.Log = log;
            worker.Log = log;
            applicationService.Log = log;

            string id = req.Query["id"];

            if (string.IsNullOrWhiteSpace(id))
            {
                const string message = "No id parameter found in querystring";
                log.LogDebug(message);
                return new BadRequestObjectResult(message);
            }
            else
            {
                log.LogInformation($"Found id '{id}' in querystring to rotate");
            }

            var azure = authenticationHelper.GetAzureConnection();
            var application = await applicationService.GetApplication(azure, id);

            if (application == null)
            {
                return new NotFoundResult();
            }

            const string keyName = "RotatedKey";
            await worker.Rotate(application, keyName);

            return new OkResult();
        }
    }
}
