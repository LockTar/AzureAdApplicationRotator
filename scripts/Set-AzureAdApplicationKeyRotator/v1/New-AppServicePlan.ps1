function New-AppServicePlan {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$AppServicePlanName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$Family,
        [Parameter(Mandatory=$true)]
        [string]$PricingTier,
        [Parameter(Mandatory=$true)]
        [int]$Instances,
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        [Parameter(Mandatory=$true)]
        [string]$DeploymentName
    )

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

    New-AzResourceGroupDeployment -Name $DeploymentName `
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
}
