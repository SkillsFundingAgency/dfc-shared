<#
.SYNOPSIS
Adds a Certificate Authority to an Azure KeyVault if it doesn't exist and sets the password.

.DESCRIPTION
Adds a Certificate Authority to an Azure KeyVault if it doesn't exist and sets the password.  The account or service principal executing the script will require SetIssuers, GetIssuers & ListIssuers on the KeyVault.

.PARAMETER AdministratorPhoneNumber
A phone number for the administrator, this is an enforced requirement of Set-AzKeyVaultCertificateIssuer

.PARAMETER CertificateIssuerAccountId
The DigiCert account id assigned to careersdeveops@education.gov.uk

.PARAMETER CertificateIssuerPassword
The password for the DigiCert account registered to careersdeveops@education.gov.uk

.PARAMETER KeyVaultName
The name of the KeyVault to add the CA to
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]    
    [String]$AdministratorPhoneNumber,
    [Parameter(Mandatory=$true)]
    [String]$CertificateIssuerAccountId,
    [Parameter(Mandatory=$true)]
    [String]$CertificateIssuerPassword,    
    [Parameter(Mandatory=$true)]
    [String]$KeyVaultName
)

$AdminDetails = New-AzKeyVaultCertificateAdministratorDetails -FirstName Careers -LastName Keyvault -EmailAddress "careersdeveops@education.gov.uk" -PhoneNumber $AdministratorPhoneNumber
$OrgDetails = New-AzKeyVaultCertificateOrganizationDetails -AdministratorDetails $AdminDetails
$SecurePassword = ConvertTo-SecureString -String $CertificateIssuerPassword -AsPlainText -Force
Set-AzKeyVaultCertificateIssuer -VaultName $KeyVaultName -Name "DigiCert" -IssuerProvider "DigiCert" -AccountId $CertificateIssuerAccountId -ApiKey $SecurePassword -OrganizationDetails $OrgDetails -PassThru
