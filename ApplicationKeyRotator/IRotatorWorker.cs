using System.Threading.Tasks;
using Microsoft.Azure.Management.Graph.RBAC.Fluent;
using Microsoft.Extensions.Logging;

namespace ApplicationKeyRotator
{
    public interface IRotatorWorker
    {
        ILogger Log { get; set; }

        Task RotateAll();

        Task Rotate(IActiveDirectoryApplication application, string keyName = "RotatedKey");
    }
}