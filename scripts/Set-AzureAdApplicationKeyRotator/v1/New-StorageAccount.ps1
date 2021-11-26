function New-StorageAccount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true)]
        [string]$Location,
        [Parameter(Mandatory=$true)]
        [string]$AccountType,
        [Parameter(Mandatory=$true)]
        [string]$AccessTier,
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        [Parameter(Mandatory=$true)]
        [string]$DeploymentName
    )

    Write-Information "Set Storage Account '$StorageAccountName'"

    # Create parameters object for ARM template
    $parametersARM = @{}
    $parametersARM.Add("storageAccountName", $StorageAccountName)
    $parametersARM.Add("location", $Location)
    $parametersARM.Add("accountType", $AccountType)
    $parametersARM.Add("accessTier", $AccessTier)

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
