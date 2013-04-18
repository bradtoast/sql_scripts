SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
DECLARE @storedProcName VARCHAR(MAX) = NULL

SELECT  p.name AS sprocName ,
  	p.[modify_date]
FROM    sys.procedures AS p
        LEFT JOIN sys.dm_exec_procedure_stats AS s ON s.[object_id] = p.[object_id]
WHERE   s.object_id IS NULL
		AND p.[modify_date] < DATEADD(YEAR, -1, GETDATE())
		AND (@storedProcName IS NULL OR p.name LIKE '%' + @storedProcName + '%')
ORDER BY [modify_date] ASC

