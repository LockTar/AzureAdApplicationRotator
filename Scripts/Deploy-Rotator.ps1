$applicationName = "ApplicationRotator"
$environment = "Test"
$location = "westeurope";

$resourceGroupName = "$applicationName-$environment"
$appServicePlanName = $applicationName + "Plan"
$functionAppName = $applicationName + $environment
$storageAccountName = $($applicationName + $environment).ToLowerInvariant()
$applicationInsightsName = $applicationName + $environment

$rg = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

if (!$rg) {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

# App Service Plan
$aspTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\AppServicePlan.json"
$aspDeploymentName = ((Get-ChildItem $aspTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\Create-AppServicePlan.ps1 `
    -ResourceGroupName $resourceGroupName `
    -AppServicePlanName $appServicePlanName `
    -Location $location `
    -Family "Y" `
    -PricingTier "1" `
    -Instances "0" `
    -TemplateFile $aspTemplateFile `
    -DeploymentName $aspDeploymentName


#Application Insights
$applicationInsightsTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ApplicationInsights.json"
$applicationInsightsDeploymentName = ((Get-ChildItem $applicationInsightsTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\Create-ApplicationInsights.ps1 `
    -ResourceGroupName $resourceGroupName `
    -ApplicationInsightsName $applicationInsightsName `
    -Location $location `
    -TemplateFile $applicationInsightsTemplateFile `
    -DeploymentName $applicationInsightsDeploymentName


# Storage Account
$storageAccountTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\StorageAccount.json"
$storageAccountDeploymentName = ((Get-ChildItem $storageAccountTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\Create-StorageAccount.ps1 `
    -ResourceGroupName $resourceGroupName `
    -StorageAccountName $storageAccountName `
    -Location $location `
    -AccountType "Standard_LRS" `
    -AccessTier "Cool" `
    -TemplateFile $storageAccountTemplateFile `
    -DeploymentName $storageAccountDeploymentName


# Function App
$functionTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\FunctionApp.json"
$functionDeploymentName = ((Get-ChildItem $functionTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\Create-FunctionApp.ps1 `
    -ResourceGroupName $resourceGroupName `
    -FunctionAppName $functionAppName `
    -Location $location `
    -StorageAccountName $storageAccountName `
    -AppServicePlanName $appServicePlanName `
    -ApplicationInsightsName $applicationInsightsName `
    -TemplateFile $functionTemplateFile `
    -DeploymentName $functionDeploymentName

