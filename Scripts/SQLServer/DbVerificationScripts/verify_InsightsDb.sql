/**
 * Copyright (c) UiPath Inc. All rights reserved.
 *
 * Instructions:
 *   1. Subsitute the placeholder "Insights_DB_name" with the actual name of your Insights database.
 *   2. Execute the script and share the output with the Insights team.
 */

BEGIN
	USE Insights_DB_name; -- Replace "Insights_DB_name" with the name of your Insights DB.
	
	SELECT TOP 1 MigrationId, ContextKey
		FROM dbo.__MigrationHistory
		ORDER BY MigrationId DESC;

	SELECT * FROM dbo.Tenants;

	DECLARE @nJobs INT = (SELECT COUNT(*) FROM (
		SELECT
			Id, TenantId, CreationTime, StartTime, EndTime, JobKey,
			JobSource, EnvName, NULL AS OrgUnitCode, OrgUnitName,
			OrganizationUnitId, ProcessName, DisplayName,
			OrgUnitFullyQualifiedName, RuntimeType
		FROM dbo.Jobs) AS Tmp);

	DECLARE @nJobEvents INT = (SELECT COUNT(*) FROM (
		SELECT
			Id, TenantId, ProcessVersion, RobotName, RobotType,
			HostMachineName, JobId, TimeStamp, Action, JobState,
			UserName, RuntimeType
		FROM dbo.JobEvents) AS Tmp);

	DECLARE @nQueueItems INT = (SELECT COUNT(*) FROM (
		SELECT
			Id, TenantId, Priority, QueueName, ProcessingStatus,
			ReviewStatus, RobotName, RobotType, CreationTime,
			StartProcessing, EndProcessing, CreatorJobId, ExecutorJobId,
			SecondsInPreviousAttempts, AncestorId, RetryNumber,
			DeferDate, DueDate, Progress, SpecificData, AnalyticsData,
			Output, ProcessingExceptionType, ProcessingExceptionReason,
			Reference, ReviewerUserName, OrgUnitCode, OrgUnitName,
			OrganizationUnitId, OrgUnitFullyQualifiedName,
			ProcessingExceptionDetails
		FROM dbo.QueueItems) AS Tmp);

	DECLARE @nQueueItemEvents INT = (SELECT COUNT(*) FROM (
		SELECT
			Id, TenantId, QueueItemId, TimeStamp, Action, UserName,
			ProcessingStatus, QueueDefinitionId,
			JobOrgUnitFullyQualifiedName, JobOrganizationUnitId
		FROM dbo.QueueItemEvents) AS Tmp);

	DECLARE @nRobotLogs INT = (SELECT COUNT(*) FROM(
		SELECT
			Id, TenantId, OrganizationUnitId, TimeStamp, JobKey,
			MachineId, ProcessName, WindowsIdentity, RobotName,
			RawMessage, Message, LevelOrdinal
		FROM dbo.RobotLogs) AS Tmp);

	DECLARE @nInvalidJobs INT = (SELECT COUNT(*) FROM dbo.Jobs WHERE ID < 0);
	DECLARE @nInvalidJobEvents INT = (SELECT COUNT(*) FROM dbo.JobEvents WHERE ID < 0);
	DECLARE @nInvalidQueueItems INT = (SELECT COUNT(*) FROM dbo.QueueItems WHERE ID < 0);
	DECLARE @nInvalidQueueItemEvents INT = (SELECT COUNT(*) FROM dbo.QueueItemEvents WHERE ID < 0);
	DECLARE @nInvalidRobotLogs INT = (SELECT COUNT(*) FROM dbo.RobotLogs WHERE ID < 0);

	SELECT 'Jobs' AS TableName, @nJobs AS Valid, @nInvalidJobs AS Invalid
		UNION ALL SELECT 'JobEvents', @nJobEvents, @nInvalidJobEvents
		UNION ALL SELECT 'QueueItems', @nQueueItems, @nInvalidQueueItems
		UNION ALL SELECT 'QueueItemEvents', @nQueueItemEvents, @nInvalidQueueItemEvents
		UNION ALL SELECT 'RobotLogs', @nRobotLogs, @nInvalidRobotLogs;
END
;
