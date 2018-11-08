using Microsoft.Azure.Management.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator.Authentication
{
    public interface IAuthenticationHelper
    {
        ILogger Log { get; set; }

        IAzure GetAzureConnection();
    }
}