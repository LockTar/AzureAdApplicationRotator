Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$resourceGroupName = Get-VstsInput -Name resourceGroupName -Require
$location = Get-VstsInput -Name location -Require
$keyVaultName = Get-VstsInput -Name keyVaultName -Require

# Initialize Azure Connection
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers\VstsAzureHelpers.psm1
Initialize-PackageProvider
Initialize-Module -Name "AzureRM.Resources" -RequiredVersion "6.7.0"
Initialize-AzureRM

Write-Verbose "Input variables are: "
Write-Verbose "resourceGroupName: $resourceGroupName"
Write-Verbose "keyVaultName: $keyVaultName"
Write-Verbose "location: $location"

Import-Module $PSScriptRoot\scripts\Remove-AzureAdApplicationKeyRotator.psm1

Remove-AzureAdApplicationKeyRotator `
    -ResourceGroupName $resourceGroupName `
    -KeyVaultName $keyVaultName `
    -Location $location

Trace-VstsLeavingInvocation $MyInvocation