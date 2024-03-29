# # Private module-scope variables.
# $script:azureModule = $null
# $script:azureRMProfileModule = $null

function Set-AzureAdApplicationKeyRotator {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$KeyVaultName,
        [Parameter(Mandatory=$true)]
        [string]$Schedule,
        [Parameter(Mandatory=$true)]
        [string]$DefaultKeyName,
        [Parameter(Mandatory=$true)]
        [int]$KeyDurationInMinutes,
        [bool]$CreateApplicationInsights,
        [Parameter(Mandatory=$true)]
        [string]$TenantId
    )

    # Dot source the private functions.
    . $PSScriptRoot/New-ApplicationInsights.ps1
    . $PSScriptRoot/New-AppServicePlan.ps1
    . $PSScriptRoot/New-FunctionApp.ps1
    . $PSScriptRoot/New-StorageAccount.ps1
    . $PSScriptRoot/Publish-AppService.ps1

    $applicationName = "AppKeyRotator"

    $functionAppName = "$KeyVaultName-$applicationName"
    $appServicePlanName = $functionAppName + "Plan"
    $storageAccountName = $($KeyVaultName).ToLowerInvariant().Replace('-', '') + "sa"
    $applicationInsightsName = $functionAppName + "ai"

    #Resource Group
    Write-Verbose "Check if Resource Group '$ResourceGroupName' already exist"
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue

    if (!$resourceGroup) {
        Write-Error "Resource Group with the name '$ResourceGroupName' doesn't exist. First create a Resource Group"
    }

    #KeyVault
    Write-Verbose "Check if Key Vault '$KeyVaultName' already exist"
    $keyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$keyVault) {
        Write-Error "Key Vault '$KeyVaultName' doesn't exist. First create a Key Vault."
    }

    # App Service Plan
    $aspTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\AppServicePlan.json"
    $aspDeploymentName = ((Get-ChildItem $aspTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

    New-AppServicePlan `
        -ResourceGroupName $ResourceGroupName `
        -AppServicePlanName $appServicePlanName `
        -Location $Location `
        -Family "Y" `
        -PricingTier "1" `
        -Instances "0" `
        -TemplateFile $aspTemplateFile `
        -DeploymentName $aspDeploymentName

    #Application Insights
    if ($CreateApplicationInsights) {
        $applicationInsightsTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\ApplicationInsights.json"
        $applicationInsightsDeploymentName = ((Get-ChildItem $applicationInsightsTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

        New-ApplicationInsights `
            -ResourceGroupName $ResourceGroupName `
            -ApplicationInsightsName $applicationInsightsName `
            -Location $Location `
            -TemplateFile $applicationInsightsTemplateFile `
            -DeploymentName $applicationInsightsDeploymentName
    }
    else {
        Write-Verbose "Create Application Insights is false so check if Application Insights '$applicationInsightsName' already exist"
        $applicationInsights = Get-AzApplicationInsights -Name $applicationInsightsName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($applicationInsights) {
            Write-Information "Application Insights '$applicationInsightsName' exists so remove it"
            Remove-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $applicationInsightsName
        }
        else {
            Write-Information "Application Insights '$applicationInsightsName' doesn't exist so do nothing"
        }

        $applicationInsightsName = $null
    }

    # Storage Account
    $storageAccountTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\StorageAccount.json"
    $storageAccountDeploymentName = ((Get-ChildItem $storageAccountTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

    New-StorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $storageAccountName `
        -Location $Location `
        -AccountType "Standard_LRS" `
        -AccessTier "Cool" `
        -TemplateFile $storageAccountTemplateFile `
        -DeploymentName $storageAccountDeploymentName

    # Function App
    $functionAppTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\FunctionApp.json"
    $functionAppDeploymentName = ((Get-ChildItem $functionAppTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))

    New-FunctionApp `
        -ResourceGroupName $ResourceGroupName `
        -FunctionAppName $functionAppName `
        -Location $Location `
        -StorageAccountName $storageAccountName `
        -AppServicePlanName $appServicePlanName `
        -KeyVaultName $KeyVaultName `
        -Schedule $Schedule `
        -DefaultKeyName $DefaultKeyName `
        -KeyDurationInMinutes $KeyDurationInMinutes `
        -ApplicationInsightsName $applicationInsightsName `
        -TenantId $TenantId `
        -TemplateFile $functionAppTemplateFile `
        -DeploymentName $functionAppDeploymentName

    Write-Information 'Sleep 60 sec because function app is slow to start up'
    Start-Sleep 60

    # Get ARM output variables
    Write-Information "Retrieve Function App MSI SP from ARM output"
    $functionAppSpId = (Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $functionAppDeploymentName).Outputs.functionAppSpId.value
    Write-Verbose "functionAppSpId: $functionAppSpId"

    Write-Information "Retrieve Function App name ARM output"
    $functionAppName = (Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $functionAppDeploymentName).Outputs.functionAppName.value
    Write-Verbose "functionAppName: $functionAppName"

    # KeyVault Access Policy
    Write-Information "Set access policy for Function App Service Principal Id"
    Set-AzKeyVaultAccessPolicy `
        -VaultName $KeyVaultName `
        -ObjectId $functionAppSpId `
        -PermissionsToSecrets Get, List, Set

    # Publish Azure AD Application Key Rotator from the artifacts folder
    Write-Information "Publish the Application Key Rotator to the Function App"
    $zipFilePath = Join-Path -Path $PSScriptRoot -ChildPath ".\Artifacts\ApplicationKeyRotator.zip"
    Publish-AppService `
        -ResourceGroupName $ResourceGroupName `
        -ZipFilePath $zipFilePath `
        -AppServiceName $functionAppName   
}

Export-ModuleMember -Function Set-AzureAdApplicationKeyRotator
