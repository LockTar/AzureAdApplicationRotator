Param(     
    [string]$ResourceGroupName,
    [string]$KeyVaultName,
    [string]$Location,
    [string]$TemplateFile,
    [string]$DeploymentName
) 

$ErrorActionPreference = "Stop" 

Write-Information "Create KeyVault" 

# Create parameters object for ARM template
$parametersARM = @{}
$parametersARM.Add("keyVaultName", $KeyVaultName)
$parametersARM.Add("location", $Location)

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
