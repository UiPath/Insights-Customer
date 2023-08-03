--LevelOrdinal: 0 unknown, 1 debug, 2 infor, 3 warn, 4 error, 5 fetal
--if you have too many robotlogs, you can add filter for specific time range for each delete. eg: [Timestamp] < '2020-01-01 00:00:00.000'
--if you want to delete debug log add filter "or LevelOrdinal in (0, 1)"
delete from [dbo].[RobotLogs] where LevelOrdinal = 2 and (Message not like '%execution ended');
--you just need to truncate read tables once
truncate table [read].[RobotLogs];