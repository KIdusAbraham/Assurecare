DECLARE @command1 NVARCHAR(2000)

create table #indexcols(
dbname varchar(1000),
tblname varchar(1000),
id bigint,
indid bigint,
name varchar(1000),
position int,
cols int
)

SET @command1 = 'USE [?]; '
SET @command1 = @command1 + '
BEGIN
insert into #indexcols
	SELECT
	DB_NAME(),
	object_schema_name(i.object_id) + ''.'' + OBJECT_NAME(i.object_id),
    i.object_id,
    i.index_id,
    i.name ,
    k.keyno,
    CASE k.keyno
          WHEN 0 THEN NULL
          ELSE k.colid
          END AS cols
   FROM
    sys.indexes AS i  
	join sys.objects o 
	on i.object_id=o.object_id,
    sys.sysindexkeys AS k
      WHERE
        k.id = i.object_id
        AND k.indid = i.index_id
		and o.is_ms_shipped=0
		and i.is_unique = 0
		and i.is_primary_key = 0
END';
EXEC dbo.sp_MSforeachdb @command1



    SELECT
		@@servername AS [Server Name],
		c1.dbname,
        c1.tblname,
        c1.name AS [Index Name] ,
        c2.name AS [Overlapping Index Name]
    FROM
        #indexcols AS c1 
        JOIN #indexcols AS c2 ON c1.dbname=c2.dbname
              AND c1.id = c2.id
              AND c1.indid < c2.indid 
              and c1.cols=c2.cols
              and c1.position = 1 and c2.position = 1 --just check the first key column
	group by c1.dbname,c1.tblname,c1.id,c1.name,c2.name

drop table #indexcols
