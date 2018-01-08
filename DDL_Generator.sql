--SP_DDL_Generator 'AWBuildVersion'

IF EXISTS(SELECT * FROM sys.procedures WHERE Name like 'SP_DDL_Generator')
	DROP PROCEDURE [dbo].[SP_DDL_Generator]
GO
CREATE PROCEDURE [dbo].[SP_DDL_Generator]
(
	@ObjectName SYSNAME
)
AS

SET NOCOUNT ON

BEGIN TRY
	--This is the string containing the DDL info the we will print to the console
	DECLARE @DDL_String NVARCHAR(MAX) = ''

	SET @DDL_String = 
		'    USE ' + CONVERT(NVARCHAR, DB_NAME()) + ' 
	GO

	CREATE '

	SELECT 
		@DDL_String = @DDL_String + 
		CASE 
			WHEN AO.Type = 'V'
			THEN 'VIEW'
			WHEN AO.Type = 'U'
			THEN 'TABLE '
		END

		+ '[' + S.Name + '].[' + AO.Name + ']
		('
	+
		STUFF(Columns.Name, LEN(Columns.Name), 1, '')
		--Columns.Name
	+
	'
		)'
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
							'[' + AC.Name + '] ' +	--Column Name
							 CASE 
								WHEN AC.is_identity = 1
								THEN 'IDENTITY(' + 
									  CONVERT(NVARCHAR, IC.seed_value) + ',' + 
									  CONVERT(NVARCHAR, IC.increment_value) + ')'
								ELSE ''
							END
								
						FROM
							sys.all_columns AS AC
							LEFT JOIN
								sys.identity_columns AS IC
									ON IC.Object_ID = AC.Object_ID
						WHERE
							AC.object_ID = AO.Object_ID
						FOR XML PATH('')
					) AS Name
			) AS Columns
		WHERE
			AO.Name = @ObjectName


		PRINT @DDL_String
END TRY

BEGIN CATCH
	DECLARE @ErrorMsg NVARCHAR(2048) = ERROR_MESSAGE()
	RAISERROR(@ErrorMsg, 16, 1)
END CATCH

SET NOCOUNT OFF