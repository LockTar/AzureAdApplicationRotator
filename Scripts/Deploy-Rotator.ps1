$applicationName = "ApplicationRotator"
$environment = "Test"
$location = "westeurope";

$resourceGroupName = "$applicationName-$environment"
$appServicePlanName = $applicationName + "Plan"
$functionAppName = $applicationName + $environment
$storageAccountName = $($applicationName + $environment).ToLowerInvariant()
$applicationInsightsName = $applicationName + $environment

$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

if (!$resourceGroup) {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

# App Service Plan
$aspTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\AppServicePlan.json"
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
$applicationInsightsTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\ApplicationInsights.json"
$applicationInsightsDeploymentName = ((Get-ChildItem $applicationInsightsTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\Create-ApplicationInsights.ps1 `
    -ResourceGroupName $resourceGroupName `
    -ApplicationInsightsName $applicationInsightsName `
    -Location $location `
    -TemplateFile $applicationInsightsTemplateFile `
    -DeploymentName $applicationInsightsDeploymentName


# Storage Account
$storageAccountTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\StorageAccount.json"
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
$functionTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\FunctionApp.json"
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


# Deploy the Azure AD Application Key Rotator
# Get ARM output variables
Write-Information "Retrieve Function App MSI SP from ARM output"
$functionAppSpId = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentNameFunctionApp).Outputs.functionAppSpId.value
Write-Verbose "functionAppSpId: $functionAppSpId"

Write-Information "Retrieve Function App name ARM output"
$functionAppName = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentNameFunctionApp).Outputs.functionAppName.value
Write-Verbose "functionAppName: $functionAppName"

# Publish
Write-Information "Publish the Application Key Rotator to the Function App"
$zipFilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "Artifacts\ApplicationKeyRotator.zip"))
.\Publish-AppService.ps1 `
    -ResourceGroupName $resourceGroupName `
    -ZipFilePath $zipFilePath `
    -AppServiceName $functionAppName


# Check role assignments for Function App Servic Principal Id and set as contributor on the Resource Group
$role = "Contributor"
Write-Verbose "Check role assignment $role on $functionAppSpId"
$assignment = Get-AzureRmRoleAssignment `
    -ObjectId $functionAppSpId `
    -ResourceGroupName $resourceGroupName `
    -RoleDefinitionName $role `
    -Verbose

if (!$assignment) {
    Write-Information "Create role assignment $role on $functionAppSpId"
    $assignment = New-AzureRmRoleAssignment `
        -ObjectId $functionAppSpId `
        -ResourceGroupName $resourceGroupName `
        -RoleDefinitionName $role `
        -Verbose
}