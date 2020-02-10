param(
   [Parameter(Mandatory=$true)][string]$username
  ,[Parameter(Mandatory=$true)][string]$password
)

$insightsAdminToolPath = "${Env:ProgramFiles(x86)}\UiPath\Orchestrator\Tools"
$uifrostPath = "${Env:ProgramFiles}\Sisense\DataConnectors\JVMContainer\Connectors\UiFrost"

function Get-CheckBuild($tenant)
{
	$cubeBuilding = 1
	while ($cubeBuilding -ne 0)
	{
		$buildResult = & "$insightsAdminToolPath\UiPath.InsightsAdminTool.exe" buildStatus -t $tenant | out-string
		$buildStatus = $buildResult.Split(“`n”)

		if($buildStatus[1].StartsWith("Build successfully ended"))
		{
			$cubeBuilding = 0;
		}
		elseif ($cubeBuilding -eq 180)
		{
			throw 'Cube is still building after 30m. Please execute script during downtime.'
		}
		else
		{
			Write-Output "$tenant Cube is still building. Waiting..."
			Start-Sleep -s 10
			$cubeBuilding++
		}
	}
}

Write-Output "Copying .jar"
Copy-Item com.sisense.connectors.jdbc.UiFrost.jar -Destination "$uifrostPath\com.sisense.connectors.jdbc.UiFrost.jar" -Recurse -force

Write-Output "Getting list of tenants"
$listTenants = & "$insightsAdminToolPath\UiPath.InsightsAdminTool.exe" list -u $username -p $password | out-string
$tenantArray = $listTenants.Split(“`n”)

Write-Output "Starting cube rebuilds"
foreach ($row in $tenantArray)
{
    #Iterate and find tenants that have Insights enabled and do a full rebuild
    if($row -match 'tenant (?<Tenant>.+) with insights ENABLED')
    {        
        $tenant =   $Matches.Tenant        
        Get-CheckBuild $tenant        
        Write-Output "Triggered $tenant cube rebuild"
        & "$insightsAdminToolPath\UiPath.InsightsAdminTool.exe" rebuild -t $tenant | out-null        
        Get-CheckBuild $tenant        
        Write-Output "$tenant cube is rebuilt"
    }    
}
Write-Output "Restarting Sisense.JVMConnectorsContainer Service"
Restart-Service -Name Sisense.JVMConnectorsContainer -Force
Write-Output "Restarted Sisense.JVMConnectorsContainer Service"

Write-Output "UTC fix applied"