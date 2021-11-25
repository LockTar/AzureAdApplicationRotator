Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$resourceGroupName = Get-VstsInput -Name resourceGroupName -Require
$location = Get-VstsInput -Name location -Require
$keyVaultName = Get-VstsInput -Name keyVaultName -Require


# Cleanup hosted agent with AzureRM modules
. "$PSScriptRoot\Utility.ps1"
CleanUp-PSModulePathForHostedAgent

# Initialize Azure helpers
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Import-Module $PSScriptRoot\ps_modules\CustomAzureDevOpsAzureHelpers\CustomAzureDevOpsAzureHelpers.psm1

try 
{
    # Login
    Initialize-PackageProvider
    Initialize-Module -Name "Az.Accounts" -RequiredVersion "2.6.0"
    Initialize-Module -Name "Az.Resources" -RequiredVersion "4.4.0"

    $connectedServiceName = Get-VstsInput -Name ConnectedServiceNameARM -Require
    $endpoint = Get-VstsEndpoint -Name $connectedServiceName -Require
    Initialize-AzModule -Endpoint $endpoint

    Write-Verbose "Input variables are: "
    Write-Verbose "resourceGroupName: $resourceGroupName"
    Write-Verbose "keyVaultName: $keyVaultName"
    Write-Verbose "location: $location"

    Import-Module $PSScriptRoot\scripts\Remove-AzureAdApplicationKeyRotator.psm1

    Remove-AzureAdApplicationKeyRotator `
        -ResourceGroupName $resourceGroupName `
        -KeyVaultName $keyVaultName `
        -Location $location `
        -InformationAction Continue
}
finally {
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -ErrorAction SilentlyContinue
}
