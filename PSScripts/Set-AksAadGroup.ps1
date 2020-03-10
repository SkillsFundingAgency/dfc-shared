<#
.SYNOPSIS
Creates an AAD group, adds members and outputs the group's Object Id to be consumed by a later task that 

.DESCRIPTION
Creates an AAD group, adds members and outputs the group's Object Id to be consumed by a later task that.  Typically that task will create a group in Kubernetes that is mapped to the AAD group.

.PARAMETER AksAadGroupName
The name of the group to create.

.PARAMETER AddServicePrincipal
(optional) Add the Service Principal executing this script to the group.

.PARAMETER UsersToAdd
(optional) Users or Groups to add to the groups membership list
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$AksAadGroupName,
    [Parameter(Mandatory=$false)]
    [Switch]$AddServicePrincipal,
    [Parameter(Mandatory=$false)]
    [String[]]$UsersToAdd
)

$AksAadGroup = Get-AzAdGroup -DisplayName  $AksAadGroupName
if (!$AksAadGroup) {

    $MailNickname = $AksAadGroupName -replace " ", "-"
    $AksAadGroup = New-AzAdGroup -DisplayName $AksAadGroupName -MailNickname $MailNickname

}

Write-Verbose "Writing ObjectId $($AksAadGroup.Id) to variable AksAadGroupObjectId"
Write-Output "##vso[task.setvariable variable=AksAadGroupObjectId]$($AksAadGroup.Id)"

if ($AddServicePrincipal) {

    $Context = Get-AzContext
    $ServicePrincipal = Get-AzADServicePrincipal -ApplicationId $Context.Account.Id
    Write-Verbose "Adding Service Principal $($ServicePrincipal.Id) to group $($AksAadGroup.DisplayName)"
    $ExistingMember = Get-AzADGroupMember -GroupObjectId $AksAadGroup.Id | Where-Object { $_.Id -eq $ServicePrincipal.Id }
    if (!$ExistingMember) {

        Add-AzADGroupMember -MemberObjectId $ServicePrincipal.Id -TargetGroupObjectId $AksAadGroup.Id

    }
    Remove-Variable -Name ExistingMember

}


if ($UsersToAdd) {

    foreach ($UserId in $UsersToAdd) {

        $ExistingMember = Get-AzADGroupMember -GroupObjectId $AksAadGroup.Id | Where-Object { $_.Id -eq $UserId }
        if (!$ExistingMember) {

            Write-Verbose "Adding user $UserId to group $($AksAadGroup.DisplayName)"
            Add-AzADGroupMember -MemberObjectId $UserId -TargetGroupObjectId $AksAadGroup.Id

        }
        Remove-Variable -Name ExistingMember

    }

}