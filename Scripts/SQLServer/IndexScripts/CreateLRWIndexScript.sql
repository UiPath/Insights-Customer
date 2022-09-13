IF NOT EXISTS(SELECT * FROM sys.indexes WHERE Name = 'IX_JobEvents_JobId_TenantId' and OBJECT_NAME(object_id) = 'JobEvents')
CREATE NONCLUSTERED INDEX [IX_JobEvents_JobId_TenantId] ON [dbo].[JobEvents]
(
	[JobId] ASC,
	[TenantId] ASC
)