with CTE as (
select qie.[JobOrgUnitFullyQualifiedName] as qOrgName, qie.[JobOrganizationUnitId] as qOrgId, j.[OrganizationUnitId] as jOrgId, j.[OrgUnitFullyQualifiedName] as jOrgName
from [dbo].[QueueItemEvents] qie 
inner join [dbo].[QueueItems] qi on qie.[QueueItemId] = qi.[Id]
inner join [dbo].[Jobs] j on qi.[ExecutorJobId] = j.[Id]
where j.[OrganizationUnitId] != qie.[JobOrganizationUnitId] or (qie.[JobOrganizationUnitId] is null and j.[OrganizationUnitId] is not null))
update CTE
set qOrgName = jOrgName, qOrgId = jOrgId;