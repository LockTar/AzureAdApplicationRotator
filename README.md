# Azure AD Application Rotator

Rotate your Azure AD Application (App Registration) keys periodically to an Azure KeyVault.

## What does it do

Let's say you have some Azure AD Applications for your business applications.
For in example letting users login into a web application with his or her AD account. You need an Azure AD application with a key to do that. Those keys can be rotated into an Azure KeyVault. In that way, you have more security in your business application. The business application can just retrieve the current key from the KeyVault.

## Get Started

### Automated via Azure DevOps extension

1. Install the extension from the marketplace.
2. Create an Azure Resource Manager Service Connection in your Azure DevOps Team Project manually or let Azure DevOps create one for you.
3. Go to the [Azure portal](https://portal.azure.com)
4. In the Azure portal, navigate to **App Registrations**
5. Select the created app registration. If you can't find it, you probably don't have the right permissions. You can still find the app registration by changing the filter dropdown box to **All apps**.
6. Check the **Owners** of the selected app registration (application). If your not an owner, find an **owner** or a **Global Administrator** (you will need a Global Admin in the next steps).
7. Set the **Required Permissions** at least with the following Resource Access **Windows Azure Active Directory (Microsoft.Azure.ActiveDirectory)** with the **application** permission **Read directory data**. When you save this, this will result in the following array in the **manifest**:

    ```json
    "requiredResourceAccess": [
      {
        "resourceAppId": "00000002-0000-0000-c000-000000000000",
        "resourceAccess": [
          {
            "id": "5778995a-e1bf-45b8-affa-663a9f3f4d04",
            "type": "Role"
          }
        ]
      }
    ]
    ```
8. **Very important** Request an Azure Global Administrator to hit the button **Grant permissions** in the **Required Permissions** view. This only has to be done once.
9. Create a Release pipeline in your Team Project.
10. Create a Resource Group in your Release Pipeline (in example with PowerShell or Azure CLI). In example:
    ```powershell
    $resourceGroupName = "$(ResourceGroupName)"
    $location = "$(Location)"
    Write-Verbose "Get Resource Group '$resourceGroupName'"
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

    if (!$resourceGroup) {
       Write-Information "Create Resource Group '$resourceGroupName'"
       New-AzResourceGroup -Name $resourceGroupName -Location $location

       Write-Verbose "Give azure some time to create Resource Group"
       Start-Sleep 10
    }
    ```
11. Create a Key Vault in your Release Pipeline (in example with PowerShell or Azure CLI). In example:
    ```powershell
    $resourceGroupName = "$(ResourceGroupName)"
    $keyVaultName = "$(KeyVaultName)"
    $location = "$(Location)"

    $keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if (!$keyVault) {
        New-AzKeyVault -Name $keyVaultName  -Location $location -ResourceGroupName $resourceGroupName

        Write-Verbose "Give azure some time to create Resource Group"
        Start-Sleep 10
    }
    ```
12. Create a new Azure AD Application (App Registration) or use an existing in your tenant that needs rotation. You will get an `applicationId` and a `ObjectId` for this. You can see this in the Azure portal.
13. Set the rotator service principal (MSI) as owner of that application. See [How to set correct AD permissions of MSI](#How-to-set-correct-AD-permissions-of-MSI) for more information.
14. Create a placeholder secret in the KeyVault where the keys of your application will be rotated with the following PowerShell:
    ```powershell
    # Add a test secret
    Write-Information "Add a placeholder secret so we can rotate keys for a specific application"
    $tags = @{ApplicationObjectId = "PASTE OBJECTID (NOT APPLICATIONID) OF YOUR APPLICATION THAT NEEDS ROTATION HERE"}
    $secretValue = ConvertTo-SecureString -String 'Foo' -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'YOUR SECRET NAME THAT YOU USE IN YOUR CODE OF YOUR BUSINESS APPLICATION' -SecretValue $secretValue -Tag $tags
    ```
    You can add multiple secrets in your KeyVault for multiple applications.
15. Use the 'Set Azure AD Application Key Rotator' task after the Key Vault and the placeholder secret creation task in your Release Pipeline.

### Manual steps

1. Install the rotator function in a Resource Group.
2. Get the Service Principal Object Id of the function (MSI).
    ```powershell
    # Get MSI of rotator function app
    Get-AzADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }
    $rotatorAppSpId = $(Get-AzADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }).Id
    ```
3. Create a new Azure AD Application (App Registration) or use an existing in your tenant that needs rotation. You will get an `applicationId` and a `ObjectId` for this. You can see this in the Azure portal.
4. Set the rotator service principal (MSI) as owner of that application. See [How to set correct AD permissions of MSI](#How-to-set-correct-AD-permissions-of-MSI) for more information.
5. Create a placeholder secret in the KeyVault where the keys of your application will be rotated with the following PowerShell:
    ```powershell
    # Add a test secret
    Write-Information "Add a placeholder secret so we can rotate keys for a specific application"
    $tags = @{ApplicationObjectId = "PASTE OBJECTID (NOT APPLICATIONID) OF YOUR APPLICATION THAT NEEDS ROTATION HERE"}
    $secretValue = ConvertTo-SecureString -String 'Foo' -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name 'YOUR SECRET NAME THAT YOU USE IN YOUR CODE OF YOUR BUSINESS APPLICATION' -SecretValue $secretValue -Tag $tags
    ```
    You can add multiple secrets in your KeyVault for multiple applications.
6. Make sure that the rotator function has the right Access Policy on the KeyVault. You can set that with the following PowerShell:

    ```powershell
    Write-Information "Set access policy for Application Key Rotator Function App Service Principal Id"
    Set-AzKeyVaultAccessPolicy `
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

    "LocalDevelopment": true,
    "TenantId": "Here the tentant id of you application",
    "ClientId": "Clientid of an AD Application to run locally",
    "ClientSecret": "Client secret of the above clientid to authenticate",

    "KeyVaultUrl": "https://KeyVaultNameHere.vault.azure.net/",
    "DefaultKeyName": "RotatedKey",
    "KeyDurationInMinutes": 2,

    "Schedule": "0 */1 * * * *"
  }
}
```

Run the `\scripts\test\Test-KeyRotator.ps1` file to generate some test environment and to test your code in the cloud.

## FAQ

### How to set correct AD permissions of MSI

The Azure Function App rotator runs under Managed Service Identity (MSI). This MSI is generated when you create the Function app. It is removed when you remove the Function app or when you refresh the MSI of the active Function app. The MSI **must** have AD permissions to **manage app registrations** (Manage apps that this app creates or owns) where it is owner on.\
\
You can check if the MSI already has the right permissions with the [Azure AD Graph Explorer](https://graphexplorer.azurewebsites.net). Login to the explorer and execute the following url to get the app roles of the MSI:\
`https://graph.windows.net/<YOUR TENANT ID HERE>/servicePrincipals/<YOUR MSI ID HERE>/appRoleAssignments`

The following script will set the right permissions. Because this app role need admin consent, it needs to be executed by an **Global Administrator** of your tenant.

```powershell
Connect-AzureAD
$msiObjectId = "YOUR MSI OBJECT ID HERE"

$adgraph = Get-AzureADServicePrincipal -Filter "AppId eq '00000002-0000-0000-c000-000000000000'"
Write-Host "-ResourceId $($adgraph.ObjectId)"

# Manage apps that this app creates or owns (Role: Application.ReadWrite.OwnedBy)
$rdscope = "824c81eb-e3f8-4ee6-8f6d-de7f50d565b7"

# Read directory data (Role: Directory.Read.All)
$rdscope2 = "5778995a-e1bf-45b8-affa-663a9f3f4d04"

try
{
    New-AzureADServiceAppRoleAssignment -Id $rdscope -PrincipalId $msiObjectId -ObjectId $msiObjectId -ResourceId $adgraph.ObjectId
    New-AzureADServiceAppRoleAssignment -Id $rdscope2 -PrincipalId $msiObjectId -ObjectId $msiObjectId -ResourceId $adgraph.ObjectId
}
#the New-AzureADServiceAppRoleAssignment is throwing the following exception
#the message is Unauthorized, but the assignment is applied!
catch [Microsoft.Open.AzureAD16.Client.ApiException]
{
    #This error appears when the assignment already has been done
    if ($Error[0].Exception.Message.Contains("BadRequest"))
    {
        Write-Output "The Role assignment was already applied. Check if all roles are applied!"
    }
}

Write-Output "The Role assignment:"
Get-AzureADServiceAppRoleAssignedTo -ObjectId $msiObjectId
```

Next to this, the MSI must be **Owner** of the app registration from which you want to rotate the key from otherwise it can't create new keys. You can do this with the following script. The person or service principal that runs this script needs to be **owner of the app registration** in order to set a new owner.

```powershell
Connect-AzureAD
Connect-AzAccount

$msiObjectId = "YOUR MSI OBJECT ID HERE"
# Get application that needs key rotation
$appObjectIdThatNeedsRotation = "PASTE OBJECTID (NOT APPLICATIONID) OF YOUR APPLICATION THAT NEEDS ROTATION HERE"

Get-AzADApplication -ObjectId $appObjectIdThatNeedsRotation
Get-AzADApplication -ObjectId $appObjectIdThatNeedsRotation | Get-AzADServicePrincipal

# Add MSI as owner of the application
Add-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation -RefObjectId $msiObjectId
Get-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation
```

**Restart the Function App** so the MSI will pick up the new permissions.

### Forbidden to get active directory application with id

See [How to set correct AD permissions of MSI](#How-to-set-correct-AD-permissions-of-MSI) for more information.
