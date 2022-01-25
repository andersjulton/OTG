

function DeployCertificate {
    <#
    .SYNOPSIS
    Buy and deploy azure certificate and create SSL bindings
    
    .DESCRIPTION
    Script for creating an azure certificate order resource and buying a certificate for an Azure DNS Zone.
    Script must have a bicep file for certificate deployment. 
    Automatically save certificate details in keyVault.
    Import certificate to app service.
    Create SSL binding.
    
    .PARAMETER certRg
    Resource group for certificates
    
    .PARAMETER certOrderName
    Name of certificate
    
    .PARAMETER zoneRg
    Resource group of DNS zone
    
    .PARAMETER zoneName
    Name of DNS Zone
    
    .PARAMETER keyVaultName
    Name of keyVault where certificate is saved
    
    .PARAMETER webAppRg
    Resource group of app service
    
    .PARAMETER webAppName
    Name of app service
    #>
    param (
        # Name of resource group containing Azure certificates
        [Parameter(Mandatory = $true)]
        [string]$certRg,
        # Name of new certificate
        [Parameter(Mandatory = $true)]
        [string]$certOrderName,
        # Name of resource group containing Azure DNS Zone
        [Parameter(Mandatory = $true)]
        [string]$zoneRg,
        # Name of DNS zone
        [Parameter(Mandatory = $true)]
        [string]$zoneName,
        # Name of KeyVault containing certificate secrets
        [Parameter(Mandatory = $true)]
        [string]$keyVaultName,
        # Name of resource group containing Azure Web App
        [Parameter(Mandatory = $true)]
        [string]$webAppRg,
        # Name of web app
        [Parameter(Mandatory = $true)]
        [string]$webAppName
    )

    
    $context = Get-AzContext -ErrorAction Stop
    $subscriptionId = $context.Subscription.Id

    Get-AzResourceGroup -Name $certRg -ErrorAction Stop

    Get-AzResourceGroup -Name $zoneRg -ErrorAction Stop

    Get-AzDnsZone -Name $zoneName -ResourceGroupName $zoneRg -ErrorAction Stop

    Get-AzWebApp -ResourceGroupName $webAppRg -Name $webAppName -ErrorAction Stop

    $keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction Stop

    $certName = $certOrderName
    $autoRenew = $true
    $distinguishedName = "CN=$($zoneName)"
    $productType = "StandardDomainValidatedSsl"
    $keyvaultid = $keyVault.ResourceId
    $keyvaultSecret = $certOrderName
    $makeCertOrder = $false
    $makeCert = $false

    # Deploy certificate order
    New-AzResourceGroupDeployment `
        -ResourceGroupName $certRg `
        -TemplateFile 'certOrder.bicep' `
        -TemplateParameterObject @{
        'certOrderName'      = $certOrderName
        'autoRenew'          = $autoRenew
        'distinguishedName'  = $distinguishedName
        'productType'        = $productType
        'certName'           = $certName
        'keyVaultId'         = $keyvaultid
        'keyVaultSecretName' = $keyvaultSecret
        'makeCertOrder'      = $makeCertOrder
        'makeCert'           = $makeCert
    }

    # Get newly created certificate order
    $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($certRg)/providers/Microsoft.CertificateRegistration/certificateOrders/$($certOrderName)?api-version=2015-08-01"
    $cert = Invoke-AzRestMethod -Uri $uri -Method GET -ErrorAction Stop
    $content = $cert.Content | ConvertFrom-Json
    $domainVerificationToken = $content.properties.domainVerificationToken

    # Add domain verification token as TXT record to domain for verification.
    $recordSet = Get-AzDnsRecordSet -ResourceGroupName $zoneRg -ZoneName $zoneName -Name "@" -RecordType TXT
    Add-AzDnsRecordConfig -RecordSet $recordSet -Value $domainVerificationToken
    Set-AzDnsRecordSet -RecordSet $recordSet

    Start-Sleep -Seconds 180

    # Verify domain
    $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($certRg)/providers/Microsoft.CertificateRegistration/certificateOrders/$($certOrderName)/verifyDomainOwnership?api-version=2019-08-01"
    $response = Invoke-AzRestMethod -Uri $uri -Method POST -ErrorAction Stop

    if ($response.StatusCode -ne 200) {
        Write-Error "Failed to verify"
        throw $response.Content
    }

    # Deploy new certificate to existing certificate order
    $makecert = $true
    $makeCertOrder = $false

    New-AzResourceGroupDeployment `
        -ResourceGroupName $certRg `
        -TemplateFile 'certOrder.bicep' `
        -TemplateParameterObject @{
        'certOrderName'      = $certOrderName
        'autoRenew'          = $autoRenew
        'distinguishedName'  = $distinguishedName
        'productType'        = $productType
        'certName'           = $certName
        'keyVaultId'         = $keyvaultid
        'keyVaultSecretName' = $keyvaultSecret
        'makeCertOrder'      = $makeCertOrder
        'makeCert'           = $makeCert
    }

    # Get web app details
    $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($webAppRg)/providers/Microsoft.Web/sites/$($webAppName)?api-version=2015-08-01"
    $webApp = Invoke-AzRestMethod -Uri $uri -Method GET -ErrorAction Stop
    $content = $webApp.Content | ConvertFrom-Json
    $webSpace = $content.properties.webSpace
    $serverFarmId = $content.properties.serverFarmId

    # Import certificate to web application
    $body = @{
        "location"   = "westeurope"
        "properties" = @{
            "ServerFarmId"       = $serverFarmId
            "keyVaultId"         = $keyvaultid
            "keyVaultSecretName" = $keyvaultSecret
        }
    }
    $bodyString = $body | ConvertTo-Json
    $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($webAppRg)/providers/Microsoft.Web/certificates/$($certOrderName)-$($webSpace)?api-version=2018-11-01"

    Invoke-AzRestMethod -Uri $uri -Method PUT -Payload $bodyString -ErrorAction Stop

    # Generate SSL bindings for webapp
    $uri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($certRg)/providers/Microsoft.CertificateRegistration/certificateOrders/$($certOrderName)?api-version=2015-08-01"

    $cert = Invoke-AzRestMethod -Uri $uri -Method GET -ErrorAction Stop
    $content = $cert.Content | ConvertFrom-Json
    $thumbprint = $content.properties.signedCertificate.thumbprint

    New-AzWebAppSSLBinding -ResourceGroupName $webAppRg -WebAppName $webAppName -Thumbprint $thumbprint -Name "www.$($zoneName)" -ErrorAction Stop 
    New-AzWebAppSSLBinding -ResourceGroupName $webAppRg -WebAppName $webAppName -Thumbprint $thumbprint -Name $zoneName -ErrorAction Stop 
}
### CODE BELOW FOR USE IN AZURE FUNCTIONS WITH MANAGED IDENTITY ###

# try {
#     "Logging in to Azure..."
#     Connect-AzAccount -Identity
# }
# catch {
#     Write-Error -Message $_.Exception
#     throw $_.Exception
# }

Connect-AzAccount -TenantId "d027b1fe-9231-4605-b90e-e930bc359715" 
Set-AzContext -Subscription "e1aa94ea-64ec-41ad-863a-e68b5cee827e"

$certRg = "thonshopping-domains-certificates"
$zoneRg = "thonshopping-domains"
$keyVaultName = "thonshopping-domains-kv"
$webAppRg = "ThonShopping-internet-web-rg"
$webAppName = "thonshopping-internet-webapp-we"
$certOrderName = "knarvik-senter"
$zoneName = "knarvik-senter.no"

$parameters = @{
    'certRg'        = $certRg
    'certOrderName' = $certOrderName
    'zoneRg'        = $zoneRg
    'zoneName'      = $zoneName
    'keyvaultName'  = $keyVaultName
    'webAppRg'      = $webAppRg
    'webAppName'    = $webAppName
}
DeployCertificate @parameters

### CODE BELOW IS FOR AUTOMATIC PURCHASE OF NEW CERTIFICATE WHEN EXPIRY DATE IS LESS THAN 3 DAYS AWAY ###
### SHOULD BE USED IN AN DAILY SCHEDULE BASED AZURE FUNCTIONS ###

# # Get all certificates in resource group
# $certs = Get-AzWebAppCertificate -ResourceGroupName  $webAppRg
# # Filter out certificates that are not for top level domains
# $validCerts = $certs | Where-Object { $_.SubjectName -notmatch "beta" -and $_.SubjectName -notmatch "stage" }
# # Get all SSL bindings for web app
# $bindings = Get-AzWebAppSSLBinding -ResourceGroupName $webAppRg -WebAppName $webAppName
# # Filter out bindings for beta domains
# $validBindings = $bindings | Where-Object { $_.Name -notmatch "beta" }

# # Loop through each certificate
# foreach ($cert in $validCerts) {
#     $daysToExpiry = New-TimeSpan -Start (Get-Date) -End $cert.ExpirationDate
#     # Skip if certificate is already an Azure bought certificate, assuming it has auto-renew enabled
#     if ($cert.Issuer -eq "Go Daddy Secure Certificate Authority - G2") {
#         Write-Output "Certificate with thumbprint $($cert.Thumbprint) is an Azure purchased certificate."
#         continue
#     }
#     # Skip if more than 3 days to expiry
#     elseif ($daysToExpiry.Days -ge 3) {
#         continue
#     }
#     # Skip if certificate does not have a SSL binding
#     elseif ($validBindings.Thumbprint -notcontains $cert.Thumbprint) {
#         Write-Output "Certificate with thumbprint $($cert.Thumbprint) does not have an active SSL binding."
#         continue
#     }
#     else {
#         # Parse hostname
#         $strSplit = $cert.HostNames[0].Split(".", 3)
#         if ($strSplit.Length -eq 2) {
#             $certOrderName = $strSplit[0]
#             $zoneName = $cert.HostNames[0]
#         }
#         elseif ($strSplit.Length -eq 3) {
#             $certOrderName = $strSplit[1] 
#             $zoneName = "$($strSplit[1]).$($strSplit[2])"
#         }
#         else {
#             Write-Error "Not able to parse hostname: $($cert.HostNames[0])"
#             continue
#         }
#         $parameters = @{
#             'certRg'        = $certRg
#             'certOrderName' = $certOrderName
#             'zoneRg'        = $zoneRg
#             'zoneName'      = $zoneName
#             'keyvaultName'  = $keyVaultName
#             'webAppRg'      = $webAppRg
#             'webAppName'    = $webAppName
#         }
#         DeployCertificate @parameters
#     }
# }



