SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
DECLARE @TABLENAME varchar(100)
DECLARE @SCHEMA varchar(100)
SET @TABLENAME = N'tableName'
SET @SCHEMA = N'dbo'

DECLARE @Done bit 
SET @Done=0 

DECLARE @CRLF char(2)
SET @CRLF = char(10)
DECLARE @SQL varchar(1000)
SET @SQL = '
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''['+@SCHEMA+'].
['+@TABLENAME+'_Audit]'') AND type in (N''U''))
DROP TABLE [dbo].['+@TABLENAME+'_Audit]
CREATE TABLE ['+@SCHEMA+'].['+@TABLENAME+'_Audit] ('+@CRLF
DECLARE @COLUMNID int
SET @COLUMNID = 0
DECLARE @COLUMNNAME varchar(1000)
DECLARE @COLUMNTYPE varchar(100)
DECLARE @COLUMNSIZE int

WHILE @Done=0   
BEGIN            
    SELECT top 1
    @COLUMNID=clmns.column_id,
    @COLUMNNAME=clmns.name ,
    @COLUMNTYPE=usrt.name ,
    @COLUMNSIZE=CAST(CASE WHEN baset.name IN (N'nchar', N'nvarchar') AND 
clmns.max_length <> -1 THEN clmns.max_length/2 ELSE clmns.max_length END AS int)
    FROM
    sys.tables AS tbl
    INNER JOIN sys.all_columns AS clmns ON clmns.object_id=tbl.object_id
    LEFT OUTER JOIN sys.types AS usrt ON usrt.user_type_id = clmns.user_type_id
    LEFT OUTER JOIN sys.types AS baset ON baset.user_type_id = clmns.system_type_id and 
baset.user_type_id = baset.system_type_id
    WHERE
    (tbl.name=@TABLENAME and SCHEMA_NAME(tbl.schema_id)=@SCHEMA)
    and clmns.column_id > @COLUMNID
    ORDER BY
    clmns.column_id asc

    IF @@rowcount=0  
        begin   
            SET @Done=1  
        end
    else
        begin
            SET @SQL=@SQL+'['+@COLUMNNAME+'] ['+@COLUMNTYPE+'] '
            IF (@COLUMNTYPE='varchar') SET @SQL=@SQL+'('+ltrim(str(@COLUMNSIZE))
+') '
            SET @SQL=@SQL+'NULL, '+@CRLF
        end
END

SET @SQL=@SQL+'[timestamp] datetime )'
print @SQL
exec (@SQL)
SET @SQL='IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N''[dbo].
['+@TABLENAME+'_Trigger]''))
DROP TRIGGER [dbo].['+@TABLENAME+'_Trigger]'
print @SQL
--exec(@SQL)

SET @SQL='CREATE TRIGGER ['+@TABLENAME+'_Trigger] 
   ON  ['+@SCHEMA+'].['+@TABLENAME+'] 
   AFTER UPDATE, INSERT
AS 
BEGIN
    SET NOCOUNT ON;
    INSERT INTO '+@TABLENAME+'_Audit 
    SELECT *,getdate() FROM inserted
END'
print @SQL
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
--exec (@SQL)
