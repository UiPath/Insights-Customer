--LevelOrdinal: 0 unknown, 1 debug, 2 infor, 3 warn, 4 error, 5 fetal
delete from [dbo].[RobotLogs] where LevelOrdinal in (0, 1) or (LevelOrdinal = 2 and Message not like '%execution ended');
--you just need to truncate read tables once
truncate table [read].[RobotLogs];