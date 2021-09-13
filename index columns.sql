CREATE TABLE #output
                (
	dbname varchar(2000)
,	tablename varchar(2000)
,	indexname varchar(2000)
,	typedesc varchar(2000)
,	isunique bit
,	ispk bit
,	idxCol_asc varchar(1000)
,	idxCol_desc varchar(1000)
,	incCol varchar(2000)
,	idxCol_all varchar(1000)
--,	filterdef varchar(2000) -- 2008 + ONLY!!
                );

DECLARE @command1 NVARCHAR(4000)
declare @var nvarchar(255)

declare dbs cursor for
select [name] from sys.databases
where [name] not in ('tempDb', 'msdb', 'master', 'model')

open dbs
fetch next from dbs into @var
while @@fetch_status=0
begin

set @command1= 'use ['+@var+']

INSERT #output
SELECT '''+@var+''' as dbname
	 , Table_Name       =SCHEMA_NAME(st.Schema_id) + ''.''
                         + OBJECT_NAME(st.object_id)
     , Index_Name       = si.name
	 , si.Type_Desc
	 , si.is_unique
	 , si.is_primary_key
     , Indexed_Columns_asc  = LEFT(ixColumns_asc, LEN(ixColumns_asc) -1)
     , Indexed_Columns_desc  = LEFT(ixColumns_desc, LEN(ixColumns_desc) -1)
     , Included_Columns = LEFT(includedColumns, LEN(includedColumns) -1)
     , Indexed_Columns_all  = LEFT(ixColumns_all, LEN(ixColumns_all) -1)
--     , si.filter_definition -- 2008 + ONLY!!
  FROM ['+@var+'].sys.tables st
  join ['+@var+'].sys.indexes si
    on st.object_id = si.object_id
CROSS APPLY (
            SELECT sc.Name + '', ''
              FROM ['+@var+'].sys.index_columns ic
              JOIN ['+@var+'].sys.columns sc
                on ic.object_id = sc.object_id
               AND ic.column_id = sc.column_id
             WHERE si.object_id = ic.object_id
               AND is_included_column = 0
               and si.index_id = ic.index_id
               and is_descending_key = 0
             ORDER BY ic.Key_Ordinal
              FOR XML PATH('''') ) ixa (ixColumns_asc)
CROSS APPLY (
            SELECT sc.Name + '', ''
              FROM ['+@var+'].sys.index_columns ic
              JOIN ['+@var+'].sys.columns sc
                on ic.object_id = sc.object_id
               AND ic.column_id = sc.column_id
             WHERE si.object_id = ic.object_id
               AND is_included_column = 0
               and si.index_id = ic.index_id
               and is_descending_key = 1
             ORDER BY ic.Key_Ordinal
              FOR XML PATH('''') ) ixd (ixColumns_desc)
CROSS APPLY (
            SELECT sc2.Name + '', ''
              FROM ['+@var+'].sys.index_columns ic2 
			  JOIN ['+@var+'].sys.columns sc2 
			   on ic2.object_id = sc2.object_id
               AND ic2.column_id = sc2.column_id
             WHERE si.object_id = ic2.object_id
               AND is_included_column = 1
               and si.index_id = ic2.index_id
             ORDER BY ic2.Key_Ordinal
              FOR XML PATH('''') ) nc (includedColumns)
CROSS APPLY (
            SELECT sc.Name + '', ''
              FROM ['+@var+'].sys.index_columns ic
              JOIN ['+@var+'].sys.columns sc
                on ic.object_id = sc.object_id
               AND ic.column_id = sc.column_id
             WHERE si.object_id = ic.object_id
               AND is_included_column = 0
               and si.index_id = ic.index_id
             ORDER BY ic.Key_Ordinal
              FOR XML PATH('''') ) ixal (ixColumns_all)
where si.Type_Desc<>''HEAP''
'

exec(@command1)

fetch next from dbs into @var
end
close dbs
deallocate dbs

select * from #output
order by dbname, tablename, indexname
drop table #output