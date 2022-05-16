IF NOT EXISTS(SELECT * FROM sys.indexes WHERE Name = 'IX_TenantId_ProcessName' and OBJECT_NAME(object_id) = 'RobotLogs')
	CREATE NONCLUSTERED INDEX [IX_TenantId_ProcessName] ON [dbo].[RobotLogs]
	(
		[TenantId] ASC,
		[ProcessName] ASC
	)
