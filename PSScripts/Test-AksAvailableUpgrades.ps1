[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$AksResourceGroup,
    [Parameter(Mandatory=$true)]
    [String]$AksServiceName
)

$Upgrades = az aks get-upgrades --resource-group $AksResourceGroup --name $AksServiceName | ConvertFrom-Json
$GenerallyAvailableUpgrades = $Upgrades.controlPlaneProfile.upgrades | Where-Object { $_.isPreview -ne $true }

if ($GenerallyAvailableUpgrades) {

    Write-Warning "Upgrades available for Kubernetes service"
    $GenerallyAvailableUpgrades

}
else {

    Write-Verbose "No upgrades available for Kubernetes service"
    
}