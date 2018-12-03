$applicationName = "AppKeyRotator"
$environment = "Test"

$functionAppName = $applicationName + $environment
$appObjectIdThatNeedsRotation = "83d86c42-6567-49e0-ab8c-e40848205883"

#Get MSI of rotator function app
Get-AzureRmADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }
$msiObjectId = $(Get-AzureRmADServicePrincipal -SearchString $functionAppName | Where-Object { $_.DisplayName -eq $functionAppName }).Id

# Get application and service principal
Get-AzureRmADApplication -ObjectId $appObjectIdThatNeedsRotation
Get-AzureRmADApplication -ObjectId $appObjectIdThatNeedsRotation | Get-AzureRmADServicePrincipal

#Add MSI as owner of the application
Get-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation
Add-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation -RefObjectId $msiObjectId
Get-AzureADApplicationOwner -ObjectId $appObjectIdThatNeedsRotation