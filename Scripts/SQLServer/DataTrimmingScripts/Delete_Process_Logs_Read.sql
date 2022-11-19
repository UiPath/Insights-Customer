SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [read].[Delete_Process_Logs_Read]
	@ProcessName NVARCHAR(128),
	@TenantId INT
AS
BEGIN
	IF IS_SRVROLEMEMBER('sysadmin') != 1
	BEGIN
		PRINT('Failed to execute the script! Current user doesn''t own sysadmin role.')
    	RETURN;
	END;

	DECLARE @topId INT = 0;

	SET @topId = (SELECT ISNULL((SELECT TOP(1) Id FROM [read].[RobotLogs] WHERE ProcessName = @ProcessName AND TenantId = @TenantId), 0));

	IF(@topId = 0)
    BEGIN
        PRINT('There''s no logs from this process! The script is exiting...');
	    RETURN;
    END;

	DECLARE @TenantKey NVARCHAR(128) = (SELECT [Key] FROM [dbo].[Tenants] WHERE Id = @TenantId);

    IF(@TenantKey IS NULL)
    BEGIN
        PRINT('TenantId does not exist! The script is exiting...');
        RETURN;
    END;

	-- rename RobotLog read table
	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'RobotLogs')
	BEGIN
	exec sp_rename 'read.RobotLogs', 'RobotLogs_Temp';
	END;

	-- kill all of running Migrate RobotLogs SPs
	DECLARE @command NVARCHAR(MAX);

	WHILE EXISTS (SELECT session_id 
			  FROM sys.dm_exec_requests handle OUTER APPLY sys.fn_get_sql(handle.sql_handle) spname  
			  WHERE spname.text LIKE '%MigrateRobotLogs%' AND spname.text NOT LIKE '%sys.dm_exec_requests%')
	BEGIN
		SELECT @command = STRING_AGG(CONCAT ('KILL ', session_id), ' ')  
		FROM sys.dm_exec_requests handle OUTER APPLY sys.fn_get_sql(handle.sql_handle) spname  
		WHERE spname.text LIKE '%MigrateRobotLogs%' AND spname.text NOT LIKE '%sys.dm_exec_requests%';

    	EXEC (@command);
	-- Aborted SP will be retried, wait 3 seconds and kill the process again. 
		WAITFOR DELAY '00:00:03';
	END;

	-- truncate read RobotLogs table and change it to the original name
	IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'read' AND TABLE_NAME = 'RobotLogs_Temp')
	BEGIN
	TRUNCATE TABLE [read].[RobotLogs_Temp];
	exec sp_rename 'read.RobotLogs_Temp', 'RobotLogs';
	END;

	-- rebuild impacted process table 
	UPDATE [read].[JsonSettings]
	SET DdlOperationPerformed = 0, LastUpdatedTime = GETUTCDATE()
	WHERE QueueJsonType IS NULL AND ObjectName = @ProcessName AND Enabled = 1 AND TenantKey = @TenantKey;

    PRINT('The script executed successfully!');

END;
GO
