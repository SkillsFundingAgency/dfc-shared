# dfc-shared

[![Build status](https://sfa-gov-uk.visualstudio.com/Digital%20First%20Careers/_apis/build/status/DFC%20Shared/dfc-shared?branchName=master)](https://sfa-gov-uk.visualstudio.com/Digital%20First%20Careers/_build/latest?definitionId=1131)

Repository with all the shared Azure resources used across the DFC services.
Each environment (DEV, LAB, SIT, PP and PRD) will have its own shared resources.

Deployed using the comnbination of a template file and a parameters file.

Two parameters files must be maintained:
    * [parameters.json](Resources\parameters.json) is used in the Azure DevOps pipeline and has tokenized values managed within Azure DevOps.
    * [test-parameters.json](Resources\template.json) for local and test deployment.

## Deploying

After completing the initial deployment the permissions on the AKS Service Principals will need approving.  The Service Principals are created and approved by the [New-AksServicePrincipals.ps1](PSScripts\New-AksServicePrincipals.ps1) script.  The script will parse the logs to detect the creation of any new Service Principals, if it does it will abort the deployment.  The manual steps below will need to be completed before rerunning the deployment.

1. To approve the permissions added by the script:
- Log on to the Azure Portal of the relevant tenent and elevant your permissions if necessary
- Browse to Azure Active Directory > App Registrations > All Applications and search for dfc-<env>, you should see 3 app registrations that contain an 'aks' segment in their name
- To approve the API permissions click dfc-<env>-shared-aks-api > API Permissions > Grant admin consent for Default Directory.  The permissions on dfc-<env>-shared-aks-client do not need approving and dfc-<env>-shared-aks-svc isn't assigned any API permissions

2. The secrets for the service principals are stored in the dfc-<env>-shared-kv KeyVault, these will need to be manually added to the 'KeyVault - dfc-<env>-shared-kv' variable library in Azure DevOps.  The secrets need to be added for dfc-<env>-shared-aks-api and dfc-<env>-shared-aks-svc, dfc-<env>-shared-aks-client doesn't have a secret

Rerun the failed deployment.

To run the deployment without APIM, set the parameter 'deployApim' to false.

To run the deployment without Managed SQL Instance set the paramter 'deployManageSql' to 'false'.

## Testing

If the template is run locally please ensure you clean up the resources created to avoid pipeline failures with name clashes. If you do not do this the template wil fail with inner errors such as "The account -storage account- is already in another resource group in this susbscription.\"