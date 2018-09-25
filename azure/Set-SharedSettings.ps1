param (
    [Parameter(Mandatory=$true)][string]$KeyvaultName
)

Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyvaultName -ServicePrincipalName "abfa0a7c-a6b6-4736-8310-5855508787cd" -PermissionsToSecrets get -Verbose