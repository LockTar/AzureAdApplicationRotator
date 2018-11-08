using System.Threading.Tasks;
using ApplicationKeyRotator.Applications;
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
            [Inject] IRotatorWorker worker)
        {
            worker.Log = log;

            await worker.RotateAll();

            return new OkResult();
        }

        [FunctionName("ByApplicationObjectId")]
        public static async Task<IActionResult> RunByApplicationObjectId([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]HttpRequest req, ILogger log, 
            [Inject] IRotatorWorker worker, 
            [Inject] IApplicationService applicationService)
        {
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
                        
            var application = await applicationService.GetApplication(id);

            if (application == null)
            {
                return new NotFoundResult();
            }

            await worker.Rotate(application);

            return new OkResult();
        }
    }
}
