Trace-VstsEnteringInvocation $MyInvocation

# Get inputs.
$createIfNotExist = Get-VstsInput -Name createIfNotExist -AsBool
$objectId = Get-VstsInput -Name objectId
$name = Get-VstsInput -Name name -Require
$appIdUri = Get-VstsInput -Name appIdUri -Require
$homePageUrl = Get-VstsInput -Name homePageUrl
$logoutUrl = Get-VstsInput -Name logoutUrl
$termsOfServiceUrl = Get-VstsInput -Name termsOfServiceUrl
$privacyStatementUrl = Get-VstsInput -Name privacyStatementUrl
$multiTenant = Get-VstsInput -Name multiTenant -AsBool
$replyUrlsMethod = Get-VstsInput -Name replyUrlsMethod -Require
$replyUrlsSingleLine = Get-VstsInput -Name replyUrlsSingleLine
$replyUrlsMultiLine = Get-VstsInput -Name replyUrlsMultiLine
$resourceAccessFilePath = Get-VstsInput -Name resourceAccessFilePath
$owners = Get-VstsInput -Name owners

# Create pretty array for optional replyurls array
$replyUrlsArray = @()
switch ($replyUrlsMethod)
{
    "Singleline"
    {
        if ($replyUrlsSingleLine -ne "") {
            $replyUrlsArray = $replyUrlsSingleLine.Split(";")
        }
    }
    "Multiline"
    {
        if ($replyUrlsMultiLine -ne "") {
            $replyUrlsArray = $replyUrlsMultiLine.Split("`n")
        }
    }
}

# Create pretty array for optional owners array
$ownersArray = @()
if ($owners -ne "") {
    $ownersArray = $owners.Split("`n")
}

# Initialize Azure Connection
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers\VstsAzureHelpers.psm1
Initialize-PackageProvider
Initialize-Module -Name "AzureRM.Resources" -RequiredVersion "6.7.0"
Initialize-AzureRM

Initialize-Module -Name "AzureAD" -RequiredVersion "2.0.2.4"
Initialize-AzureAD

Write-Verbose "Input variables are: "
Write-Verbose "createIfNotExist: $createIfNotExist"
Write-Verbose "objectId: $objectId"
Write-Verbose "name: $name"
Write-Verbose "appIdUri: $appIdUri"
Write-Verbose "homePageUrl: $homePageUrl"
Write-Verbose "logoutUrl: $logoutUrl"
Write-Verbose "termsOfServiceUrl: $termsOfServiceUrl"
Write-Verbose "privacyStatementUrl: $privacyStatementUrl"
Write-Verbose "multiTenant: $multiTenant"
Write-Verbose "replyUrls: $replyUrls"
Write-Verbose "replyUrlsArray: $replyUrlsArray"
Write-Verbose "resourceAccessFilePath: $resourceAccessFilePath"
Write-Verbose "owners: $owners"
Write-Verbose "ownersArray: $ownersArray"

Write-Verbose "Add service principal of the azurerm connection to the array of owners"
$serviceName = Get-VstsInput -Name ConnectedServiceNameARM -Require
$endpoint = Get-VstsEndpoint -Name $serviceName -Require
$clientId = $endpoint.Auth.Parameters.ServicePrincipalId
$deployServicePrincipalId = (Get-AzureRmADServicePrincipal -ApplicationId $clientId).Id
$ownersArray += $deployServicePrincipalId

Import-Module $PSScriptRoot\scripts\Get-AadApplication.psm1
Import-Module $PSScriptRoot\scripts\New-AadApplication.psm1
Import-Module $PSScriptRoot\scripts\Set-AadApplication.psm1

if ($createIfNotExist) {
    Write-Verbose "Check if the application '$name' exists"
    $result = Get-AadApplication -ApplicationName $name -FailIfNotFound $false

    if (!$result.Application) {
        Write-Verbose "Application doesn't exist. Create the application '$name'"
        New-AadApplication -ApplicationName $name -SignOnUrl $homePageUrl

        $secondsToWait = 60
        Write-Verbose "Application '$name' is created but wait $secondsToWait seconds so Azure AD can process it and we can set all the properties"
        Start-Sleep -Seconds $secondsToWait
    }

    Write-Verbose "Get the application '$name' again so we have the ObjectId to alter the application"
    $result = Get-AadApplication -ApplicationName $name -FailIfNotFound $false

    $objectId = $result.Application.ObjectId
}

Set-AadApplication `
    -ObjectId $objectId `
    -Name $name `
    -AppIdUri $appIdUri `
    -HomePageUrl $homePageUrl `
    -LogoutUrl $logoutUrl `
    -TermsOfServiceUrl $termsOfServiceUrl `
    -PrivacyStatementUrl $privacyStatementUrl `
    -MultiTenant $multiTenant `
    -ReplyUrls $replyUrlsArray `
    -ResourceAccessFilePath $resourceAccessFilePath `
    -Owners $ownersArray