Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$resourceGroupName = Get-VstsInput -Name resourceGroupName -Require
$location = Get-VstsInput -Name location -Require
$keyVaultName = Get-VstsInput -Name keyVaultName -Require
$createApplicationInsights = Get-VstsInput -Name createApplicationInsights -AsBool

# Initialize Azure Connection
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers\VstsAzureHelpers.psm1
Initialize-PackageProvider
Initialize-Module -Name "AzureRM.Resources" -RequiredVersion "6.7.0"
Initialize-AzureRM

Write-Verbose "Input variables are: "
Write-Verbose "resourceGroupName: $resourceGroupName"
Write-Verbose "keyVaultName: $keyVaultName"
Write-Verbose "location: $location"
Write-Verbose "createApplicationInsights: $createApplicationInsights"

Import-Module $PSScriptRoot\scripts\Set-AadApplicationKeyRotator.psm1

Set-AadApplicationKeyRotator `
    -ResourceGroupName $resourceGroupName `
    -KeyVaultName $keyVaultName `
    -Location $location `
    -CreateApplicationInsights $createApplicationInsights

Trace-VstsLeavingInvocation $MyInvocation