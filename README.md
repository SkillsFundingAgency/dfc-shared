# dfc-shared

[![Build status](https://sfa-gov-uk.visualstudio.com/Digital%20First%20Careers/_apis/build/status/DFC%20Shared/dfc-shared?branchName=master)](https://sfa-gov-uk.visualstudio.com/Digital%20First%20Careers/_build/latest?definitionId=1131)

Repository with all the shared Azure resources used across the DFC services.
Each environment (DEV, LAB, SIT, PP and PRD) will have its own shared resources.

Deployed using the comnbination of a template file and a parameters file.

Two parameters files must be maintained:
    * [parameters.json](parameters.json) is used in the Azure DevOps pipeline and has tokenized values managed within Azure DevOps.
    * [test-parameters.json](test-parameters.json) for local and test deployment.

To test the deployment without APIM, set the parameter 'apimExists' to false and do not pass a value for the parameter 'certificates'