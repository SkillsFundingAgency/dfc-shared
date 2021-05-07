<#
.SYNOPSIS
Grants acrPull permissions on supplied resource group to supplied application identity

.DESCRIPTION
Grants acrPull permissions on supplied resource group to supplied application identity

.PARAMETER ResourceGroupName
Name of the ResourceGroupName

.PARAMETER ServicePrincipalName
Name of the service principal

.PARAMETER RoleDefinitionName
Name of the RoleDefinitionName

.EXAMPLE
Assign-KeyVault-Permissions-To-Identity.ps1 -ResourceGroupName dfc-dev-shared-rg -ServicePrincipalName dfc-dev-api-eventgridsubscriptions-fa -RoleDefinitionName acrPull -Verbose
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$ServicePrincipalName,
    [Parameter(Mandatory=$true)]
    [string]$RoleDefinitionName
)

$ServicePrincipalObject = Get-AzADServicePrincipal -DisplayName $ServicePrincipalName

if ($ServicePrincipalObject) {
    Write-Verbose "Setting Application Id for $($ServicePrincipalName)"
    $ObjectId = $ServicePrincipalObject.Id

    Write-Verbose "Assigning $($RoleDefinitionName) permissions to $($ObjectId) with scope $($ResourceGroupName)"
    New-AzRoleAssignment -ResourceGroupName $ResourceGroupName -ObjectId $ObjectId -RoleDefinitionName $RoleDefinitionName

} else {
    Write-Verbose "$($ServicePrincipalName) not found on subscription"
}