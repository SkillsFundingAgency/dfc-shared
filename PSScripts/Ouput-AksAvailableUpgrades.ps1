<#
.SYNOPSIS
Gets the available AKS upgrades and writes the information out to logs and a variable.  

.DESCRIPTION
Gets the available AKS upgrades and writes the information out to logs and a variable.  The az cli doesn't handle writing complex objects to Azure DevOps variables well so a simple count is outputted along with more detail to the logs.

.PARAMETER AksResourceGroup
The AKS resource group

.PARAMETER AksServiceName
The AKS service name
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$AksResourceGroup,
    [Parameter(Mandatory=$true)]
    [String]$AksServiceName
)

$Upgrades = az aks get-upgrades --resource-group $AksResourceGroup --name $AksServiceName | ConvertFrom-Json
$GenerallyAvailableUpgrades = $Upgrades.controlPlaneProfile.upgrades | Where-Object { $_.isPreview -ne $true }
Write-Output "##vso[task.setvariable variable=GenerallyAvailableUpgradesCount]$($GenerallyAvailableUpgrades.Count)"
$GenerallyAvailableUpgrades