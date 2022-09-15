-- 1.backfill JobOrganizationUnitId
with CTE as (
select qie.[JobOrgUnitFullyQualifiedName] as qOrgName, qie.[JobOrganizationUnitId] as qOrgId, j.[OrganizationUnitId] as jOrgId, j.[OrgUnitFullyQualifiedName] as jOrgName
from [dbo].[QueueItemEvents] qie 
inner join [dbo].[QueueItems] qi on qie.[QueueItemId] = qi.[Id]
inner join [dbo].[Jobs] j on qi.[ExecutorJobId] = j.[Id]
where j.[OrganizationUnitId] != qie.[JobOrganizationUnitId] or (qie.[JobOrganizationUnitId] is null and j.[OrganizationUnitId] is not null))
update CTE
set qOrgName = jOrgName, qOrgId = jOrgId;

-- 2.create LRW index if it does not exist
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE Name = 'IX_JobEvents_JobId_TenantId' and OBJECT_NAME(object_id) = 'JobEvents')
CREATE NONCLUSTERED INDEX [IX_JobEvents_JobId_TenantId] ON [dbo].[JobEvents]
(
	[JobId] ASC,
	[TenantId] ASC
)

-- 3.truncate read table
truncate table [read].[QueueItemEvents];
truncate table [read].[QueueItems];
truncate table [read].[Jobs];
truncate table [read].[JobEvents];
delete [dbo].[IngestionMarkers] where [IngestionEventType] in (9002, 9001);