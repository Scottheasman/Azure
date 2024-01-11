<#PSScriptInfo
.VERSION 2024-01-05
.AUTHOR scott hesman
.COMPANYNAME 
.COPYRIGHT This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys` fees, that arise or result
from the use or distribution of the Sample Code..
.TAGS 
.DESCRIPTION 
List all Azure Subscriptions, and Management Groups.
Exports all the Assigned roles based on their possition of assignment. Root inherited, This Resource, Management Group Inherited, (showing the name og the Management group the inheritance came from.)
Export to Excel as an xlsx creating a table.
This can be imported to Powerbi for further slicing in dashboards.
#>
Connect-AzAccount

$subscriptions = $null
$subscription = $null
$roleAssignments = $null
$managementGroup = $null
$managementGroups = $null

$subscriptions = Get-AzSubscription | Where-Object { $_.Name -notlike '*Access to Azure Active Directory*' -and $_.Name -notlike '*sub-swx*' }
$managementGroups = Get-AzManagementGroup

# Get the current date
$currentDate = Get-Date

$roleAssignments = foreach ($subscription in $subscriptions) {
    Set-AzContext -Subscription $subscription | Out-Null
    Get-AzRoleAssignment | Select-Object DisplayName, SignInName, RoleDefinitionName, ObjectType, @{Name='SubscriptionName';Expression={$subscription.Name}}, @{Name='Management Group Name';Expression={'N/A'}},@{Name='Inherited';Expression={
        if ($_.Scope -eq "/") {"Root Inherited"}
        elseif ($_.Scope.StartsWith("/subscriptions/")) {"This Resource"}
        elseif ($_.Scope.StartsWith("/providers/Microsoft.Management/")) {$_.Scope.Split("/")[-1]}
        else {"Unknown"}
    }}, @{Name='Date';Expression={$currentDate}}
}

$roleAssignments += foreach ($managementGroup in $managementGroups) {
    Set-AzContext -TenantId $managementGroup.TenantId | Out-Null
    Get-AzRoleAssignment -Scope $managementGroup.Id | Select-Object ID, DisplayName, SignInName, Name, RoleDefinitionName, ObjectType, @{Name='SubscriptionName';Expression={'N/A'}}, @{Name='Management Group Name';Expression={$ManagementGroup.DisplayName}}, @{Name='Inherited';Expression={
        if ($_.Scope -eq "/") {"Root Inherited"}
        elseif ($_.Scope.StartsWith($managementGroup.Id)) {"This Resource"}
        elseif ($_.Scope.StartsWith("/providers/Microsoft.Management/")) {$_.Scope.Split("/")[-1]}
        else {"Unknown"}
    }}, @{Name='ManagementGroupName';Expression={$managementGroup.DisplayName}}, @{Name='Date';Expression={$currentDate}}
}

$roleassignments | Export-Excel -Path "C:\Devops\powershell-scripts\Azure\RBAC\RbacPerms-$((Get-Date).ToString('MM-dd-yyyy')).xlsx" -WorksheetName "rbac" -TableStyle "Medium2"
Copy-Item -Path "C:\Devops\powershell-scripts\Azure\RBAC\RbacPerms-$((Get-Date).ToString('MM-dd-yyyy')).xlsx" -Destination "C:\Devops\powershell-scripts\Azure\RBAC\RbacPerms.xlsx"
