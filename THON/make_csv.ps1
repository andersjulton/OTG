# Script for making csv file of NS records from zone files

$tenantID = "d027b1fe-9231-4605-b90e-e930bc359715"
$subscription = "e1aa94ea-64ec-41ad-863a-e68b5cee827e"
$path = ""
$resourceGroup = "thonshopping-domains"

az login --tenant $tenantID
az account set --subscription $subscription

$csv = @()

Get-ChildItem $path | Foreach-Object {

    $firstLine = Get-Content $_ -First 1
    $zoneName = $firstLine.Substring(1)

    # Get ns records of all DNS zones in folder path
    $output = az network dns record-set ns list --resource-group $resourceGroup --zone-name $zoneName | ConvertFrom-Json 
    $string = ""
    foreach ($line in $output.nsRecords) {
        $string += "$($line.nsdname)`n"
    }
    
    $props = @{
        Domain     = $zoneName
        NameServer = $string
    }
    
    $csv += new-object psobject -property $props
}
$csv | Select-Object Domain, NameServer | export-csv -path "$path\ns_records_bonus.csv" -notypeinformation -encoding UTF8
