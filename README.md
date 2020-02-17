# dfc-shared

[![Build status](https://sfa-gov-uk.visualstudio.com/Digital%20First%20Careers/_apis/build/status/DFC%20Shared/dfc-shared?branchName=master)](https://sfa-gov-uk.visualstudio.com/Digital%20First%20Careers/_build/latest?definitionId=1131)

Repository with all the shared Azure resources used across the DFC services.
Each environment (DEV, LAB, SIT, PP and PRD) will have its own shared resources.

Deployed using the comnbination of a template file and a parameters file.

Two parameters files must be maintained:
    * [parameters.json](Resources/parameters.json) is used in the Azure DevOps pipeline and has tokenized values managed within Azure DevOps.
    * [test-parameters.json](Resources/template.json) for local and test deployment.

## Deploying

After completing the initial deployment the permissions on the AKS Service Principals will need approving.  The Service Principals are created and approved by the [New-AksServicePrincipals.ps1](PSScripts/New-AksServicePrincipals.ps1) script.  The script will parse the logs to detect the creation of any new Service Principals, if it does it will abort the deployment.  The manual steps below will need to be completed before rerunning the deployment.

1. To approve the permissions added by the script:
- Log on to the Azure Portal of the relevant tenent and elevant your permissions if necessary
- Browse to Azure Active Directory > App Registrations > All Applications and search for dfc-<env>, you should see 3 app registrations that contain an 'aks' segment in their name
- To approve the API permissions click dfc-<env>-shared-aks-api > API Permissions > Grant admin consent for Default Directory.  The permissions on dfc-<env>-shared-aks-client do not need approving and dfc-<env>-shared-aks-svc isn't assigned any API permissions

2. The secrets for the service principals are stored in the dfc-<env>-shared-kv KeyVault, these will need to be manually added to the 'KeyVault - dfc-<env>-shared-kv' variable library in Azure DevOps.  The secrets need to be added for dfc-<env>-shared-aks-api and dfc-<env>-shared-aks-svc, dfc-<env>-shared-aks-client doesn't have a secret

Rerun the failed deployment.

To run the deployment without APIM, set the ARM template parameter 'deployApim' to false.

## Post Deployment Steps

1. Add the name of the AKS created route table to the variable group  *dfc-shared-infrastructure-<env>*, inside this variable group is variable called *AksRouteTableName*.  On the initial deployment the value of this variable should be null.  Once AKS has been deployed the value should be set to the name of the route table, this can be found in the dfc-<env>-shared-aksnodes-rg resource group.  If it isn't set the route table will not be attached to the subnet (and therefore AKS) and you will experience intermittent network related failures.

### Notes on the AKS route table

The AKS service depends on a subnet, this subnet needs minimal configuration as the AKS service principal will handle that.  A [vnet and associated subnet](Resources\networks\aks-vnet.json) is defined in this repo.  On the initial deployment it will be deployed without a route table, when the AKS service is deployed it will create a route table and add that to the subnet, this will be created in a resource group called dfc-<env>-shared-aksnodes-rg.  To prevent routetable setting on the subtnet being reset on subsequent deployments we need to pass the name of the routetable AKS creates in as an ARM template parameter.

### Notes on adding Azure Resource roles to dfc-<env>-shared-aks-svc

During the development process more restricted permissions were assigned to the dfc-<env>-shared-aks-svc service principal.  The service principal failed to pick up the permissions associated with the AcrPull role despite waiting overnight, rebooting all the nodes, deleting the pod that required the permissions and deleting the cluster.  It hasn't been established whether this is something to specific to ACR permissions or a wider issue (ACRs are coupled to AKS more closely than other resources).

## Testing

If the template is run locally please ensure you clean up the resources created to avoid pipeline failures with name clashes. If you do not do this the template wil fail with inner errors such as "The account -storage account- is already in another resource group in this susbscription.\"

Test-AzureRmResourceGroupDeployment is ran as part of the pipeline.  When running this against a template that includes Azure Kubernetes Service the tests will fail if some depedancies don't exist in the tenant that the test runs in.  These depedencies include service principals and their secrets and availabilty of VM vCPU cores.  To identify what is causing the test to fail run it locally with the debug switch.

### Notes on AKS daemonset kured

[kured](https://github.com/weaveworks/kured) is a Kubernetes daemonset that automatically reboots AKS nodes after they have been patched.  The current version (1.2.0) doesn't support setting reboot windows so this hasn't been deployed to PRD_SHARED.  The deployment is disabled by a condition in the [Deploy.yml template](Resources\AzureDevOps\JobTemplates\Deploy.yml).