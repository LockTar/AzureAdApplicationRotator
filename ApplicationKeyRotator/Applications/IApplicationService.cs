using System.Threading.Tasks;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public interface IApplicationService
    {
        ILogger Log { get; set; }

        Task<IActiveDirectoryApplication> GetApplication(string id);

        Task AddSecretToActiveDirectoryApplication(IActiveDirectoryApplication application, string keyName, string key);

        Task RemoveExpiredKeys(IActiveDirectoryApplication application);
    }
}