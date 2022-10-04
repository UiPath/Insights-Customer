DECLARE @tenantKey VARCHAR(128);
DECLARE @tenantId int;
SET @tenantKey = '123e4567-e89b-12d3-a456-426652340000'; --replace with tenantKey from dbo.tenants
SET @tenantId = (select id from [dbo].[Tenants] where [key] = @tenantKey);

delete from [dbo].[JobEvents] where TenantKey = @tenantKey;
delete from [dbo].[Jobs] where TenantKey = @tenantKey;
delete from [dbo].[QueueItemEvents] where TenantKey = @tenantKey;
delete from [dbo].[QueueItems] where TenantKey = @tenantKey;
delete from [dbo].[RobotLogs] where TenantId = @tenantId;
delete from [read].[QueueDynamicJsonMetadata] where TenantKey = @tenantKey;
delete from [read].[RobotDynamicJsonMetadata] where TenantKey = @tenantKey;