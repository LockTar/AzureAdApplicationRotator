Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$resourceGroupName = Get-VstsInput -Name resourceGroupName -Require
$location = Get-VstsInput -Name location -Require
$keyVaultName = Get-VstsInput -Name keyVaultName -Require
$schedule = Get-VstsInput -Name schedule -Require
$defaultKeyName = Get-VstsInput -Name defaultKeyName -Require
$keyDurationInMinutes = Get-VstsInput -Name keyDurationInMinutes -Require -AsInt
$createApplicationInsights = Get-VstsInput -Name createApplicationInsights -AsBool

# Initialize Azure Connection
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers\VstsAzureHelpers.psm1
Initialize-PackageProvider
Initialize-Module -Name "AzureRM.Resources" -RequiredVersion "6.7.0"
Initialize-AzureRM

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

Trace-VstsLeavingInvocation $MyInvocation