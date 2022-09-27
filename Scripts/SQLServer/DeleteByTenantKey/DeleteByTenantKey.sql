DECLARE @tenantKey VARCHAR(128);
DECLARE @tenantId int;
SET @tenantKey = '341055E5-B0D1-403C-A7B0-ADF6BB66B75C'; --replace with tenantKey from dbo.tenants
SET @tenantId = (select id from [dbo].[Tenants] where [key] = @tenantKey);

delete from [dbo].[JobEvents] where TenantKey = @tenantKey;
delete from [dbo].[Jobs] where TenantKey = @tenantKey;
delete from [dbo].[QueueItemEvents] where TenantKey = @tenantKey;
delete from [dbo].[QueueItems] where TenantKey = @tenantKey;
delete from [dbo].[QUEUEMETADATA] where TenantKey = @tenantKey;
delete from [dbo].[PROCESSMETADATA] where TenantKey = @tenantKey;
delete from [dbo].[RobotLogs] where TenantId = @tenantId;
delete from [read].[QueueDynamicJsonMetadata] where TenantKey = @tenantKey;
delete from [read].[RobotDynamicJsonMetadata] where TenantKey = @tenantKey;