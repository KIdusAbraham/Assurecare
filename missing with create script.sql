DECLARE @command1 NVARCHAR(2000)

create table #missing(
dbname varchar(1000),
tblname varchar(1000),
impact float,
seeks bigint,
scans bigint,
eq_col varchar(max),
ineq_col varchar(max),
inc_col varchar(max),
CreateIndexStatement varchar(max)
)

SET @command1 = 'USE [?]; '
SET @command1 = @command1 + '
BEGIN
insert into #missing
SELECT  db_name()
, sys.objects.name
, (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) AS Impact
, user_seeks
, user_scans
, mid.equality_columns
, mid.inequality_columns
, mid.included_columns
,  ''CREATE NONCLUSTERED INDEX ix_IndexName ON ''
 + s.name
 +''.''
 + sys.objects.name COLLATE DATABASE_DEFAULT
 + '' ( '' + IsNull(mid.equality_columns, '''')
 +
 CASE
  WHEN mid.inequality_columns IS NULL
  THEN ''''
 ELSE
 CASE
  WHEN mid.equality_columns IS NULL
  THEN ''''
 ELSE '','' 
 END + mid.inequality_columns
 END + '' ) ''
 + 
 CASE
  WHEN mid.included_columns IS NULL
  THEN ''''
 ELSE ''INCLUDE ('' + mid.included_columns + '')'' 
 END + '';'' AS CreateIndexStatement
    FROM sys.dm_db_missing_index_group_stats AS migs 
            INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle
            INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle AND mid.database_id = DB_ID() 
            INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
join sys.schemas s
	on sys.objects.schema_id = s.schema_id
    WHERE     (migs.group_handle IN 
        (
        SELECT     TOP (500) group_handle 
            FROM          sys.dm_db_missing_index_group_stats WITH (nolock) 
            ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))
        AND OBJECTPROPERTY(sys.objects.OBJECT_ID, ''isusertable'')=1
    ORDER BY 2 DESC , 3 DESC 

END';
EXEC dbo.sp_MSforeachdb @command1

select * 
from #missing
order by impact desc


drop table #missing