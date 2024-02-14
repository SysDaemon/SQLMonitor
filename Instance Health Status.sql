/*
-- ============================================================================================
-- Database: Instance Health Status
-- Description: Create a Database to store all Views, Stored Procedures and Tables.
--  The Database is Shcmea strong, which means that all Stored Procedures, views and tables
--      are organized by the main topis (i.e., Disk, CPU, IO and NIC);
--
--  The Database also stores information by
--      the metrics of the instance, workload
--      and metrics; generated by Stored Procedures;
-- --------------------------------------------------------------------------------------------
-- Author: Bruno Martim - bruno@bmartim.com.br
-- Date: 13/02/2024
-- ============================================================================================
*/

-- Messages and Errors variables
DECLARE @Errors TABLE(
    [ID] UNIQUEIDENTIFIER PRIMARY KEY,
    [Message]   NVARCHAR(MAX) NOT NULL,
    Severity    INT NOT NULL,
    [State] INT
)
DECLARE @ErrorMessage   NVARCHAR(4000);

DECLARE @CMD NVARCHAR(MAX);

DECLARE @Size_DataFile NVARCHAR(15);
DECLARE @Size_LogFile NVARCHAR(15);
DECLARE @MaxSize_DataFile   NVARCHAR(15);
DECLARE @MaxSize_LogFile    NVARCHAR(15);
DECLARE @Filegrowth_DataFile NVARCHAR(15);
DECLARE @Filegrowth_LogFile NVARCHAR(15);

DECLARE @Name_DataFile  NVARCHAR(64);
DECLARE @Name_LogFile   NVARCHAR(64);
DECLARE @Path_DataFile  NVARCHAR(128);
DECLARE @Path_LogFile   NVARCHAR(128);

-- Setting the name of Logical and Physical files
SET @Name_DataFile = 'Instance Data';
SET @Name_LogFile = 'Instance Log';

-- Setting the Path for Filenames
SET @Path_DataFile = '/var/opt/mssql/data/';
SET @Path_LogFile = '/var/opt/mssql/data/';

-- Setting the size & filegrowth of the Database
SET @Size_DataFile = '100 MB';
SET @Filegrowth_DataFile = '100 MB';
SET @MaxSize_DataFile = 'UNLIMITED';

SET @Size_LogFile = '100 MB';
SET @Filegrowth_LogFile = '200 MB';
SET @MaxSize_LogFile = '2 GB';


SET @CMD = '
CREATE DATABASE [Instance Health Status]
    CONTAINMENT = NONE
    ON
        PRIMARY(
            NAME = ''' + @Name_DataFile + ''',
            FILENAME = N''' + @Path_DataFile + @Name_DataFile + '.mdf'',
                SIZE = ' + @Size_DataFile + ',
                MAXSIZE = ' + @MaxSize_DataFile + ',
                FILEGROWTH = ' + @Filegrowth_DataFile + '
        )
        LOG ON(
            NAME = ''' + @Name_LogFile + ''',
            FILENAME = N''' + @Path_LogFile + @Name_LogFile + '.ldf'',
                SIZE = ' + @Size_LogFile + ',
                MAXSIZE = ' + @MaxSize_LogFile + ',
                FILEGROWTH = ' + @Filegrowth_LogFile + '
        )
    COLLATE SQL_Latin1_General_CP1_CI_AS
'

-- PRINT @CMD

DECLARE @RC INT;
EXECUTE @RC = dbo.sp_executesql @statement = @CMD;

IF @RC != 0
    RAISERROR(
        'Could not create the Database',
        16,
        1
    )

/*
==================================================================================
Modification History:
[Document any changes made to the stored procedure along with dates and authors.]
e.g.,
Date       |    Author    | Description
-----------|--------------|-------------------------------------------------------
2023-01-01 | Bruno Martim | Initial creation of Database
==================================================================================
*/