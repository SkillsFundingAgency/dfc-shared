<#
.SYNOPSIS
Tests the output of Ouput-AksAvailableUpgrades.

.DESCRIPTION
Tests the output of Ouput-AksAvailableUpgrades.  Ouput-AksAvailableUpgrades uses the az cli to get the available AKS upgrades and writes the count of these to a variable.  This script writes out a warning to Azure DevOps if upgrades are available.  The Az Cli task can't write warnings to Azure DevOps.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [int]$GenerallyAvailableUpgradesCount
)

if ($GenerallyAvailableUpgradesCount -gt 0) {

    Write-Warning "There are $GenerallyAvailableUpgradesCount upgrades available for Kubernetes service.  See logs on previous task for details."

}
else {

    Write-Verbose "No upgrades available for Kubernetes service"
    
}