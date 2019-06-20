[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment
)

$env:ApimExists = $null -ne (Get-AzureRmApiManagement -ResourceGroupName "dfc-$Environment-shared-rg" -Name "dfc-$Environment-shared-apim" -ErrorAction Ignore)