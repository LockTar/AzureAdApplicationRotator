Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$resourceGroupName = Get-VstsInput -Name resourceGroupName
$keyVaultName = Get-VstsInput -Name keyVaultName -Require
$applicationInsightsName = Get-VstsInput -Name applicationInsightsName -Require

# Initialize Azure Connection
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers\VstsAzureHelpers.psm1
Initialize-PackageProvider
Initialize-Module -Name "AzureRM.Resources" -RequiredVersion "6.7.0"
Initialize-AzureRM

Write-Verbose "Input variables are: "
Write-Verbose "resourceGroupName: $resourceGroupName"
Write-Verbose "keyVaultName: $keyVaultName"
Write-Verbose "applicationInsightsName: $applicationInsightsName"

Import-Module $PSScriptRoot\scripts\Set-AadApplicationKeyRotator.psm1

Set-AadApplicationKeyRotator `
    -ResourceGroupName $resourceGroupName `
    -KeyVaultName $keyVaultName `
    -ApplicationInsightsName $applicationInsightsName

Trace-VstsLeavingInvocation $MyInvocation