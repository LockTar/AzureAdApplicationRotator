$VerbosePreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"


$baseName = "AppKeyRotator"
$environment = "Test"
$location = "westeurope"
$createApplicationInsights = $true

$resourceGroupName = "$baseName-$environment"
$keyVaultName = $baseName + $environment


try {
    # Dot source the private functions.
    . $PSScriptRoot/New-KeyVault.ps1

    Import-Module $PSScriptRoot\..\Set-AzureAdApplicationKeyRotator\v1\Set-AzureAdApplicationKeyRotator.psm1


    # Resource Group error test
    Write-Verbose "Get Resource Group '$resourceGroupName'"
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

    if (!$resourceGroup) {
        Write-Information "Create Resource Group '$resourceGroupName'"
        New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

        Write-Verbose "Give azure some time to create Resource Group"
        Start-Sleep 10
    }

    
    # KeyVault error test
    Write-Verbose "Get Key Vault '$keyVaultName'"
    $keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

    if (!$keyVault) {
        Write-Information "Create Key Vault '$keyVaultName'"
        $keyVaultTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath ".\ARM-Templates\KeyVault.json"
        $keyVaultDeploymentName = ((Get-ChildItem $keyVaultTemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
    
        New-KeyVault `
            -ResourceGroupName $resourceGroupName `
            -KeyVaultName $keyVaultName `
            -Location $location `
            -TemplateFile $keyVaultTemplateFile `
            -DeploymentName $keyVaultDeploymentName

        Write-Verbose "Give azure some time to create Key Vault"
        Start-Sleep 10
    }
    
        
    # Set Rotator
    Set-AzureAdApplicationKeyRotator `
        -ResourceGroupName $resourceGroupName `
        -KeyVaultName $keyVaultName `
        -Location $location `
        -Schedule "0 */1 * * * *" `
        -CreateApplicationInsights $createApplicationInsights `
        -Verbose `
        -InformationAction Continue


    # Add access policy for current user
    Write-Information "Set access policy for current user to set test secret"
    Set-AzureRmKeyVaultAccessPolicy `
        -VaultName $keyVaultName `
        -ObjectId $(Get-AzureRmADUser -UserPrincipalName $(Get-AzureRmContext).Account.Id).Id `
        -PermissionsToSecrets Get, Set

    # Add a test secret
    Write-Information "Add a test secret so we can test the rotation"
    $tags = @{ApplicationObjectId = "83d86c42-6567-49e0-ab8c-e40848205883"}
    $secretValue = ConvertTo-SecureString -String 'Bar' -AsPlainText -Force
    Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name 'Foo' -SecretValue $secretValue -Tag $tags
}
finally {
    Remove-Module Set-AzureAdApplicationKeyRotator
}


try {
    # Remove/clean up of whole Resource Group
    Import-Module $PSScriptRoot\..\Remove-AzureAdApplicationKeyRotator\v1\Remove-AzureAdApplicationKeyRotator.psm1
    Remove-AzureAdApplicationKeyRotator `
        -ResourceGroupName $resourceGroupName `
        -KeyVaultName $keyVaultName `
        -Location $location `
        -Verbose `
        -InformationAction Continue

    Write-Information "Remove Resource Group '$resourceGroupName'"
    Remove-AzureRmResourceGroup -Name $resourceGroupName -Force
}
finally {
    Remove-Module Remove-AzureAdApplicationKeyRotator
}