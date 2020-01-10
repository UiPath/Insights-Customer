Add-MpPreference -ExclusionPath "C:\Program Files\Sisense\" 
Add-MpPreference -ExclusionPath "C:\ProgramData\Sisense\"

# Sisense.Broker
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\infra\Rabbitmq\Sisense.AlertingMQ.exe"
# Sisense.CLRConnectorsContainer
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\DataConnectors\DotNetContainer\Sisense.Connectors.Container.Server.exe"
# Sisense.Collector
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\Infra\Data\Collector\Sisense.Collector.exe"
# Sisense.ECMLogs
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\Prism\ECMLogsPersistence\ECMLogsPersistenceService.exe"
# Sisense.ECMS
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\Prism\Server\ElastiCube.ManagementService.exe"
# Sisense.JVMConnectorsContainer
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\DataConnectors\JVMContainer\Sisense.JVMConnectorsContainer.exe"
# .HouseKeeper
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\infra\House-Keeper\Sisense.HouseKeeper.exe"
# .Oxygen
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\infra\Oxygen\Sisense.Oxygen.exe"
# .Repository
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\infra\MongoDB\Repository.Service.exe"
# .Shipper
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\Infra\Data\Shipper\Sisense.Shipper.exe"

# For Sisense.[] {Gateway Galaxy ECMServer Configuration Identity Intelligence Jobs Orchestrator Pivot2 Plugins QueryProxy SPE StorageManager Usage}
Add-MpPreference -ExclusionProcess "C:\Program Files\Sisense\app\*\Sisense.Service.exe" 