param(
   [Parameter(Mandatory=$true)][string]$username
  ,[Parameter(Mandatory=$true)][string]$password
)

function Get-checkBuild($tenant)
{
        $cubeBuilding = 0
        while ($cubeBuilding -ne 1)
        {
            $buildResult = & "C:\Program Files (x86)\UiPath\Orchestrator\Tools\UiPath.InsightsAdminTool.exe" buildStatus -t $tenant | out-string
            $buildStatus = $buildResult.Split(“`n”)

            if($buildStatus[1].StartsWith("Build successfully ended"))
            {
                $cubeBuilding = 1;
            }
            else
            {
                Write-Output "$tenant Cube is still building. Waiting..."
                Start-Sleep -s 10
            }
        }

}

Write-Output "Copying .jar"
Copy-Item test.txt -Destination "C:\Program Files\Sisense\DataConnectors\JVMContainer\Connectors\UiFrost\com.sisense.connectors.jdbc.UiFrost.jar" -Recurse -force


Write-Output "Getting list of tenants"
$listTenants = & "C:\Program Files (x86)\UiPath\Orchestrator\Tools\UiPath.InsightsAdminTool.exe" list -u $username -p $password | out-string
$tenantArray = $listTenants.Split(“`n”)

Write-Output "Starting cube rebuilds"
foreach ($row in $tenantArray)
{
    if($row -match 'tenant (?<Tenant>.+) with insights ENABLED')
    {        
        $tenant =   $Matches.Tenant        
        Get-checkBuild $tenant        
        Write-Output "Triggered $tenant cube rebuild"
        & "C:\Program Files (x86)\UiPath\Orchestrator\Tools\UiPath.InsightsAdminTool.exe" rebuild -t $tenant | out-null        
        Get-checkBuild $tenant        
        Write-Output "$tenant cube is rebuilt"
    }
    
}
Write-Output "Restarting Sisense.JVMConnectorsContainer Service"
Restart-Service -Name Sisense.JVMConnectorsContainer -Force
Write-Output "Restarted Sisense.JVMConnectorsContainer Service"

