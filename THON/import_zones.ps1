### Script for importing DNS Zones to Azure using BIND-files.

$tenantID = "d027b1fe-9231-4605-b90e-e930bc359715"
$subscription = "e1aa94ea-64ec-41ad-863a-e68b5cee827e"
$path = "C:\Users\domin\OneDrive - Nimtech\Documents\WindowsPowerShell\Scripts\OTG\THON\Zones"
$resourceGroup = "thonshopping-domains"

az login --tenant $tenantID
az account set --subscription $subscription

Get-ChildItem $path | Foreach-Object {

    $firstLine = Get-Content $_ -First 1
    $zoneName = $firstLine.Substring(1)

    # If incorrect files from CSC where SOA records are duplicated at end of zone file, uncomment below
    # $content = Get-Content $_
    # $content[0..($content.length - 9)] | Out-File $_ -Force

    az network dns zone import -g $resourceGroup -n $zoneName -f "$path\$($_.Name)"
}