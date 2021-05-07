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
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$ServicePrincipalName,
    [Parameter(Mandatory = $true)]
    [string]$RoleDefinitionName
)

$ServicePrincipalObject = Get-AzADServicePrincipal -DisplayName $ServicePrincipalName

if ($ServicePrincipalObject) {
    Write-Verbose "Setting Application Id for $($ServicePrincipalName)"
    $ObjectId = $ServicePrincipalObject.Id

    Write-Verbose "checking $($RoleDefinitionName) permissions from $($ObjectId) with scope $($ResourceGroupName)"
    if (Get-AzRoleAssignment -ResourceGroupName $ResourceGroupName -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId) {
        Write-Verbose "$($ServicePrincipalNamee) already has $RoleDefinitionName access on $($ResourceGroupName)"
    } else {
        Write-Verbose "Adding $($ServicePrincipalName) with $RoleDefinitionName access on $($ResourceGroupName)"
        New-AzRoleAssignment -ResourceGroupName $ResourceGroupName -RoleDefinitionName $RoleDefinitionName -ObjectId $ObjectId -verbose 
    }

}
else {
    Write-Verbose "$($ServicePrincipalName) not found on subscription"
}