-- ============================================
-- Insights Performance Indexes - Test Script
-- IN-11910: Performance Issue - Heavy SQL Operations
-- ============================================
-- This script creates optimized composite indexes to address:
-- 1. SORT bottleneck (80% of query time)
-- 2. Missing JOIN indexes for one-to-many relationships
-- ============================================
-- NOTE: Connect directly to Insights database (USE statement not supported in Azure SQL)
-- ============================================

PRINT 'Dropping old indexes that need to be recreated...'
PRINT ''

-- Drop old Jobs index (was keyed on StartTime, now replaced by CreationTime)
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Jobs_TenantKey_StartTime' AND object_id = OBJECT_ID('[read].[Jobs]'))
BEGIN
    DROP INDEX [IX_Jobs_TenantKey_StartTime] ON [read].[Jobs];
    PRINT '   Dropped IX_Jobs_TenantKey_StartTime.'
END
GO

-- Drop old RobotLogs index (INCLUDE columns changed: removed Level, RobotName, ProcessName)
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RobotLogs_TenantKey_Timestamp' AND object_id = OBJECT_ID('[read].[RobotLogs]'))
BEGIN
    DROP INDEX [IX_RobotLogs_TenantKey_Timestamp] ON [read].[RobotLogs];
    PRINT '   Dropped IX_RobotLogs_TenantKey_Timestamp.'
END
GO

PRINT ''
PRINT 'Starting index creation...'
PRINT ''

-- ============================================
-- 1. Jobs - Composite Index (TenantKey + CreationTime DESC)
-- ============================================
PRINT '1. Creating IX_Jobs_TenantKey_CreationTime...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Jobs_TenantKey_CreationTime' AND object_id = OBJECT_ID('[read].[Jobs]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Jobs_TenantKey_CreationTime]
    ON [read].[Jobs] ([TenantKey], [CreationTime] DESC)
    INCLUDE ([JobKey], [EndTime], [ProcessName]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 2. JobEvents - Composite Index (TenantKey + Timestamp DESC)
-- ============================================
PRINT '2. Creating IX_JobEvents_TenantKey_Timestamp...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_JobEvents_TenantKey_Timestamp' AND object_id = OBJECT_ID('[read].[JobEvents]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_JobEvents_TenantKey_Timestamp]
    ON [read].[JobEvents] ([TenantKey], [Timestamp] DESC)
    INCLUDE ([JobId], [JobState], [Action]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 3. QueueItems - Composite Index (TenantKey + CreationTime DESC)
-- ============================================
PRINT '3. Creating IX_QueueItems_TenantKey_CreationTime...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_QueueItems_TenantKey_CreationTime' AND object_id = OBJECT_ID('[read].[QueueItems]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_QueueItems_TenantKey_CreationTime]
    ON [read].[QueueItems] ([TenantKey], [CreationTime] DESC)
    INCLUDE ([ProcessingStatus], [ExecutorJobId], [QueueName]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 4. QueueItems - JOIN Index (ExecutorJobId)
-- Used for: Jobs.JobId = QueueItems.ExecutorJobId
-- ============================================
PRINT '4. Creating IX_QueueItems_ExecutorJobId...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_QueueItems_ExecutorJobId' AND object_id = OBJECT_ID('[read].[QueueItems]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_QueueItems_ExecutorJobId]
    ON [read].[QueueItems] ([ExecutorJobId]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 5. QueueItemEvents - Composite Index (TenantKey + Timestamp DESC)
-- ============================================
PRINT '5. Creating IX_QueueItemEvents_TenantKey_Timestamp...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_QueueItemEvents_TenantKey_Timestamp' AND object_id = OBJECT_ID('[read].[QueueItemEvents]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_QueueItemEvents_TenantKey_Timestamp]
    ON [read].[QueueItemEvents] ([TenantKey], [Timestamp] DESC)
    INCLUDE ([QueueItemId], [Action], [ProcessingStatus]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 6. QueueItemEvents - JOIN Index (QueueItemId)
-- CRITICAL: Used for QueueItemsNew derived table self-join
-- ============================================
PRINT '6. Creating IX_QueueItemEvents_QueueItemId...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_QueueItemEvents_QueueItemId' AND object_id = OBJECT_ID('[read].[QueueItemEvents]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_QueueItemEvents_QueueItemId]
    ON [read].[QueueItemEvents] ([QueueItemId]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 7. RobotLogs - Composite Index (TenantKey + Timestamp DESC)
-- ============================================
PRINT '7. Creating IX_RobotLogs_TenantKey_Timestamp...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RobotLogs_TenantKey_Timestamp' AND object_id = OBJECT_ID('[read].[RobotLogs]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RobotLogs_TenantKey_Timestamp]
    ON [read].[RobotLogs] ([TenantKey], [Timestamp] DESC)
    INCLUDE ([JobKey]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

-- ============================================
-- 8. RobotLogs - JOIN Index (JobKey)
-- CRITICAL: Used for Jobs -> RobotLogs one-to-many JOIN
-- ============================================
PRINT '8. Creating IX_RobotLogs_JobKey...'
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RobotLogs_JobKey' AND object_id = OBJECT_ID('[read].[RobotLogs]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RobotLogs_JobKey]
    ON [read].[RobotLogs] ([JobKey]);
    PRINT '   Created successfully.'
END
ELSE
    PRINT '   Already exists, skipped.'
GO

PRINT ''
PRINT '============================================'
PRINT 'Index creation completed!'
PRINT '============================================'
PRINT ''

-- ============================================
-- Verify created indexes
-- ============================================
PRINT 'Verifying indexes...'
SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    STUFF((
        SELECT ', ' + c.name + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS KeyColumns,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS IncludedColumns
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'read'
    AND i.name LIKE 'IX_%'
    AND i.name IN (
        'IX_Jobs_TenantKey_CreationTime',
        'IX_JobEvents_TenantKey_Timestamp',
        'IX_QueueItems_TenantKey_CreationTime',
        'IX_QueueItems_ExecutorJobId',
        'IX_QueueItemEvents_TenantKey_Timestamp',
        'IX_QueueItemEvents_QueueItemId',
        'IX_RobotLogs_TenantKey_Timestamp',
        'IX_RobotLogs_JobKey'
    )
ORDER BY t.name, i.name;
GO
