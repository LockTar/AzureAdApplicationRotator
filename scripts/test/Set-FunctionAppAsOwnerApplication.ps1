$applicationName = "AppKeyRotator"
$environment = "Test"

$functionAppName = $applicationName + $environment + "-AppKeyRotator"
$appObjectIdThatNeedsRotation = "83d86c42-6567-49e0-ab8c-e40848205883"

Write-Host "Your Function app is $functionAppName"

#Get MSI of rotator function app
Write-Host "Find Service Principal (MSI) of the function app $functionAppName"
Get-AzADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }
$msiObjectId = $(Get-AzADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }).Id

if ($null -eq $msiObjectId) {
    throw "Can't find the ObjectId of the MSI of the Function APP"
}

# Get application and service principal
Write-Host "The function app will be owner of app object id $appObjectIdThatNeedsRotation"
Get-AzADApplication -ObjectId $appObjectIdThatNeedsRotation
Get-AzADApplication -ObjectId $appObjectIdThatNeedsRotation | Get-AzADServicePrincipal

#Add MSI as owner of the application
Get-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation
Add-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation -RefObjectId $msiObjectId
Get-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation
