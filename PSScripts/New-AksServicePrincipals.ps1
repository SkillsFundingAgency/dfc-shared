<#
.SYNOPSIS
Creates the Service Principals and App Registrations required by an Azure Kubernetes Cluster

.DESCRIPTION
Creates the Service Principals and App Registrations required by an Azure Kubernetes Cluster

.PARAMETER AksServicePrincipalName
The name of the AAD Service Principal that will be granted Contributor rights on the Azure Subscription that the AKS cluster resides in.
If executed from Azure DevOps this will be the default subscription of the Azure DevOps Service Principal.  The name should be in the format dfc-<env>-shared-aks-svc.

.PARAMETER AksAdClientApplicationName

.PARAMETER AksAdServerApplicationName
The name of the AAD Application registration that will be granted permissions on the Microsoft Graph API to interact with AAD on behalf of the AKS cluster.
The permissions granted will be Directory.Read.All and User.Read.  The name should be in the format dfc-<env>-shared-aks-api.

.PARAMETER DfcDevOpsScriptRoot
The path to the PSScripts folder in the local copy of the dfc-devops repo, eg $(System.DefaultWorkingDirectory)/_SkillsFundingAgency_dfc-devops/PSScripts in an Azure DevOps task

.NOTES
These documents are generally for Azure CLI rather than PowerShell but are a useful reference point
AksServicePrincipalName: https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal
AksAdClientApplicationName & AksAdServerApplicationName: https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$AksServicePrincipalName,
    [Parameter(Mandatory=$true)]
    [String]$AksAdClientApplicationName,
    [Parameter(Mandatory=$true)]
    [String]$AksAdServerApplicationName,
    [Parameter(Mandatory=$true)]
    [String]$DfcDevOpsScriptRoot,
    [Parameter(Mandatory=$true)]
    [String]$SharedKeyVaultName
)

# Create Service Principal with Contributor on Subscription
$AksServicePrincipal = & $DfcDevOpsScriptRoot/New-ApplicationRegistration.ps1 -AppRegistrationName $AksServicePrincipalName -AddSecret -KeyVaultName $SharedKeyVaultName -Verbose
$ExistingAssignment = Get-AzureRmRoleAssignment -ObjectId $AksServicePrincipal.Id --RoleDefinitionName Contributor
if ($ExistingAssignment) {

    Write-Verbose "$($ExistingAssignment.DisplayName) is assigned $($ExistingAssignment.RoleDefinitionName)"

}
else {

    Write-Verbose "Assigning 'Contributor' to $($AksServicePrincipal.Id)"
    New-AzureRmRoleAssignment -ObjectId $AksServicePrincipal.Id --RoleDefinitionName Contributor

}

# Create Service Principl with Delegated Permissions Directory.Read.All & User.Read and Application Permissions Directory.Read.All
& $DfcDevOpsScriptRoot/New-ApplicationRegistration.ps1 -AppRegistrationName $AksAdServerApplicationName -AddSecret -KeyVaultName $SharedKeyVaultName -Verbose
& $DfcDevOpsScriptRoot/Add-AzureAdApiPermissionsToApp.ps1 -AppRegistrationDisplayName $AksAdServerApplicationName -ApiName "Microsoft Graph" -DelegatedPermissions "Directory.Read.All",  "User.Read" -Verbose

# Create Service Principal with Delegated user_impersonation on ``das-dev-shared-aks-api`` (as per Apprenticeships Kubernetes Service)

