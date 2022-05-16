SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [read].[Delete_Process_Logs_Read]
	@ProcessName NVARCHAR(128),
	@TenantId INT
AS
BEGIN

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

	-- clear read table
	TRUNCATE TABLE [read].[RobotLogs];

	-- rebuild impacted process table 
	UPDATE [read].[JsonSettings]
	SET DdlOperationPerformed = 0, LastUpdatedTime = GETUTCDATE()
	WHERE QueueJsonType IS NULL AND ObjectName = @ProcessName AND Enabled = 1 AND TenantKey = @TenantKey;

    PRINT('The script executed successfully!');

END;
GO
