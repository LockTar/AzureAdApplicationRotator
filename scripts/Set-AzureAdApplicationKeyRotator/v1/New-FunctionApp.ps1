Param(
    [string]$ResourceGroupName,
    [string]$FunctionAppName,
    [string]$Location,
    [string]$StorageAccountName,
    [string]$AppServicePlanName,
    [string]$ApplicationInsightsName,
    [string]$TemplateFile,
    [string]$DeploymentName
)

$ErrorActionPreference = "Stop"

Write-Information "Set Function App '$FunctionAppName'"

# Create parameters object for ARM template
$parametersARM = @{}
$parametersARM.Add("functionAppName", $FunctionAppName)
$parametersARM.Add("location", $Location)
$parametersARM.Add("storageAccountName", $StorageAccountName)
$parametersARM.Add("appServicePlanName", $AppServicePlanName)
$parametersARM.Add("appInsightsName", $ApplicationInsightsName)

# Deploy with ARM
Write-Verbose "Deploy ARM template with deploymentname $DeploymentName"

New-AzureRmResourceGroupDeployment -Name $DeploymentName `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -TemplateParameterObject $parametersARM `
    -Force `
    -Verbose `
    -ErrorVariable ErrorMessages

Write-Verbose "Deployed ARM template, checking for errors..."
if ($ErrorMessages) {
    $wholeError = @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    throw $wholeError
}
