Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$resourceGroupName = Get-VstsInput -Name resourceGroupName -Require
$location = Get-VstsInput -Name location -Require
$keyVaultName = Get-VstsInput -Name keyVaultName -Require
$schedule = Get-VstsInput -Name schedule -Require
$defaultKeyName = Get-VstsInput -Name defaultKeyName -Require
$keyDurationInMinutes = Get-VstsInput -Name keyDurationInMinutes -Require -AsInt
$createApplicationInsights = Get-VstsInput -Name createApplicationInsights -AsBool

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


    # Get tenantid out of the AzureRM connection
    $serviceName = Get-VstsInput -Name ConnectedServiceNameARM -Require
    $endpoint = Get-VstsEndpoint -Name $serviceName -Require
    $tenantId = $endpoint.Auth.Parameters.TenantId

    Write-Verbose "Input variables are: "
    Write-Verbose "resourceGroupName: $resourceGroupName"
    Write-Verbose "keyVaultName: $keyVaultName"
    Write-Verbose "location: $location"
    Write-Verbose "schedule: $schedule"
    Write-Verbose "defaultKeyName: $defaultKeyName"
    Write-Verbose "keyDurationInMinutes: $keyDurationInMinutes"
    Write-Verbose "createApplicationInsights: $createApplicationInsights"
    Write-Verbose "tenantId: $tenantId"

    Import-Module $PSScriptRoot\scripts\Set-AzureAdApplicationKeyRotator.psm1

    Set-AzureAdApplicationKeyRotator `
        -ResourceGroupName $resourceGroupName `
        -KeyVaultName $keyVaultName `
        -Location $location `
        -Schedule $schedule `
        -DefaultKeyName $DefaultKeyName `
        -KeyDurationInMinutes $KeyDurationInMinutes `
        -CreateApplicationInsights $createApplicationInsights `
        -TenantId $tenantId `
        -InformationAction Continue   
}
finally {
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -ErrorAction SilentlyContinue

    Trace-VstsLeavingInvocation $MyInvocation
}
