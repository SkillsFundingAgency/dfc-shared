<#
.SYNOPSIS
Creates the Service Principals and App Registrations required by an Azure Kubernetes Cluster

.DESCRIPTION
Creates the Service Principals and App Registrations required by an Azure Kubernetes Cluster.  The Application (Client) IDs are written out to Azure DevOps variables to be consumed by later steps in the pipeline.

.PARAMETER AksServicePrincipalName
The name of the AAD Service Principal that will be granted Contributor rights on the Azure Subscription that the AKS cluster resides in.
If executed from Azure DevOps this will be the default subscription of the Azure DevOps Service Principal.  The name should be in the format dfc-<env>-shared-aks-svc.

.PARAMETER AksAdClientApplicationName
The name of the AAD Application registration that will be granted permissions user_impersonation on the AksAdServerApplicationName app registration.  The name should be in the format dfc-<env>-shared-aks-client.

.PARAMETER AksAdServerApplicationName
The name of the AAD Application registration that will be granted permissions on the Microsoft Graph API to interact with AAD on behalf of the AKS cluster.
The permissions granted will be Directory.Read.All and User.Read.  The name should be in the format dfc-<env>-shared-aks-api.

.PARAMETER DfcDevOpsScriptRoot
The path to the PSScripts folder in the local copy of the dfc-devops repo, eg $(System.DefaultWorkingDirectory)/_SkillsFundingAgency_dfc-devops/PSScripts in an Azure DevOps task

.PARAMETER SharedKeyVaultName
The name of the KeyVault where the App Registration secrets will be stored.  Must be in the same tenant.

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

$LogFile = New-Item -Path $DfcDevOpsScriptRoot -Name "$env:Release__EnvironmentName-Logfile.log" -Force

# Create Service Principal with Contributor on Subscription
$Context = Get-AzureRmContext
$AksServicePrincipal = & $DfcDevOpsScriptRoot/New-ApplicationRegistration.ps1 -AppRegistrationName $AksServicePrincipalName -AddSecret -KeyVaultName $SharedKeyVaultName -Verbose | Tee-Object -FilePath $LogFile -Append
$ExistingAssignment = Get-AzureRmRoleAssignment -ObjectId $AksServicePrincipal.Id -RoleDefinitionName Contributor -Scope "/subscriptions/$($Context.Subscription.Id)"
if ($ExistingAssignment) {

    Write-Verbose "$($ExistingAssignment.DisplayName) is assigned $($ExistingAssignment.RoleDefinitionName) on /subscriptions/$($Context.Subscription.Id)"

}
else {

    Write-Verbose "Assigning 'Contributor' to $($AksServicePrincipal.Id)"
    # Service Principal isn't immediately available to add role to
    Start-Sleep -Seconds 15
    New-AzureRmRoleAssignment -ObjectId $AksServicePrincipal.Id -RoleDefinitionName Contributor -Scope "/subscriptions/$($Context.Subscription.Id)"

}
Write-Verbose "Writing AksServicePrincipal ApplicationId value [$($AksServicePrincipal.ApplicationId)] to variable AksServicePrincipalClientId"
Write-Output "##vso[task.setvariable variable=AksServicePrincipalClientId]$($AksServicePrincipal.ApplicationId)"

# Create Service Principal with Delegated Permissions Directory.Read.All & User.Read and Application Permissions Directory.Read.All
$AksAdServerApplication = & $DfcDevOpsScriptRoot/New-ApplicationRegistration.ps1 -AppRegistrationName $AksAdServerApplicationName -AddSecret -KeyVaultName $SharedKeyVaultName -Verbose | Tee-Object -FilePath $LogFile -Append
# Service Principal isn't immediately available to add API permissions to
Start-Sleep -Seconds 15
& $DfcDevOpsScriptRoot/Add-AzureAdApiPermissionsToApp.ps1 -AppRegistrationDisplayName $AksAdServerApplicationName -ApiName "Microsoft Graph" -ApplicationPermissions "Directory.Read.All" -DelegatedPermissions "Directory.Read.All", "User.Read" -Verbose
Write-Verbose "Writing AksAdServerApplication ApplicationId value [$($AksAdServerApplication.ApplicationId)] to variable AksRbacServerAppId"
Write-Output "##vso[task.setvariable variable=AksRbacServerAppId]$($AksAdServerApplication.ApplicationId)"

# Create Service Principal with Delegated user_impersonation on $AksAdServerApplication
$AksAdClientApplicationSpn = & $DfcDevOpsScriptRoot/New-ApplicationRegistration.ps1 -AppRegistrationName $AksAdClientApplicationName -Verbose | Tee-Object -FilePath $LogFile -Append
# Service Principal isn't immediately available to add API permissions to
Start-Sleep -Seconds 15
& $DfcDevOpsScriptRoot/Add-AzureAdApiPermissionsToApp.ps1 -AppRegistrationDisplayName $AksAdClientApplicationName -ApiName $AksAdServerApplication.DisplayName -DelegatedPermissions "user_impersonation" -Verbose
# Set the allowPublicClient property of the App Registration to true.  This step depends on the token for Microsoft Graph obtained during the execution of Add-AzureAdApiPermissionsToApp.ps1
$AksAdClientApplication = Get-AzureRmADApplication -DisplayName $AksAdClientApplicationSpn.DisplayName
Write-Verbose "Setting allowPublicClient on $($AksAdClientApplicationSpn.DisplayName) [$($AksAdClientApplication.ObjectId)] to true"
Set-AzureADApplication -ObjectId $AksAdClientApplication.ObjectId -PublicClient $true -IdentifierUris @()
Write-Verbose "Writing AksAdClientApplicationSpn ApplicationId value [$($AksAdClientApplicationSpn.ApplicationId)] to variable AksRbacClientAppId"
Write-Output "##vso[task.setvariable variable=AksRbacClientAppId]$($AksAdClientApplicationSpn.ApplicationId)"

Write-Verbose "Getting logs from $($LogFile.FullName)"
$Logs = Get-Content -Path $LogFile
if ($Logs -match "Registering service principal ...") {

    Write-Verbose "Service Principal creation detected in logs, manual steps required"
    throw "Service Principal permissions needs approving and variables may need to be created or updated in Azure DevOps, see dfc-shared README.md"

}
else {

    Write-Verbose "Service Principal creation not detected in logs"

}