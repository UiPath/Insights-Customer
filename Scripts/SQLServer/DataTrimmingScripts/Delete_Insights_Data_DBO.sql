SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'IX_CreationTime' AND object_id = OBJECT_ID('[dbo].[QueueItems]'))
BEGIN
CREATE NONCLUSTERED INDEX [IX_CreationTime] ON [dbo].[QueueItems]
(
	[CreationTime] ASC
) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
END;
GO

CREATE OR ALTER PROCEDURE [dbo].[Delete_Insights_Data_DBO]
	@CutoffTimeStamp DATETIME,
	@BatchSize INT = 100000
AS
BEGIN

	DECLARE @total_deleted_jobEvents BIGINT = 0;
	DECLARE @total_deleted_queueItemEvents BIGINT = 0;
	DECLARE @total_deleted_robotLogs BIGINT = 0;
	DECLARE @total_deleted_jobs BIGINT = 0;
	DECLARE @total_deleted_queueItems BIGINT = 0;
	
	DECLARE @Jobs_Cutoff_Id BIGINT = 0;
	DECLARE @JobEvents_Cutoff_Id BIGINT = 0;
	DECLARE @QueueItems_Cutoff_Id BIGINT = 0;
	DECLARE @QueueItemEvents_Cutoff_Id BIGINT = 0;
	DECLARE @RobotLogs_Cutoff_Id BIGINT = 0;

	SET NOCOUNT ON;

	-- Get Cutoff Id of Jobs, QueueItems, QueueItemEvents, JobEvents, RobotLogs based on input timestamp.
	SET @JobEvents_Cutoff_Id = (SELECT ISNULL((SELECT MAX(Id) FROM [dbo].[JobEvents] WHERE TimeStamp <= @CutoffTimeStamp), 0));
	SET @Jobs_Cutoff_Id = (SELECT ISNULL((SELECT MAX(Id) FROM [dbo].[Jobs] WHERE CreationTime <= @CutoffTimeStamp), 0));
	SET @QueueItemEvents_Cutoff_Id = (SELECT ISNULL((SELECT MAX(Id) FROM [dbo].[QueueItemEvents] WHERE TimeStamp <= @CutoffTimeStamp), 0));
	SET @QueueItems_Cutoff_Id = (SELECT ISNULL((SELECT MAX(AnalyticsId) FROM [dbo].[QueueItems] WITH(INDEX(IX_CreationTime)) WHERE CreationTime <= @CutoffTimeStamp), 0));
	SET @RobotLogs_Cutoff_Id = (SELECT ISNULL((SELECT MAX(Id) FROM [dbo].[RobotLogs] WITH(INDEX(IX_TimeStamp)) WHERE TimeStamp <= @CutoffTimeStamp), 0));


	-- delete QueueItems
	DECLARE @Deleted_Rows_QueueItems INT = @BatchSize;
	WHILE(@Deleted_Rows_QueueItems = @BatchSize)
	BEGIN
		DELETE TOP(@BatchSize) FROM [dbo].[QueueItems] WHERE AnalyticsId <= @QueueItems_Cutoff_Id;
		SET @Deleted_Rows_QueueItems = @@ROWCOUNT;
		SET @total_deleted_queueItems = @Deleted_Rows_QueueItems +  @total_deleted_queueItems;
	END;

	-- delete QueueItemEvents
	DECLARE @Deleted_Rows_QueueItemEvents INT = @BatchSize;
	WHILE(@Deleted_Rows_QueueItemEvents = @BatchSize)
	BEGIN
		DELETE TOP(@BatchSize) FROM [dbo].[QueueItemEvents] WHERE Id <= @QueueItemEvents_Cutoff_Id;
		SET @Deleted_Rows_QueueItemEvents = @@ROWCOUNT;
		SET @total_deleted_queueItemEvents = @Deleted_Rows_QueueItemEvents + @total_deleted_queueItemEvents;
	END;

	-- delete jobs
	DECLARE @Deleted_Rows_Jobs INT = @BatchSize;
	WHILE(@Deleted_Rows_Jobs = @BatchSize)
	BEGIN
		DELETE TOP(@BatchSize) FROM [dbo].[Jobs] WHERE Id <= @Jobs_Cutoff_Id;
		SET @Deleted_Rows_Jobs = @@ROWCOUNT;
		SET @total_deleted_jobs = @Deleted_Rows_Jobs + @total_deleted_jobs;	
	END;

	-- delete jobEvents
	DECLARE @Deleted_Rows_JobEvents INT = @BatchSize;
	WHILE(@Deleted_Rows_JobEvents = @BatchSize)
	BEGIN
		DELETE TOP(@BatchSize) FROM [dbo].[JobEvents] WHERE Id <= @JobEvents_Cutoff_Id;
		SET @Deleted_Rows_JobEvents = @@ROWCOUNT;
		SET @total_deleted_jobEvents = @Deleted_Rows_JobEvents + @total_deleted_jobEvents;
	END;

	-- delete robotLogs
	DECLARE @Deleted_Rows_RobotLogs INT = @BatchSize;
	WHILE(@Deleted_Rows_RobotLogs = @BatchSize)
	BEGIN
		DELETE TOP(@BatchSize) FROM [dbo].[RobotLogs] WHERE Id <= @RobotLogs_Cutoff_Id;
		SET @Deleted_Rows_RobotLogs = @@ROWCOUNT;
		SET @total_deleted_robotLogs = @Deleted_Rows_RobotLogs + @total_deleted_robotLogs;
	END;

    PRINT('The script executed successfully!');
	PRINT('Total deleted rows from [dbo].[JobEvents]: ' + CONVERT(NVARCHAR, @total_deleted_jobEvents));
	PRINT('Total deleted rows from [dbo].[QueueItemEvents]: ' + CONVERT(NVARCHAR, @total_deleted_queueItemEvents));
	PRINT('Total deleted rows from [dbo].[Jobs]: ' + CONVERT(NVARCHAR, @total_deleted_jobs));
	PRINT('Total deleted rows from [dbo].[QueueItems]: ' + CONVERT(NVARCHAR, @total_deleted_queueItems));
	PRINT('Total deleted rows from [dbo].[RobotLogs]: ' + CONVERT(NVARCHAR, @total_deleted_robotLogs));

END;
GO


