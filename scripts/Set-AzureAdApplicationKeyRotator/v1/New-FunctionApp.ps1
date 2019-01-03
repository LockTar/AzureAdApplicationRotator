function New-FunctionApp {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$FunctionAppName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true)]
        [string]$AppServicePlanName,
        [Parameter(Mandatory=$true)]
        [string]$Schedule,
        [Parameter(Mandatory=$false)]
        [string]$ApplicationInsightsName,
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        [Parameter(Mandatory=$true)]
        [string]$DeploymentName
    )

    Write-Information "Set Function App '$FunctionAppName'"

    # Create parameters object for ARM template
    $parametersARM = @{}
    $parametersARM.Add("functionAppName", $FunctionAppName)
    $parametersARM.Add("location", $Location)
    $parametersARM.Add("storageAccountName", $StorageAccountName)
    $parametersARM.Add("appServicePlanName", $AppServicePlanName)
    $parametersARM.Add("schedule", $Schedule)
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
}