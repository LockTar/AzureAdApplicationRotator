$oldverbose = $VerbosePreference
$VerbosePreference = "continue"
$oldinformation = $InformationPreference
$InformationPreference = "continue"

$applicationName = "AppKeyRotator"
$environment = "Test"
$location = "westeurope";

$resourceGroupName = "$applicationName-$environment"
$keyVaultName = $applicationName + $environment
$appServicePlanName = $applicationName + "Plan"
$functionAppName = $applicationName + $environment
$storageAccountName = $($applicationName + $environment).ToLowerInvariant()
$applicationInsightsName = $applicationName + $environment

$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

if (!$resourceGroup) {
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}


# KeyVault
$keyVaultTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\KeyVault.json"
$keyVaultDeploymentName = ((Get-ChildItem $keyVaultTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\New-KeyVault.ps1 `
    -ResourceGroupName $resourceGroupName `
    -KeyVaultName $keyVaultName `
    -Location $location `
    -TemplateFile $keyVaultTemplateFile `
    -DeploymentName $keyVaultDeploymentName


# App Service Plan
$aspTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\AppServicePlan.json"
$aspDeploymentName = ((Get-ChildItem $aspTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\New-AppServicePlan.ps1 `
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

.\New-ApplicationInsights.ps1 `
    -ResourceGroupName $resourceGroupName `
    -ApplicationInsightsName $applicationInsightsName `
    -Location $location `
    -TemplateFile $applicationInsightsTemplateFile `
    -DeploymentName $applicationInsightsDeploymentName


# Storage Account
$storageAccountTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\StorageAccount.json"
$storageAccountDeploymentName = ((Get-ChildItem $storageAccountTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\New-StorageAccount.ps1 `
    -ResourceGroupName $resourceGroupName `
    -StorageAccountName $storageAccountName `
    -Location $location `
    -AccountType "Standard_LRS" `
    -AccessTier "Cool" `
    -TemplateFile $storageAccountTemplateFile `
    -DeploymentName $storageAccountDeploymentName


# Function App
$functionAppTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\FunctionApp.json"
$functionAppDeploymentName = ((Get-ChildItem $functionAppTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

.\New-FunctionApp.ps1 `
    -ResourceGroupName $resourceGroupName `
    -FunctionAppName $functionAppName `
    -Location $location `
    -StorageAccountName $storageAccountName `
    -AppServicePlanName $appServicePlanName `
    -ApplicationInsightsName $applicationInsightsName `
    -TemplateFile $functionAppTemplateFile `
    -DeploymentName $functionAppDeploymentName

# Sleep because function app is slow to start up
Start-Sleep 30

# Get ARM output variables
Write-Information "Retrieve Function App MSI SP from ARM output"
$functionAppSpId = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $functionAppDeploymentName).Outputs.functionAppSpId.value
Write-Verbose "functionAppSpId: $functionAppSpId"

Write-Information "Retrieve Function App name ARM output"
$functionAppName = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $functionAppDeploymentName).Outputs.functionAppName.value
Write-Verbose "functionAppName: $functionAppName"

# Publish Azure AD Application Key Rotator from the artifacts folder
Write-Information "Publish the Application Key Rotator to the Function App"
$zipFilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, ".\..\..\Artifacts\ApplicationKeyRotator.zip"))
.\Publish-AppService.ps1 `
    -ResourceGroupName $resourceGroupName `
    -ZipFilePath $zipFilePath `
    -AppServiceName $functionAppName


# Check role assignments for Function App Servic Principal Id and set as contributor on the Resource Group
#$role = "Contributor"
#Write-Verbose "Check role assignment $role on $functionAppSpId"
#$assignment = Get-AzureRmRoleAssignment `
#    -ObjectId $functionAppSpId `
#    -ResourceGroupName $resourceGroupName `
#    -RoleDefinitionName $role `
#    -Verbose
#
#if (!$assignment) {
#    Write-Information "Create role assignment $role on $functionAppSpId"
#    $assignment = New-AzureRmRoleAssignment `
#        -ObjectId $functionAppSpId `
#        -ResourceGroupName $resourceGroupName `
#        -RoleDefinitionName $role `
#        -Verbose
#}

# KeyVault Access Policy
Write-Information "Set access policy for Function App Service Principal Id"
Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $keyVaultName `
    -ObjectId $functionAppSpId `
    -PermissionsToSecrets Get,Set

Write-Information "Set access policy for current user to set test secret"
Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $keyVaultName `
    -ObjectId $(Get-AzureRmADUser -UserPrincipalName $(Get-AzureRmContext).Account.Id).Id `
    -PermissionsToSecrets Get,Set

# Add a test secret
Write-Information "Add a test secret so we can test the rotation"
$tags = @{ApplicationObjectId="83d86c42-6567-49e0-ab8c-e40848205883"}
$secretValue = ConvertTo-SecureString -String 'Bar' -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name 'Foo' -SecretValue $secretValue -Tag $tags


$VerbosePreference = $oldverbose
$InformationPreference = $oldinformation