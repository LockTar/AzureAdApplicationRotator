function Publish-AppService {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [System.String]
        $ResourceGroupName,    

        [Parameter(Mandatory = $True)]
        [System.String]
        $ZipFilePath,    

        [Parameter(Mandatory = $True)]
        [System.String]
        $AppServiceName
    )

    Write-Verbose "Getting publishing profile of App Service"
    $publishProfilePath = Join-Path -Path $ENV:Temp -ChildPath "publishprofile.xml"
    $null = Get-AzureRmWebAppPublishingProfile `
        -OutputFile $publishProfilePath `
        -Format WebDeploy `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppServiceName 

    # Stop the web app to make sure deployment is possible.
    Write-Verbose "Stopping App Service so we can safely deploy"
    $null = Stop-AzureRmWebApp `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppServiceName 

    Write-Verbose "Parsing the credentials"    
    [Xml]$publishsettingsxml = Get-Content $publishProfilePath
    $userName = $publishsettingsxml.publishData.publishProfile[0].userName      
    $password = $publishsettingsxml.publishData.publishProfile[0].userPWD

    Write-Verbose "Building up the credential header"
    $pair = "$($userName):$($password)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"

    $headers = @{
        Authorization = $basicAuthValue
    }

    # Use Kudu deploy
    Write-Verbose "Publish the zip to the App Service"
    Invoke-WebRequest -UseBasicParsing -Uri https://$AppServiceName.scm.azurewebsites.net/api/zipdeploy -Headers $headers `
        -InFile $ZipFilePath -ContentType "multipart/form-data" -Method Post

    Write-Verbose "Start the App Service"
    $null = Start-AzureRmWebApp `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppServiceName

    Write-Verbose "App Service deployment complete"
}