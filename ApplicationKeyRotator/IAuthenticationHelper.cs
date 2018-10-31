using Microsoft.Azure.Management.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public interface IAuthenticationHelper
    {
        ILogger Log { get; set; }

        IAzure GetAzureConnection();
    }
}