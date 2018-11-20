using System.Threading.Tasks;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator.Applications
{
    public interface IApplicationService
    {
        ILogger Log { get; set; }

        Task<IActiveDirectoryApplication> GetApplication(string id);

        Task AddSecretToActiveDirectoryApplication(IActiveDirectoryApplication application, string keyName, string key, int keyDurationInMinutes);

        Task RemoveExpiredKeys(IActiveDirectoryApplication application);
    }
}