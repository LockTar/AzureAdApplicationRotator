Param(
    [string]$ResourceGroupName,
    [string]$AppServicePlanName,
    [string]$Location,
    [string]$Family,
    [string]$PricingTier,
    [int]$Instances,
    [string]$TemplateFile,
    [string]$DeploymentName
)

$ErrorActionPreference = "Stop"

Write-Information "Set App Service Plan '$AppServicePlanName'"

# Create parameters object for ARM template
$parametersARM = @{}
$parametersARM.Add("appServicePlanName", $AppServicePlanName)
$parametersARM.Add("location", $Location)
$parametersARM.Add("family", $Family)
$parametersARM.Add("pricingTier", $PricingTier)
$parametersARM.Add("instances", $Instances)

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
