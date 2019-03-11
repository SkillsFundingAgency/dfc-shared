[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment
)

$ApimExists = $null -ne (Get-AzureRmApiManagement -ResourceGroupName "dss-$Environment-shared-rg" -Name "dss-$Environment-shared-apim" -ErrorAction Ignore)
Write-Verbose "Writing value $ApimExists to variable ApimExists"
Write-Output "##vso[task.setvariable variable=ApimExists]$ApimExists"