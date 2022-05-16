IF NOT EXISTS (SELECT * FROM sysindexes WHERE id = object_id('dbo.QueueItemEvents') AND NAME = 'TenantId_ProceStatus_QI_INDEX')
  CREATE NONCLUSTERED INDEX [TenantId_ProceStatus_QI_INDEX] ON dbo.QueueItemEvents (TenantId, ProcessingStatus) INCLUDE (QueueItemId);
