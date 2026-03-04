# Insights-Customer

UiPath Insights user scripts, util tools, and hotfix patches for customer.

## Scripts

- OnPrem Installation Scripts https://github.com/UiPath/Insights-Customer/tree/master/Scripts/OnPrem
- SQLServer Scripts https://github.com/UiPath/Insights-Customer/tree/master/Scripts/SQLServer

### Performance Indexes Script (IN-11910)

The script `Scripts/SQLServer/IndexScripts/insights_indexes_test.sql` creates optimized composite indexes to improve query performance on the Insights database. It addresses heavy SQL operation bottlenecks caused by missing SORT and JOIN indexes.

**Prerequisites:**
- SQL Server Management Studio (SSMS) or Azure Data Studio
- Access to the target Insights database with permissions to create/drop indexes
- The script targets the `[read]` schema

**Steps to run:**

1. Open SSMS or Azure Data Studio.
2. Connect directly to the **Insights database** (do NOT use a `USE` statement — it is not supported in Azure SQL).
3. Open the script file `Scripts/SQLServer/IndexScripts/insights_indexes_test.sql`.
4. Execute the script. It will:
   - Drop 2 outdated indexes (`IX_Jobs_TenantKey_StartTime`, `IX_RobotLogs_TenantKey_Timestamp`) that are replaced by improved versions.
   - Create 8 new nonclustered indexes across 5 tables (`Jobs`, `JobEvents`, `QueueItems`, `QueueItemEvents`, `RobotLogs`).
   - Print progress messages for each step.
   - Run a verification query at the end to confirm all indexes were created.
5. Review the verification query output to ensure all 8 indexes are listed.

**Notes:**
- The script is **idempotent** — it uses `IF NOT EXISTS` / `IF EXISTS` checks, so it is safe to run multiple times.
- Index creation may take time on large tables. Consider running during a maintenance window to avoid impacting production workloads.

## Tools

- Insights Backup Tool https://github.com/UiPath/Insights-Customer/blob/master/Tools/InsightsBackupTool.exe

## Hotfixes

- Log4j fixes: https://github.com/UiPath/Insights-Customer/tree/master/hotfix/log4j
