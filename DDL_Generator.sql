USE [AdventureWorks2012]
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE Name like 'SP_DDL_Generator')
	DROP PROCEDURE [dbo].[SP_DDL_Generator]
GO
CREATE PROCEDURE [dbo].[SP_DDL_Generator]
(
	@ObjectName SYSNAME,
	@Schema SYSNAME = dbo,
	@DDL_String NVARCHAR(MAX) = '' OUTPUT		--Output paremeter used if someone wants to call this programatically
)
AS

SET NOCOUNT ON

BEGIN TRY
	--This is the string containing the DDL info the we will print to the console
	SET @DDL_String =  
		'    USE ' + CONVERT(NVARCHAR, DB_NAME()) + ' 
	GO
	'

	SELECT 
		@DDL_String = @DDL_String + 
		CASE 
			WHEN AO.Type = 'V'
			THEN 'CREATE VIEW '
			WHEN AO.Type = 'U'
			THEN 'CREATE TABLE '
		END

		+ QUOTENAME(S.Name) + '.' + QUOTENAME(AO.Name) + '
		('
	+
		STUFF(Columns.Name, LEN(Columns.Name), 1, '')
	+
	'
		)
		'  
	FROM
		sys.all_objects AS AO
		INNER JOIN
			sys.schemas AS S
				ON S.Schema_ID = AO.Schema_ID
		CROSS APPLY
			(

				SELECT
					(
						SELECT	
							CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + 
							QUOTENAME(AC.Name)  +	--Column Name
							' ' + QUOTENAME(T.Name) +		--Data type name
							CASE
								WHEN T.Name = 'varchar' 
									THEN  '(' + CONVERT(NVARCHAR, AC.Max_Length) + ')'
								WHEN T.Name = 'nvarchar' 
									THEN  '(' + CONVERT(NVARCHAR, AC.Max_Length/2) + ')'
								WHEN T.Name = 'char' 
									THEN  '(' + CONVERT(NVARCHAR, AC.Max_Length) + ')'
								WHEN T.Name = 'decimal'
									THEN  '(' + CONVERT(NVARCHAR, AC.precision) + ',' + CONVERT(NVARCHAR, AC.scale) + ')'
								ELSE ''
							END  +
							 CASE					--Identity info
								WHEN AC.is_identity = 1
								THEN ' IDENTITY(' + 
									  CONVERT(NVARCHAR, ISNULL(IC.seed_value, 1)) + ',' +
									  CONVERT(NVARCHAR, ISNULL(IC.increment_value, 1)) + ')'
								ELSE ''
							END + 
							CASE					--NULL or NOT NULL
							  WHEN AC.is_nullable = 1
								THEN ' NULL'
								ELSE ' NOT NULL'
							END  +
							',' 
						FROM
							sys.all_columns AS AC
							LEFT JOIN
								sys.types AS T
									ON T.user_type_id = AC.user_type_id
							LEFT JOIN
								sys.identity_columns AS IC
									ON IC.Object_ID = AC.Object_ID
						WHERE
							AC.object_ID = AO.Object_ID
						FOR XML PATH('')
					) AS Name
			) AS Columns
	WHERE
		AO.Name = ISNULL(@ObjectName, AO.Name)
	AND AO.type IN ('U', 'V')
	AND S.Name = ISNULL(@Schema, S.Name)
	--AND SCHEMA_NAME(AO.schema_id) NOT IN('sys', 'INFORMATION_SCHEMA')		--We don't want to return sys objects
	ORDER BY
		AO.name ASC

	PRINT @DDL_String 

END TRY

BEGIN CATCH
	DECLARE @ErrorMsg NVARCHAR(2048) = ERROR_MESSAGE()
	RAISERROR(@ErrorMsg, 16, 1)
END CATCH

SET NOCOUNT OFF
