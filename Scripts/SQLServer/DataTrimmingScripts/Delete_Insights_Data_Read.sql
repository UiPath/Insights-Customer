SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [read].[Delete_Insights_Data_Read]
AS
BEGIN
	IF IS_SRVROLEMEMBER('sysadmin') != 1
	BEGIN
		PRINT('Failed to execute the script! Current user doesn''t own sysadmin role.')
    	RETURN;
	END;

	-- rename all read tables
	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'Jobs')
	BEGIN
	exec sp_rename 'read.Jobs', 'Jobs_Temp';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'JobEvents')
	BEGIN
	exec sp_rename 'read.JobEvents', 'JobEvents_Temp';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'QueueItems')
	BEGIN
	exec sp_rename 'read.QueueItems', 'QueueItems_Temp';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'QueueItemEvents')
	BEGIN
	exec sp_rename 'read.QueueItemEvents', 'QueueItemEvents_Temp';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'RobotLogs')
	BEGIN
	exec sp_rename 'read.RobotLogs', 'RobotLogs_Temp';
	END;

	-- kill all of running Migrate Data SPs
	DECLARE @command NVARCHAR(MAX);

	WHILE EXISTS (SELECT session_id 
			  FROM sys.dm_exec_requests handle OUTER APPLY sys.fn_get_sql(handle.sql_handle) spname  
			  WHERE (spname.text LIKE '%MigrateJobs%' OR spname.text LIKE '%MigrateQueueItems%' OR spname.text LIKE '%MigrateRobotLogs%')
			  AND spname.text NOT LIKE '%sys.dm_exec_requests%')
    BEGIN
		SELECT @command = STRING_AGG(CONCAT ('KILL ', session_id), ' ')  
		FROM sys.dm_exec_requests handle OUTER APPLY sys.fn_get_sql(handle.sql_handle) spname  
		WHERE (spname.text LIKE '%MigrateJobs%' OR spname.text LIKE '%MigrateQueueItems%' OR spname.text LIKE '%MigrateRobotLogs%')
		AND spname.text NOT LIKE '%sys.dm_exec_requests%';

    	EXEC (@command);
	-- Aborted SP will be retried, wait 3 seconds and kill the process again. 
		WAITFOR DELAY '00:00:03';
    END;

	-- truncate all temp tables and change the tables to their original names
	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'Jobs_Temp')
	BEGIN
	TRUNCATE TABLE [read].[Jobs_Temp];
	exec sp_rename 'read.Jobs_Temp', 'Jobs';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'JobEvents_Temp')
	BEGIN
	TRUNCATE TABLE [read].[JobEvents_Temp];
	exec sp_rename 'read.JobEvents_Temp', 'JobEvents';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'QueueItems_Temp')
	BEGIN
	TRUNCATE TABLE [read].[QueueItems_Temp];
	exec sp_rename 'read.QueueItems_Temp', 'QueueItems';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'QueueItemEvents_Temp')
	BEGIN
	TRUNCATE TABLE [read].[QueueItemEvents_Temp];
	exec sp_rename 'read.QueueItemEvents_Temp', 'QueueItemEvents';
	END;

	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'RobotLogs_Temp')
	BEGIN
	TRUNCATE TABLE [read].[RobotLogs_Temp];
	exec sp_rename 'read.RobotLogs_Temp', 'RobotLogs';
	END;

	-- rebuild all Dynamic Json tables
	UPDATE [read].[JsonSettings]
	SET DdlOperationPerformed = 0, LastUpdatedTime = GETUTCDATE()
	WHERE Enabled = 1;

    PRINT('The script executed successfully!');

END;
GO
