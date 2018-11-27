Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$method = Get-VstsInput -Name method
$objectId = Get-VstsInput -Name objectId
$applicationId = Get-VstsInput -Name applicationId

# Initialize Azure Connection
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers\VstsAzureHelpers.psm1
Initialize-PackageProvider
Initialize-Module -Name "AzureRM.Resources" -RequiredVersion "6.7.0"
Initialize-AzureRM

Write-Verbose "Input variables are: "
Write-Verbose "method: $method"
Write-Verbose "objectId: $objectId"
Write-Verbose "applicationId: $applicationId"

Import-Module $PSScriptRoot\scripts\Remove-AadApplication.psm1

Remove-AadApplication -ObjectId $objectId -ApplicationId $applicationId