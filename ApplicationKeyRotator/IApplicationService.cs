using System.Threading.Tasks;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public interface IApplicationService
    {
        ILogger Log { get; set; }

        Task<IActiveDirectoryApplication> GetApplication(IAzure azure, string id);
    }
}