USE [Instance Health Status];

GO

/*
-- =============================================
-- Schema: Resources
-- Table: DiskSpace
-- Description: Hold information about how much
--  disk space every database use;
-- ---------------------------------------------
-- Author: Bruno Martim
-- Date: 04/02/2024
/-- =============================================/
*/
CREATE TABLE [Resources].[DatabaseSpace] (
 	 [id] UNIQUEIDENTIFIER NOT NULL
    ,[File ID] INT
	,[Logical Name]	SYSNAME NOT NULL
	,[File Name]	VARCHAR(128) NOT NULL
	,[DBName]	SYSNAME NOT NULL
    ,[File Group ID] 	INT
	,[UsedExtents]		INT
    ,[Total Extents] 	INT
    ,[Used_KB]	FLOAT NULL
	,[Used_MB]	FLOAT NULL
	,[Used_GB]	FLOAT NULL
	,[Used_TB]	FLOAT NULL
	,[Used_PB]	FLOAT NULL
	,[Record_Added_On] DATETIME NOT NULL
	,[Record_Changed_On] DATETIME NULL
   CONSTRAINT [DiskSpace_pk] PRIMARY KEY NONCLUSTERED(
			[File ID] ASC
		) WITH (	PAD_INDEX = OFF, 
					STATISTICS_NORECOMPUTE = OFF, 
					IGNORE_DUP_KEY = OFF,
					ALLOW_ROW_LOCKS = ON, 
					ALLOW_PAGE_LOCKS = ON, 
					FILLFACTOR = 90, 
					OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
		) ON [PRIMARY]
);
GO

-- Additional comments or constraints can be added as needed
-- =============================================
-- Indexes:
-- - DiskSpace_pk: Index on [File ID]
--
-- Constraints:
-- - DiskSpace_-_Record_Added_On: Constraint for Record_Added_On
-- =============================================
ALTER TABLE [Resources].[DiskSpace]
	WITH NOCHECK ADD CONSTRAINT [DiskSpace_-_Record_Added_On]
		DEFAULT CONVERT(DATETIME, GETDATE(), (103))
			FOR [Record_Added_On];
GO

/*
====================================================================================
Modification History:

Date       |     Author   | Description
-----------|--------------|---------------------------------------------------------
2024-02-04 | Bruno Martim | Initial creation of the table

====================================================================================
*/