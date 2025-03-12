<# 

Origin author: Timmy Andersson
Origin URL: https://timmyit.com/2023/10/09/get-all-assigned-intune-policies-and-apps-from-a-microsoft-entra-group/
Modified by: Matthias Langenhoff
URL: https://cmdctrl4u.wordpress.com
GitHub: https://github.com/cmdctrl4u
Date: 2025-11-03
Version: 1.0

Description: This script checks the assignments of the following objects to a specific Azure AD group:

- Device Compliance Policies
- Applications
- Application Configurations (App Configs)
- App protection policies
- Device Configuration
- Remediation scripts
- Platform Scrips / Device Management
- Windows Autopilot profiles
- Parent groups

The script uses the Microsoft Graph PowerShell SDK to query the Microsoft Graph API.
The script is based on the following Microsoft Graph API documentation: https://docs.microsoft.com/en-us/graph/api/resources/intune-devices-devicemanagementdevicehealthscript?view=graph-rest-beta

#>

# Check and install required modules
function Ensure-ModuleInstalled {
  param (
      [string]$ModuleName
  )
  if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
      Write-Host "Install module: $ModuleName" -ForegroundColor Cyan
      Install-Module -Name $ModuleName -Force -AllowClobber
  } else {
      Write-Host "Module already installed: $ModuleName" -ForegroundColor Green
  }
}

# Check and import modules
function Ensure-ModuleImported {
  param (
      [string]$ModuleName
  )
  if (-not (Get-Module -Name $ModuleName)) {
      Write-Host "Import module: $ModuleName" -ForegroundColor Cyan
      Import-Module -Name $ModuleName
  } else {
      Write-Host "Module already imported: $ModuleName" -ForegroundColor Green
  }
}

# Check if the module is installed
Ensure-ModuleInstalled -ModuleName "Microsoft.Graph.DeviceManagement"
Ensure-ModuleInstalled -ModuleName "Microsoft.Graph.Groups"

# Check if the module is imported
Ensure-ModuleImported -ModuleName "Microsoft.Graph.DeviceManagement"
Ensure-ModuleImported -ModuleName "Microsoft.Graph.Groups"

# Connect to Microsoft Graph
Connect-MgGraph -scopes Group.Read.All, DeviceManagementManagedDevices.Read.All, DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All, DeviceManagementApps.Read.All, DeviceManagementConfiguration.Read.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementApps.ReadWrite.All -ContextScope Process

# Main

do {

# Get Azure AD Group
$groupName = Read-Host "Please enter the name of the Azure AD group you want to check"
 
$Group = Get-MgGroup -Filter "DisplayName eq '$groupName'"


#----------------------------------------- Device Compliance Policy -----------------------------------------#
# Get all Device Compliance Policies assigned to the group

if ($null -eq $Group) {
  Write-Host "Group '$groupName' not found." -ForegroundColor Red
  return
  exit 0
}
 
$Resource = "deviceManagement/deviceCompliancePolicies"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AllDCPId = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.target.groupId -match $Group.id}
 
Write-host "The following Device Compliance Policies has been assigned to: $($Group.DisplayName)" -ForegroundColor Cyan
 
foreach ($DCPId in $AllDCPId) {
 
  Write-host "$($DCPId.DisplayName)" -ForegroundColor Yellow
}

 
#------------------------------------------------------ Applications ------------------------------------------------------#
# Get all Applications assigned to the group
 
$Resource = "deviceAppManagement/mobileApps"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Apps = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.target.groupId -match $Group.id}
 
Write-host "Following Apps has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  
foreach ($App in $Apps) {
 
  Write-host "$($App.DisplayName)" -ForegroundColor Yellow 
}
 
 
#--------------------------------------------------- Application Configurations (App Configs) -------------------------------------------#
# Get all Application Configurations assigned to the group 
 
$Resource = "deviceAppManagement/targetedManagedAppConfigurations"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$AppConfigs = (Invoke-MgGraphRequest -Method GET -Uri $uri).Value | Where-Object {$_.assignments.target.groupId -match $Group.id}
 
Write-host "Following App Configuration has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  
foreach ($AppConfig in $AppConfigs) {
 
  Write-host "$($AppConfig.DisplayName)" -ForegroundColor Yellow
}
 

#-------------------------------------------------------- App protection policies ---------------------------------------------------#
# Get all App protection policies assigned to the group 
 
$AppProtURIs = @{
    iosManagedAppProtections = "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections?`$expand=Assignments"
    androidManagedAppProtections = "https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections?`$expand=Assignments"
    windowsManagedAppProtections = "https://graph.microsoft.com/beta/deviceAppManagement/windowsManagedAppProtections?`$expand=Assignments"
    mdmWindowsInformationProtectionPolicies = "https://graph.microsoft.com/beta/deviceAppManagement/mdmWindowsInformationProtectionPolicies?`$expand=Assignments"
  }
 
$graphApiVersion = "Beta"
 
$AllAppProt = $null
foreach ($url in $AppProtURIs.GetEnumerator()) {
 
 
 $AllAppProt = (Invoke-MgGraphRequest -Method GET -Uri $url.value).Value | Where-Object {$_.assignments.target.groupId -match $Group.id} -ErrorAction SilentlyContinue
  Write-host "Following App Protection / "$($url.name)" has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  foreach ($AppProt in $AllAppProt) {
 
    Write-host "$($AppProt.DisplayName)" -ForegroundColor Yellow    
  }
  } 
 

#------------------------------------------------------------ Device Configuration ---------------------------------------------------#
# Get all Device Configurations assigned to the group
 
$DCURIs = @{
    ConfigurationPolicies = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$expand=Assignments"
    DeviceConfigurations = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$expand=Assignments"
    GroupPolicyConfigurations = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?`$expand=Assignments"
    mobileAppConfigurations = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppConfigurations?`$expand=Assignments"
  }
   
$AllDC = $null
foreach ($url in $DCURIs.GetEnumerator()) {
 
 
  $AllDC = (Invoke-MgGraphRequest -Method GET -Uri $url.value).Value | Where-Object {$_.assignments.target.groupId -match $Group.id} -ErrorAction SilentlyContinue
  Write-host "Following Device Configuration / "$($url.name)" has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  foreach ($DCs in $AllDC) {
 
    #If statement because ConfigurationPolicies does not contain DisplayName. 
      if ($($DCs.displayName -ne $null)) { 
       
      Write-host "$($DCs.DisplayName)" -ForegroundColor Yellow
      } 
      else {
        Write-host "$($DCs.Name)" -ForegroundColor Yellow
      } 
  }
  } 
 

#----------------------------------------------------------------- Remediation scripts ---------------------------------------------------#
# Get all Remediation scripts assigned to the group 
 
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
$REMSC = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllREMSC = $REMSC.value 
Write-host "Following Remediation Script has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
  
foreach ($Script in $AllREMSC) {
 
$SCRIPTAS = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts/$($Script.Id)/assignments").value 
 
  if ($SCRIPTAS.target.groupId -match $Group.Id) {
  Write-host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
}
 
 
#-------------------------------------------------- Platform Scrips / Device Management ---------------------------------------------------#
# Get all Platform Scrips / Device Management scripts assigned to the group
 
$Resource = "deviceManagement/deviceManagementScripts"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
$PSSC = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllPSSC = $PSSC.value
Write-host "Following Platform Scripts / Device Management scripts has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
 
foreach ($Script in $AllPSSC) {
   
$SCRIPTAS = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($Script.Id)/assignments").value 
 
  if ($SCRIPTAS.target.groupId -match $Group.Id) {
  Write-host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
}
 

#----------------------------------------------------------- Windows Autopilot profiles ---------------------------------------------------#
# Get all Windows Autopilot profiles assigned to the group
 
$Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=Assignments"
$Response = Invoke-MgGraphRequest -Method GET -Uri $uri
$AllObjects = $Response.value
Write-host "Following Autopilot Profiles has been assigned to: $($Group.DisplayName)" -ForegroundColor cyan
 
foreach ($Script in $AllObjects) {
   
$APProfile = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/$($Script.Id)/assignments").value 
 
  if ($APProfile.target.groupId -match $Group.Id) {
  Write-host "$($Script.DisplayName)" -ForegroundColor Yellow
  }
}


#--------------------------------------------------- Group is member of ---------------------------------------------------#
# Get all parent groups of the group

$GroupIdString = $Group.Id.ToString()

$Resource = "groups"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$($groupIDString)/memberOf"
$MemberOf = Invoke-MgGraphRequest -Method GET -Uri $uri

if ($null -ne $MemberOf) {
  $AllMemberOf = $MemberOf.value
  Write-Host "Following parent groups have been found for group: $($Group.DisplayName)" -ForegroundColor Cyan

  foreach ($parentGroup in $AllMemberOf) {
      Write-Host "$($parentGroup.displayName)" -ForegroundColor Yellow
  }
} else {
  Write-Host "No parent groups found or an error occurred." -ForegroundColor Red
}


# Should the script be repeated?
  $repeat = Read-Host "Do you want to check another group? (Y/N)"

}while ($repeat -match '^(Y(es)?)$')
 
Disconnect-Graph
