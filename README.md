# Azure AD Application Rotator

Rotate your Azure AD Application (App Registration) keys periodically to an Azure KeyVault.

## What does it do

Let's say you have some Azure AD Applications for your business applications.
For in example letting users login into a web application with his or her AD account. You need an Azure AD application with a key to do that. Those keys can be rotated into an Azure KeyVault. In that way, you have more security in your business application. The business application can just retrieve the current key from the KeyVault.

## Getting started

### Automated

```powershell
# Coming soon...
```

### Manual steps

1. Install the rotator function in a Resource Group.
2. Get the Service Principal Object Id of the function (MSI).
    ```powershell
    # Get MSI of rotator function app
    Get-AzureRmADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }
    $rotatorAppSpId = $(Get-AzureRmADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }).Id
    ```
3. Create a new Azure AD Application (App Registration) in your tenant. You will get an `applicationId` and a `ObjectId` for this. You can see this in the portal.
4. Set the rotator service principal (MSI) as owner of the application.

    ```powershell
    # Get application that needs key rotation
    $appObjectIdThatNeedsRotation = "PUT Application ObjectId GUID HERE"

    Get-AzureRmADApplication -ObjectId $appObjectIdThatNeedsRotation
    Get-AzureRmADApplication -ObjectId $appObjectIdThatNeedsRotation | Get-AzureRmADServicePrincipal

    # Add MSI as owner of the application
    Add-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation -RefObjectId $rotatorAppSpId
    Get-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation
    ```

5. Create a key for this application via the portal or via PowerShell with a short live span (ie 1 day). This key will be rotated so a short live span is preferred. The expired keys will be cleaned up by the rotator.
6. Store the created key in a KeyVault with the following PowerShell:

    ```powershell
    # Coming soon...
    ```

7. Make sure that the rotator function has the right Access Policy on the KeyVault. You can set that with the following PowerShell:

    ```powershell
    Write-Information "Set access policy for Application Key Rotator Function App Service Principal Id"
    Set-AzureRmKeyVaultAccessPolicy `
      -VaultName $keyVaultName `
      -ObjectId $rotatorAppSpId `
      -PermissionsToSecrets Get,Set
    ```

## Contribute

Create a `local.settings.json` file in the root of the `ApplicationRotator` function.

Contents of the `local.settings.json`:

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "AzureWebJobsDashboard": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "TenantId": "Here the tentant id of you application",
    "ClientId": "Clientid of an AD Application to run locally",
    "ClientSecret": "Client secret of the above clientid to authenticate",
    "KeyVaultUrl": "https://KeyVaultNameHere.vault.azure.net/"
  }
}
```