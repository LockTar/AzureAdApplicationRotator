# function Initialize-AzureSubscriptionRM {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory=$true)]
#         $Endpoint)

#     #Set UserAgent for Azure Calls
#     Set-UserAgent

#     Write-Verbose 'Get all values from the endpoint'
#     $clientId = $Endpoint.Auth.Parameters.ServicePrincipalId
#     $clientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey
#     $tenantId = $Endpoint.Auth.Parameters.TenantId
#     $environmentName = "AzureCloud"
#     $subscriptionId = $Endpoint.Data.SubscriptionId

#     $psCredential = New-Object System.Management.Automation.PSCredential(
#         $clientId,
#         (ConvertTo-SecureString $clientSecret -AsPlainText -Force))

#     Write-Verbose "##[command] Connect-AzureRMAccount -ServicePrincipal -Tenant $tenantId -Credential $psCredential -Environment $environmentName"
#     $null = Connect-AzureRMAccount -ServicePrincipal -Tenant $tenantId -Credential $psCredential -Environment $environmentName
    
#     Write-Verbose "##[command] Set-AzureRmContext -SubscriptionId $subscriptionId -Tenant $tenantId"
#     $null = Set-AzureRmContext -SubscriptionId $subscriptionId -Tenant $tenantId
# }

function Initialize-AzureSubscriptionAD {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $Endpoint)

    #Set UserAgent for Azure Calls
    Set-UserAgent

    Write-Verbose 'Get all values from the endpoint'
    $clientId = $Endpoint.Auth.Parameters.ServicePrincipalId
    $clientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey
    $tenantId = $Endpoint.Auth.Parameters.TenantId
    
    $adTokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
    $resource = "https://graph.windows.net/"

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $clientId
        client_secret = $clientSecret
        resource      = $resource
    }

    $response = Invoke-RestMethod -Method 'Post' -Uri $adTokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
    $token = $response.access_token
    Write-VstsSetSecret -Value $token

    Write-Verbose "##[command] Connect-AzureAD -AadAccessToken $token -AccountId $clientId -TenantId $tenantId"
    $null = Connect-AzureAD -AadAccessToken $token -AccountId $clientId -TenantId $tenantId
}

function Set-UserAgent {
    [CmdletBinding()]
    param()

	$userAgent = Get-VstsTaskVariable -Name AZURE_HTTP_USER_AGENT
    if ($userAgent) {
        Set-UserAgent_Core -UserAgent $userAgent
    }
}

function Set-UserAgent_Core {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserAgent)

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent($UserAgent)
    } catch {
        Write-Verbose "Set-UserAgent failed with exception message: $_.Exception.Message"
    } finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

# function Set-AzureRmVersionOnDiskInModulePath {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [string]$Name,
#         [Parameter(Mandatory = $true)]
#         [string]$RequiredVersion
#     )

#     Trace-VstsEnteringInvocation $MyInvocation
#     try {
#         # Check if AzureRM module is locally available via an already downloaded version on the system drive (hosted microsoft agents)
#         $targetAzureRmVersion = Get-AzureRMVersion -AzureRMModuleName $Name -RequiredVersion $RequiredVersion
#         $installedAzureRmVersions = "2.1.0","3.8.0","4.2.1","5.1.1","6.7.0"
#         $hostedAgentAzureRMDownloadPath = ('c:\Modules\AzureRM_{0}' -f $targetAzureRmVersion)
           
#         if ($installedAzureRmVersions.Contains($targetAzureRmVersion) -and (Test-Path -Path $hostedAgentAzureRMDownloadPath)) {
#             Write-Verbose -Message ('Module {0} with Version {1} is locally available in AzureRM version {2}' -f $Name, $RequiredVersion, $targetAzureRmVersion)
#             Write-Verbose "Add local AzureRM PowerShell modules path '$hostedAgentAzureRMDownloadPath' to the PSModulePath Environment variable"
#             $modulePath = $hostedAgentAzureRMDownloadPath
#             if (!$env:PSModulePath.Contains($modulePath)) {
#                 $env:PSModulePath = $modulePath + ';' + $env:PSModulePath
#             }

#             Write-Verbose "Check if Module with correct version $RequiredVersion is available on system"
#             $module = Get-Module -Name $Name -ListAvailable | Where-Object {$_.Version -eq $RequiredVersion -and $_.Name -eq $Name}
#             if (!($module)) {
#                 Write-Error -Message ('Module {0} with Version {1} is NOT locally available' -f $Name, $RequiredVersion)
#             }
#             else {
#                 # List all the locations where the Module version is located.
#                 $module | ForEach-Object {
#                     Write-Verbose -Message ('Module {0} with Version {1} is locally available in folder {2}' -f $Name, $RequiredVersion, $_.ModuleBase)
#                 }
#             }

#             return $true
#         }
#         else {
#             Write-Verbose -Message ('Module {0} with version {1} is not locally available on disk' -f $Name, $RequiredVersion)
#             return $false
#         }
#     } catch {
#         Write-Verbose "Set-UserAgent failed with exception message: $_.Exception.Message"
#     } finally {
#         Trace-VstsLeavingInvocation $MyInvocation
#     }
# }

# <#
# .Synopsis
#    Retrieve AzureRM PowerShell version containing AzureRM Powershell module.
# .DESCRIPTION
#    Retrieve AzureRM PowerShell version containing AzureRM Powershell module with required version from PowerShell Gallery.
# .EXAMPLE
#    Get-AzureRMVersion -AzureRMModuleName 'AzureRM.ApplicationInsights' -RequiredVersion '0.1.8'
#    6.11.0
# .INPUTS
#    AzureRMModuleName. AzureRM PowerShell Module Name.
# .INPUTS
#    RequiredVersion. AzureRM PowerShell Module Version.
# .OUTPUTS
#    AzureRM (Meta) PowerShell Module Version.
# #>
# function Get-AzureRMVersion {
#     [CmdletBinding()]
#     [OutputType([string])]
#     Param
#     (
#         [Parameter(Mandatory = $true,
#             ValueFromPipelineByPropertyName = $true,
#             Position = 0)]
#         [string]$AzureRMModuleName,

#         [Parameter(Mandatory = $true,
#             ValueFromPipelineByPropertyName = $true,
#             Position = 1)]
#         [string]
#         $RequiredVersion
#     )

#     #region check AzureRm PowerShell module version for specific Module.
#     Write-Verbose -Message ('Retrieve all AzureRM module versions from PSGallery')
#     $AllAzureRMModules = Find-Module -Name AzureRM -AllVersions
#     Write-Verbose -Message ('{0} AzureRM Module versions retrieve from the PSGallery' -f $AllAzureRMModules.count)
#     #endregion

#     #region get AzureRM PowerShell module version container the specified AzureRM.[name] Module version
#     Write-Verbose -Message ('Find Module {0} with version {1} in AzureRM Module versions' -f $($AzureRMModuleName), $($RequiredVersion))
#     foreach ($AzureRMModule in $AllAzureRMModules) {
#         Write-Verbose -Message ('Checking AzureRM Module version {0} for Module {1} with version {2}' -f $($AzureRMModule.Version), $($AzureRMModuleName), $($RequiredVersion))
#         if ($AzureRMModule.dependencies | Where-Object {($_.Name -eq $($AzureRMModuleName) -and $_.RequiredVersion -eq $RequiredVersion) }) {
#             $AzureRMModuleVersion = $AzureRMModule.Version
#             Write-Verbose -Message ('Found Module {0} with version {1} in AzureRM version {2}' -f $($AzureRMModuleName), $($RequiredVersion), $($AzureRMModule.Version))
#             return $AzureRMModuleVersion
#         }
#     }
#     if (!($AzureRMModuleVersion)) {
#         Write-Error -Message ('No AzureRM Module version found which contains Module {0} with version {1}' -f $($AzureRMModuleName), $($RequiredVersion))
#     }
#     #endregion
# }