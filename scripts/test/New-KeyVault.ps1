function New-KeyVault {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$KeyVaultName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        [Parameter(Mandatory=$true)]
        [string]$DeploymentName
    ) 

    Write-Information "Create KeyVault" 

    # Create parameters object for ARM template
    $parametersARM = @{}
    $parametersARM.Add("keyVaultName", $KeyVaultName)
    $parametersARM.Add("location", $Location)

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
