USE [Instance Health Status];

GO
/*
========================================================================
Stored Procedure: [Disk].[DatabaseSpace_prc]
Description: This Stored Procedure gather information about space
    used for each database on Instance

Author: Bruno Martim
Date: 04/02/2024
========================================================================
*/

-- Drop the stored procedure if it already exists
IF OBJECT_ID('[Disk].[DatabaseSpace_prc]', 'P') IS NOT NULL
    DROP PROCEDURE [Disk].[DatabaseSpace_prc];
GO

-- Set ANSI_NULLS and QUOTED_IDENTIFIER options
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Add additional SET options if necessary
SET NOCOUNT ON;
GO

/*
========================================================================
Parameters:
    No parameters
========================================================================
*/

CREATE OR ALTER PROCEDURE [Disk].[DatabaseSpace_prc]
AS
BEGIN
    /*
    ========================================================================
    Purpose: The code execute a DBCC on all database, to gather information
        about the space used and space alloc from every database on the instance,
        by targeting each database, using sp_MSforeachdb.
        It union with information about each database log, gathered by
        a DMV sys.dm_os_performance_counters;

    Usage:
    EXEC [Disk].[DatabaseSpace_prc]
        -- No param.
    ========================================================================
	*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	-- Error handling variables
	DECLARE @ErrorMessage	NVARCHAR(4000);
	DECLARE @ErrorSeverity	INT;
	DECLARE @ErrorState		INT;
    /*
	Algorithm 
	========================================================================
    Steps:
    1. Gather information about the current database, using a DBCC showfilestats
    2. Use sp_MSforeachdb to iterate on all database;
    3. Gather the result of DMV, by using an dinamic table unionized with 
        the temporary table;
    4. Pivot the table and sum the counter_stats values
    5. Display the DB Name, Log file used (in MB) and Data File used (in MB)
    ========================================================================
    */

    DECLARE @CMD VARCHAR(2000);

    -- Declare table to hold temporary information
	IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE object_id = OBJECT_ID('tempdb..##tmp_sfs'))
		DROP TABLE ##tmp_sfs;

    CREATE TABLE  ##tmp_sfs (
        FileID  int,
        FileGroup int,
        TotalExtents int,
        UsedExtents int,
        Name    varchar(1024),
        FileName varchar(1024),
        DBName  varchar(128)
    );

    -- Command to gather space for each database
    SET @CMD = 'DECLARE @DBName VARCHAR(128);
                SET @DBName = ''?'';

                INSERT INTO ##tmp_sfs (FileID, FileGroup, TotalExtents,
                                        UsedExtents, Name, FileName)
                    EXEC (''USE ['' + @DBName + '']
                        DBCC SHOWFILESTATS WITH NO_INFOMSGS'');
                
                UPDATE ##tmp_sfs SET DBName = @DBName
                    WHERE DBName is null';

    -- Run command against each database
    EXEC master.sys.sp_MSforeachdb @CMD;

    SELECT  DBName AS "Database Name",
            CAST([LOG File(s) Size (KB)] / 1024.0 AS DECIMAL (18,3)) AS [LogAllocMB]],
            [DataAllocMB],
            CAST([DataUsedMB] AS DECIMAL(18,3)) AS [DataUsedMB]
        FROM (
            SELECT  instance_name AS DBName, 
                    cntr_value,
                    counter_name
                FROM sys.dm_os_performance_counters
                    WHERE   counter_name IN (
                                'Log File(s) Size (KB)'
                            )
                            AND instance_name NOT IN (
                                '_Total',
                                'mssqlsystemresource'
                            )
            UNION ALL

            SELECT  DBName,
                    usedextents * 8 / 128.0 AS cntr_value,
                    'DataUsedMB' AS counter_name
                FROM ##tmp_sfs
        ) AS PerfCounters
        PIVOT(
            SUM(cntr_value)
            FOR counter_name IN (
                [LOG File(s) Size (KB)],
                [DataAllocMB],
                [DataUsedMB]
            ) 
        ) AS pvt;

END;
GO

/*
================================================================================
Modification History:
Date       |   Author     | Description
-----------|--------------|-----------------------------------------------------
2024-02-04 | Bruno Martim | Initial creation of the stored procedure
2024-02-07 | Bruno Martim | Refactor the name of the SP, from "DiskSpace" to "DatabaseSpacePRC"
================================================================================
*/