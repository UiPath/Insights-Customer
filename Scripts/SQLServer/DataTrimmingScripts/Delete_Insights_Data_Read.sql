SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [read].[Delete_Insights_Data_Read]
AS
BEGIN

	-- clear read data
	TRUNCATE TABLE [read].[Jobs];
	TRUNCATE TABLE [read].[JobEvents];
	TRUNCATE TABLE [read].[QueueItems];
	TRUNCATE TABLE [read].[QueueItemEvents];
	TRUNCATE TABLE [read].[RobotLogs];

	-- rebuild all Dynamic Json tables
	UPDATE [read].[JsonSettings]
	SET DdlOperationPerformed = 0, LastUpdatedTime = GETUTCDATE()
	WHERE Enabled = 1;

	-- kill all of running Migrate Data SPs
	DECLARE @command NVARCHAR(MAX);

	WHILE EXISTS (SELECT session_id 
			  FROM sys.dm_exec_requests handle OUTER APPLY sys.fn_get_sql(handle.sql_handle) spname  
			  WHERE spname.text LIKE '%Migrate%' AND spname.text NOT LIKE '%sys.dm_exec_requests%')
    BEGIN
		SELECT @command = STRING_AGG(CONCAT ('KILL ', session_id), ' ')  
		FROM sys.dm_exec_requests handle OUTER APPLY sys.fn_get_sql(handle.sql_handle) spname  
		WHERE spname.text LIKE '%Migrate%' AND spname.text NOT LIKE '%sys.dm_exec_requests%';

    	EXEC (@command);
	-- Aborted SP will be retried, wait 3 seconds and kill the process again. 
		WAITFOR DELAY '00:00:03';
    END;

	-- Verify again, if there is data in the table again, truncate the table again.
	IF EXISTS (SELECT TOP 1 * FROM [read].[RobotLogs]) 
	BEGIN
    	TRUNCATE TABLE [read].[RobotLogs];
	END;

	IF EXISTS (SELECT TOP 1 * FROM [read].[Jobs]) 
	BEGIN
    	TRUNCATE TABLE [read].[Jobs];
	END;

	IF EXISTS (SELECT TOP 1 * FROM [read].[JobEvents]) 
	BEGIN
    	TRUNCATE TABLE [read].[JobEvents];
	END;

	IF EXISTS (SELECT TOP 1 * FROM [read].[QueueItems]) 
	BEGIN
    	TRUNCATE TABLE [read].[QueueItems];
	END;

	IF EXISTS (SELECT TOP 1 * FROM [read].[QueueItemEvents]) 
	BEGIN
    	TRUNCATE TABLE [read].[QueueItemEvents];
	END;

    PRINT('The script executed successfully!');

END;
GO
