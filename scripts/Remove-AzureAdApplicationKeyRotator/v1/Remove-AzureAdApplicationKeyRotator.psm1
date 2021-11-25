# Private module-scope variables.
$script:azureModule = $null
$script:azureRMProfileModule = $null

function Remove-AzureAdApplicationKeyRotator {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory)]
        [string]$Location,
        [Parameter(Mandatory)]
        [string]$KeyVaultName
    )

    $applicationName = "AppKeyRotator"

    $functionAppName = "$KeyVaultName-$applicationName"
    $appServicePlanName = $functionAppName + "Plan"
    $storageAccountName = $($KeyVaultName).ToLowerInvariant().Replace('-', '') + "sa"
    $applicationInsightsName = $functionAppName + "ai"

    #Resource Group
    Write-Debug "Check if Resource Group '$ResourceGroupName' exist"
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue

    if (!$resourceGroup) {
        Write-Error "Resource Group with the name '$ResourceGroupName' doesn't exist."
    }

    #KeyVault
    Write-Debug "Check if Key Vault '$KeyVaultName' exist"
    $keyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$keyVault) {
        Write-Error "Key Vault '$KeyVaultName' doesn't exist."
    }

    #Application Insights
    Write-Debug "Check if Application Insights '$applicationInsightsName' exist"
    $applicationInsights = Get-AzApplicationInsights -Name $applicationInsightsName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
    if ($applicationInsights) {
        Write-Information "Application Insights '$applicationInsightsName' exists so remove it"
        Remove-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $applicationInsightsName
    }
    else {
        Write-Information "Application Insights '$applicationInsightsName' doesn't exist so do nothing"
    }

    # Function App
    Write-Debug "Check if Function App '$functionAppName' exist"
    $functionApp = Get-AzWebApp -Name $functionAppName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            
    if ($functionApp) {
        Write-Information "Function App '$functionAppName' exists so remove it"
        Remove-AzWebApp -ResourceGroupName $ResourceGroupName -Name $functionAppName -Force
    }
    else {
        Write-Information "Function App '$functionAppName' doesn't exist so do nothing"
    }

    # App Service Plan
    Write-Debug "Check if App Service Plan '$appServicePlanName' exist"
    $appServicePlan = Get-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
    if ($appServicePlan) {
        Write-Information "App Service Plan '$appServicePlanName' exists so remove it"
        Remove-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $appServicePlanName -Force
    }
    else {
        Write-Information "App Service Plan '$appServicePlanName' doesn't exist so do nothing"
    }

    # Storage Account
    Write-Debug "Check if Storage Account '$storageAccountName' exist"
    $storageAccount = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
    if ($storageAccount) {
        Write-Information "Storage Account '$storageAccountName' exists so remove it"
        Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -Force
    }
    else {
        Write-Information "Storage Account '$storageAccountName' doesn't exist so do nothing"
    }
}

Export-ModuleMember -Function Remove-AzureAdApplicationKeyRotator
