# CheckEntraGroupAssignments
Auditing assignments of Intune policies, apps, profiles and more for Entra groups

I found a great script from Timmy Andersson for auditing assignments of Intune policies, apps, profiles and more for Entra groups. The original script by Timmy you find here: https://timmyit.com/2023/10/09/get-all-assigned-intune-policies-and-apps-from-a-microsoft-entra-group/.

Managing devices and applications in Microsoft Intune often involves assigning policies, applications, and configurations to Azure AD groups. However, keeping track of these assignments can be challenging, especially in large environments.

To solve this, I modified the PowerShell script from Timmy to audit all policies, apps, configurations, and compliance settings assigned to a specific Entra group. I made a few small adjustments: The script now prompts for the group name in the console, lists all parent groups of the selected group, and at the end, asks whether another group should be checked.

This script provides a clear overview, ensuring better visibility and management.
