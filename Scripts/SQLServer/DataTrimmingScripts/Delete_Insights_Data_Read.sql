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
	WHERE Enabled = 1

    PRINT('The script executed successfully!');

END;
GO
