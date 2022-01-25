Connect-AzAccount -Tenant "d027b1fe-9231-4605-b90e-e930bc359715"
Set-AzContext -Subscription "e1aa94ea-64ec-41ad-863a-e68b5cee827e"

$webAppRg = "ThonShopping-internet-web-rg"

$certs = Get-AzWebAppCertificate -ResourceGroupName  $webAppRg

$validCerts = $certs | Where-Object { $_.ExpirationDate -ge $(Get-Date) } | select  SubjectName, ExpirationDate, Thumbprint | sort ExpirationDate -Descending

$validCerts

foreach ($cert in $certs) {
    if ($cert.Issuer -eq "Go Daddy Secure Certificate Authority - G2") {
        Write-Output $cert.Issuer
    }
}


$period = New-TimeSpan -Start (Get-Date) -End $certs[0].ExpirationDate

if ($period.Days -le 250) {
    Write-Output "hey"
}

$webAppRg = "ThonShopping-internet-web-rg"
$webAppName = "thonshopping-internet-webapp-we"

$certs = Get-AzWebAppCertificate -ResourceGroupName  $webAppRg
$validCerts = $certs | Where-Object { $_.SubjectName -notmatch "beta" -and $_.SubjectName -notmatch "stage" }

$bindings = Get-AzWebAppSSLBinding -ResourceGroupName $webAppRg -WebAppName $webAppName
$validBindings = $bindings | Where-Object { $_.Name -notmatch "beta" }

foreach ($cert in $validCerts) {
    $daysToExpiry = New-TimeSpan -Start (Get-Date) -End $cert.ExpirationDate
    if ($cert.Issuer -eq "Go Daddy Secure Certificate Authority - G2") {
        
        continue
    }
    elseif ($daysToExpiry.Days -ge 400) {
        continue
    }
    elseif ($validBindings.Thumbprint -notcontains $cert.Thumbprint) {
        continue
    }
    else {
        
        $strSplit = $cert.HostNames[0].Split(".", 3)
        if ($strSplit.Length -eq 2) {
            $certOrderName = $strSplit[0]
            $zoneName = $cert.HostNames[0]
        }
        elseif ($strSplit.Length -eq 3) {
            $certOrderName = $strSplit[1] 
            $zoneName = "$($strSplit[1]).$($strSplit[2])"
        }
        Write-Output $certOrderName
    }
}
