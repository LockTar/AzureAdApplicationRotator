# Azure Ad Application Rotator
Rotate your Azure AD Application (App Registration) keys periodically to an Azure KeyVault.

## Getting started
Comming soon...

## Contribute
Create a `local.settings.json` file in the root of the `ApplicationRotator` function.

Contents of the `local.settings.json`:

    {
      "IsEncrypted": false,
      "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "AzureWebJobsDashboard": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet",
        "TenantId": "Here the tentant id of you application",
        "ClientId": "Clientid of an AD Application to run locally",
        "ClientSecret": "Client secret of the above clientid to authenticate"
      }
    }
