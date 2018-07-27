Param(
    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$Location,
    [string]$AccountType,
    [string]$AccessTier,
    [string]$TemplateFile,
    [string]$DeploymentName
)

$ErrorActionPreference = "Stop"

Write-Information "Create Storage Account"

# Create parameters object for ARM template
$parametersARM = @{}
$parametersARM.Add("storageAccountName", $StorageAccountName)
$parametersARM.Add("location", $Location)
$parametersARM.Add("accountType", $AccountType)
$parametersARM.Add("accessTier", $AccessTier)

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
