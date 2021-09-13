--all dbs > compat 80
DECLARE @command1 NVARCHAR(2000)
CREATE TABLE #output
                (
                  dbname VARCHAR(128),
                  obj_name VARCHAR(260),
                  index_name VARCHAR(150),
                  index_id INT,
                  index_type VARCHAR(100),
                  pct_frag DECIMAL(16,4),
                  frag_count INT,
                  page_count INT,
                  orig_fill_factor INT,
                  avg_page_space DECIMAL(16,4)
                );
SET @command1 = 'USE [?]; '
--SET @command1 = @command1 + 'IF DB_NAME(DB_ID(''?'')) IN (REPLACEMEDOUBLE)'
SET @command1 = @command1 + '
BEGIN
INSERT #output
SELECT DB_NAME(database_id) AS [Database Name], OBJECT_NAME(ps.OBJECT_ID) AS [Object Name],
i.name AS [Index Name], ps.index_id AS [Index ID], index_type_desc AS [Index Type],
avg_fragmentation_in_percent AS [% Fragmentation], fragment_count AS [Fragment Count], 
page_count AS [Page Count],i.fill_factor AS [Original Fill Factor],
ps.avg_page_space_used_in_percent AS [Avg Page Space Used %]
--FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,''LIMITED'') AS ps
FROM sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,''SAMPLED'') AS ps 
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON ps.[object_id] = i.[object_id]
AND ps.index_id = i.index_id
WHERE database_id = DB_ID()
--AND page_count >= 1000 --1000 pages is the default for index maintenance
ORDER BY avg_fragmentation_in_percent DESC OPTION (RECOMPILE)
END';
EXEC dbo.sp_MSforeachdb @command1
select * from #output order by pct_frag desc
drop table #output