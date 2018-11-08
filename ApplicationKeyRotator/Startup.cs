using ApplicationKeyRotator;
using ApplicationKeyRotator.Applications;
using ApplicationKeyRotator.Authentication;
using ApplicationKeyRotator.KeyVaults;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Willezone.Azure.WebJobs.Extensions.DependencyInjection;

[assembly: WebJobsStartup(typeof(Startup))]
namespace ApplicationKeyRotator
{
    internal class Startup : IWebJobsStartup
    {
        public void Configure(IWebJobsBuilder builder) =>
            builder.AddDependencyInjection(ConfigureServices);

        private void ConfigureServices(IServiceCollection services)
        {
            services.AddScoped<IAuthenticationHelper, AuthenticationHelper>();
            services.AddScoped<IKeyVaultHelper, KeyVaultHelper>();

            services.AddScoped<IKeyVaultService, KeyVaultService>();
            services.AddScoped<IApplicationService, ApplicationService>();

            services.AddScoped<IRotatorWorker, RotatorWorker>();
        }
    }
}
