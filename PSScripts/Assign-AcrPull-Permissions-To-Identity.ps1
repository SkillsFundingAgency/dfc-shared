<#
.SYNOPSIS
Grants list,get permissions on supplied keyvault to supplied application identity

.DESCRIPTION
Grants list,get permissions on supplied keyvault to supplied application identity

.PARAMETER KeyVaultName
Name of the keyvault

.PARAMETER ServicePrincipalName
Name of the service principal

.EXAMPLE
Assign-AcrPull-Permissions-To-Identity.ps1 -KeyVaultName KeyVaultName -ServicePrincipalName ServicePrincipalName
Assign-KeyVault-Permissions-To-Identity.ps1 -KeyVaultName dfc-dev-shared-kv -ServicePrincipalName dfc-dev-api-eventgridsubscriptions-fa -Verbose
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