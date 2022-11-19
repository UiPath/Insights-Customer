SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Delete_Process_Logs_DBO]
	@ProcessName NVARCHAR(128),
	@TenantId INT,
	@BatchSize INT = 100000
AS
BEGIN
	IF IS_SRVROLEMEMBER('sysadmin') != 1
	BEGIN
		PRINT('Failed to execute the script! Current user doesn''t own sysadmin role.')
    	RETURN;
	END;

	SET NOCOUNT ON;
	DECLARE @Start_RobotLogs_Cutoff_Id BIGINT = 0;
	DECLARE @End_RobotLogs_Cutoff_Id BIGINT = 0;

	SET @Start_RobotLogs_Cutoff_Id = (SELECT ISNULL((SELECT MIN(Id) FROM [dbo].[RobotLogs] WHERE ProcessName = @ProcessName AND TenantId = @TenantId), 0));
	SET @End_RobotLogs_Cutoff_Id = (SELECT ISNULL((SELECT MAX(Id) FROM [dbo].[RobotLogs] WHERE ProcessName = @ProcessName AND TenantId = @TenantId), 0));

    DECLARE @Deleted_Rows_RobotLogs INT = @BatchSize;
	WHILE(@Deleted_Rows_RobotLogs = @BatchSize)
	BEGIN
		DELETE TOP(@BatchSize) FROM [dbo].[RobotLogs] 
		WHERE Id >= @Start_RobotLogs_Cutoff_Id AND Id <= @End_RobotLogs_Cutoff_Id AND ProcessName = @ProcessName AND TenantId = @TenantId
        SET @Deleted_Rows_RobotLogs = @@ROWCOUNT;
	END;

    PRINT('The script executed successfully!');
END;
GO


