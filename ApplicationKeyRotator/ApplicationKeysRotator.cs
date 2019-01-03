using System;
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
        public static async Task RunAllApplicationIds([TimerTrigger("%ScheduleAppSetting%")]TimerInfo myTimer, ILogger log,
            [Inject] IRotatorWorker worker)
        {
            worker.Log = log;

            await worker.RotateAll();
        }

        [FunctionName("ByApplicationObjectId")]
        public static async Task<IActionResult> RunByApplicationObjectId([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]HttpRequest req, ILogger log,
            [Inject] IRotatorWorker worker,
            [Inject] IApplicationService applicationService)
        {
            worker.Log = log;
            applicationService.Log = log;
            
            string id = req.Query["id"];
            string keyName = req.Query["keyName"];
            string keyDurationQuerystring = req.Query["keyDuration"];

            if (string.IsNullOrWhiteSpace(id))
            {
                const string idMessage = "No id parameter found in querystring";
                log.LogError(idMessage);
                return new BadRequestObjectResult(idMessage);
            }

            int keyDuration = default(int);
            if (!string.IsNullOrWhiteSpace(keyDurationQuerystring) && 
                !int.TryParse(keyDurationQuerystring, out keyDuration))
            {
                const string idMessage = "Keyduration parameter found in querystring is not valid. Please enter valid keyduration in minutes.";
                log.LogError(idMessage);
                return new BadRequestObjectResult(idMessage);
            }
            
            string message = $"Found id '{id}' in querystring to rotate";

            if (!string.IsNullOrWhiteSpace(keyName))
            {
                message += $", with custom keyname '{keyName}'";
            }

            if (keyDuration > 0)
            {
                message += $" and with custom keyduration '{keyDuration}'";
            }

            log.LogInformation(message);

            var application = await applicationService.GetApplication(id);

            if (application == null)
            {
                return new NotFoundResult();
            }

            await worker.Rotate(application, keyName, keyDuration);

            return new OkResult();
        }
    }
}
