/*
Script Name: SQL Monitor
Description: 
This script create a Database called "Instance Health Status" and its Database Objects, like:

Tables:
	*) ReportLog
		- Its intended to store information about this script, like the parameters that
			the user have entered;
	*) 

Stored Procedures:
	*)

Functions:
	*)

Views
	*)

Triggers
	*)

Author: Bruno Martim
Date: 25/05/2024

Purpose:
- [Explain the purpose or goal of the script]

Usage:
- [Provide instructions on how to use the script, including any required parameters or inputs]

Example:
- [Provide an example of how to use the script, if applicable]

Dependencies:
- [List any dependencies or requirements, such as specific database objects or permissions]

Assumptions:
- [Document any assumptions made by the script, such as the structure of the database or expected data]

Input:
- [List any inputs required by the script, such as parameters or data sources]

Output:
- [Describe the expected output of the script]

Error Handling:
- [Explain how errors are handled in the script, including any try-catch blocks or error logging]

Notes:
- [Include any additional notes or explanations that may be helpful]

References:
- [List any external references or documentation related to the script]

*/
USE [master];

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;


--	"Instance Health Status" database
DECLARE @dat_file_name	VARCHAR(128)	=	'/var/opt/mssql/data/ihs.mdf'
DECLARE @dat_size	VARCHAR(15)			=	'100 MB'
DECLARE @dat_maxsize VARCHAR(15)		=	'UNLIMITED'
DECLARE @dat_filegrowth	VARCHAR(15)		=	'100 MB'
-------------
DECLARE @log_file_name	VARCHAR(128)	=	'/var/opt/mssql/data/ihs.ldf'
DECLARE @log_size	VARCHAR(15)			=	'500 MB'
DECLARE @log_maxsize	VARCHAR(15)		=	'5	GB'
DECLARE @log_filegrowth	VARCHAR(15)		=	'500 MB'
-------------
DECLARE @collation	SYSNAME				=	'Latin1_General_CI_AS'


-- Script variables
DECLARE @command	NVARCHAR(MAX);
DECLARE @report		NVARCHAR(MAX);
DECLARE @return_code	INT = 0;

-- Error Handling Variables
DECLARE @error_message	NVARCHAR(4000);
DECLARE @error_severity	INT;
DECLARE @error_state	INT;

-----------------------------------------------------------------------
----					Member need to be SysAdmin				-------
-----------------------------------------------------------------------
IF IS_SRVROLEMEMBER('sysadmin',SUSER_NAME()) != 1	BEGIN
	SET @error_message = 'Você precisa ser membro ''SysAdmin'' para executar este script'
	SET @error_severity = 16;
	SET @error_state = 1;

	RAISERROR(
		@error_message,
		@error_severity,
		@error_state
	) WITH NOWAIT;
END

-----------------------------------------------------------------------
----				Temporary error table log					-------
-----------------------------------------------------------------------
IF EXISTS (SELECT * FROM [tempdb].sys.objects WHERE [name] LIKE '%#error_handling%' and type = 'U')
	DROP TABLE #error_handling
CREATE TABLE #error_handling(
	 [id]	INT IDENTITY(1,1)
	,[message]	VARCHAR(MAX)
	,[severity]	INT
	,[state]	INT)

SET @error_message = NULL;

-----------------------------------------------------------------------
------				Validate the database variables set			-------
-----------------------------------------------------------------------
	/* Verify if the lenght of the variable is less than 3 positions (**.mdf)... */
IF LEN(@dat_file_name) < 3 BEGIN
	INSERT INTO #error_handling(
		[message],
		[severity],
		[state])
			VALUES(
				'The lenght of the Data Filename is less than 3 positions. Please, verify the name of the data filename and try again',
				16,
				1);
END;

IF LEN(@log_file_name) < 3 BEGIN
	INSERT INTO #error_handling(
		[message],
		[severity],
		[state])
			VALUES(
			 'The length of the Log Filename is less than 3 positions. Please, verify the name of the data filename and try again',
			 16,
			 1);
END

------------------------------------------------------------------------
------					Print Errors if exists					--------
------------------------------------------------------------------------
IF EXISTS (SELECT [message] FROM #error_handling) AND @@ERROR != 0 BEGIN
	DECLARE error_cursor	CURSOR FAST_FORWARD	FOR SELECT [message], [severity],[state] FROM #error_handling;
	OPEN error_cursor;
	FETCH NEXT FROM error_cursor INTO @error_message, @error_severity, @error_state;

	WHILE @@FETCH_STATUS = 0 BEGIN
		RAISERROR(@error_message, @error_severity, @error_state)
		FETCH NEXT FROM error_cursor INTO @error_message, @error_severity, @error_state;
	END
	CLOSE error_cursor;
	DEALLOCATE error_cursor;
	GOTO return_error;
END

------------------------------------------------------------------------
-----						Create the database					--------
------------------------------------------------------------------------
SET @command =
	'CREATE DATABASE [Instance Health Status]
			CONTAINMENT = NONE
			ON
				PRIMARY(
					NAME = ''IHS Dat'',
					FILENAME = N''' + @dat_file_name + ''',
					SIZE = ' + @dat_size + ',
					MAXSIZE = ' + @dat_maxsize + ',
					FILEGROWTH = ' + @dat_filegrowth + '
				)
				LOG ON(
					NAME = ''IHS log'',
					FILENAME = N'''+ @log_file_name + ''',
					SIZE = ' + @log_size + ',
					MAXSIZE = ' + @log_maxsize+ ',
					FILEGROWTH = ' + @log_filegrowth + '
				)
			COLLATE ' + @collation

IF NOT EXISTS (SELECT * FROM sys.databases WHERE [name] = 'Instance Health Status')
	-- In that case of @return_code return any value different to 0, finish the script
	EXECUTE @return_code = sp_executesql @statement = @command
	IF @return_code != 0
		GOTO return_error;
ELSE BEGIN
	/*	If the database is already created, then drop the database and start creating all objects as new */
	
	ALTER DATABASE [Instance Health Status] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	
	DROP DATABASE [Instance Health Status];
	
	EXECUTE @return_code = sp_executesql @statement = @command

	IF @return_code != 0
		GOTO return_error;
END
	
SET @report = 
'#######################################################################
########						REPORT							########
########################################################################' + CHAR(10) +
'********	Banco de dados "Instance Health Status" criado com sucesso' + CHAR(10) +
'----------------------------------------------------'+ CHAR(10) +
'Nome e caminho do data file: ' + @dat_file_name + CHAR(10) +
'Tamanho inicial: ' + @dat_size + CHAR(10) +
'Tamanho maximo: ' + @dat_maxsize + CHAR(10) +
'Growth: ' + @dat_filegrowth + CHAR(10) +
'----------------------------------------------------'+ CHAR(10) +
'Nome e caminho do log file: ' + @log_file_name + CHAR(10) +
'Tamanho inicial: ' + @log_size + CHAR(10) +
'Tamanho maximo: ' + @log_maxsize + CHAR(10) +
'Growth: ' + @log_filegrowth + CHAR(10) +
'***********************************************************************';

------------------------------------------------------------------------
-----						Report table						--------
------------------------------------------------------------------------
CREATE TABLE [Instance Health Status].[dbo].[ScriptReport](
	 [id]	INT IDENTITY(1,1)
	,[context]		VARCHAR(128)
	,[report]		NVARCHAR(MAX)
	,[date_executed]	DATETIME
	CONSTRAINT [script_report_pk] PRIMARY KEY NONCLUSTERED(
		[id] ASC
	) WITH (	PAD_INDEX = OFF, 
				STATISTICS_NORECOMPUTE = OFF, 
				IGNORE_DUP_KEY = OFF, 
				ALLOW_ROW_LOCKS = ON, 
				ALLOW_PAGE_LOCKS = ON, 
				FILLFACTOR = 90
	) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [Instance Health Status].[dbo].[ScriptReport]
	WITH NOCHECK ADD CONSTRAINT [scriptreport_date_executed]
		DEFAULT CONVERT(DATETIME, GETDATE(), 103)
			FOR [date_executed];

INSERT INTO [Instance Health Status].[dbo].[ScriptReport](
	[context],
	[report])
		VALUES(
			'CREATE DATABASE',
			@report);

------------------------------------------------------------------------
----							Show report						--------
------------------------------------------------------------------------
IF EXISTS (SELECT [id] FROM [Instance Health Status].[dbo].[ScriptReport]) BEGIN
	SET @report = NULL
	DECLARE report_cursor CURSOR FAST_FORWARD FOR SELECT [report] FROM [Instance Health Status].[dbo].[ScriptReport] ORDER BY [id] ASC
	OPEN report_cursor
	FETCH NEXT FROM report_cursor INTO @report
	
	WHILE @@FETCH_STATUS = 0 BEGIN
		PRINT @report
		FETCH NEXT FROM report_cursor INTO @report
	END
	CLOSE report_cursor
	DEALLOCATE report_cursor
END

return_error:
	IF @return_code != 0
		print 'Script terminou com erro'
	ELSE
		print 'Script terminou com sucesso'
-- End of SQL code