using Microsoft.Azure.Management.Fluent;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace ApplicationKeyRotator.Authentication
{
    public interface IAuthenticationHelper
    {
        ILogger Log { get; set; }

        Task<Azure.IAuthenticated> GetAzureConnection();
    }
}