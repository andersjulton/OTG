
# Translation of F# deployment script in ThonShopping DevOps.
# This script is not complete. Should be further tested.
# Bicep files are ok

$resourceGroup = ""
$location = "westeurope"

$subscription = Get-AzContext
$appInsightName = ""
$appInsightKind = 'web'
$appInsightTags = {}
$Application_Type = 'web'
$SamplingPercentage = 100
$RetentionInDays = 30

$appPlanName = "testPlan"
$workerCount = 3

$storageAccountName = ""
$containerName = ""

$webAppName = ""
$deploymentName = ""

if (!(Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location
}
else {
    Write-Output "Resource group $resourceGroup already exists in subscription $($subscription.subscription.Name)."
    Write-Output "Resources will be deployed to $resourceGroup"
}
New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroup `
    -TemplateFile 'main.bicep' `
    -TemplateParameterObject @{
    'deployAppInsight'   = $false;
    'deployAppPlan'      = $true;
    'appInsightName'     = $appInsightName;
    'appInsightKind'     = $appInsightKind;
    'appInsightTags'     = $appInsightTags;
    'Application_Type'   = $Application_Type;
    'SamplingPercentage' = $SamplingPercentage;
    'RetentionInDays'    = $RetentionInDays;
    'appPlanName'        = $appPlanName;
    'workerCount'        = $workerCount;
    'storageAccountName' = $storageAccountName;
    'containerName'      = $containerName;
}

New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroup `
    -TemplateFile 'main.bicep' `
    -TemplateParameterObject @{
    'deployWebApp' = $true;
    'webAppName'   = $webAppName;
    'deployName'   = $deploymentName;
    'appPlanName'  = $appPlanName;
}
$instrumentationKey = (Get-AzApplicationInsights -ResourceGroupName $resourceGroup -name $appInsightName).InstrumentationKey

$webAppSettings = @(
    @{
        'name'  = 'APPINSIGHTS_INSTRUMENTATIONKEY'
        'value' = $instrumentationKey
    }
    @{
        'name'  = 'ApplicationInsightsAgent_EXTENSION_VERSION'
        'value' = '~2'
    }
    @{
        'name'  = 'XDT_MicrosoftApplicationInsights_Mode'
        'value' = 'recommended'
    }
    @{
        'name'  = 'WEBSITE_TIME_ZONE'
        'value' = 'W. Europe Standard Time'
    }
    @{
        'name'  = 'WEBSITE_SWAP_WARMUP_PING_PATH'
        'value' = '/api/warmup/pages'
    }
    @{
        'name'  = 'WEBSITE_SWAP_WARMUP_PING_STATUSES'
        'value' = 200
    }
)


Set-AzWebAppSlot -ResourceGroupName $resourceGroup -Name $webAppName -Slot $slotName -AppSettings $webAppSettings