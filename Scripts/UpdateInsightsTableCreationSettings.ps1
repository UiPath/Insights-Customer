<# 
.SYNOPSIS 
Script that enables/disables per process/queue table creation for UiPath Insights.
#>
param(
  [Parameter(Mandatory=$true)][string]$server # Orchestrator endpoint
  ,[Parameter(Mandatory=$true)][string]$tenancyName # Tenant name
  ,[Parameter(Mandatory=$true)][string]$user # Tenant user name
  ,[secureString]$password = $(Read-Host -Prompt "Enter password" -AsSecureString) # Tenant user password (prompted)
  ,[boolean]$perProcessTablesEnabled = $true # Boolean to enable/disable process tables
  ,[boolean]$perQueueTablesEnabled = $true # Boolean to enable/disable queue tables
)

$credentials = New-Object System.Management.Automation.PSCredential `
  -ArgumentList $user, $password

# Base headers
$headers = @{
  'Accept' = 'application/json'
  'Content-Type' = 'application/json'
}

$body = "{ 
  `"tenancyName`": `"$tenancyName`",
  `"usernameOrEmailAddress`":
  `"$($credentials.GetNetworkCredential().UserName)`",
  `"password`": `"$($credentials.GetNetworkCredential().Password)`"
}"

$targetUri = "$server/api/Account/Authenticate"

# Authenticate with the given tenant.
$authResult = Invoke-RestMethod -Method Post -Uri $targetUri -Headers $headers -Body $body

if ($null -eq $authResult -or $null -eq $authResult.result) {
  Write-Output "Could not authenticate, exiting."
  exit 1
}

$authToken = $authResult.result
$headers.Add('Authorization', "Bearer $authToken")

$targetUri = "$server/odata/Settings/UiPath.Server.Configuration.OData.UpdateBulk"

# Settings definition, if not specified from command line arguments these will be set to true.
$body = "
{ 
  `"settings`": [ 
    { 
      `"Name`": `"Insights.PerProcessTables`",
      `"Value`": `"$perProcessTablesEnabled`",
      `"Scope`": `"Tenant`"
    }, 
    { 
      `"Name`": `"Insights.PerQueueTables`",
      `"Value`": `"$perQueueTablesEnabled`",
      `"Scope`": `"Tenant`"
    }
  ]
}"

# Update settings.
Invoke-RestMethod -Method Post -Uri $targetUri -Headers $headers -Body $body