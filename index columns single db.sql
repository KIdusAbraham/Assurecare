SELECT db_name() as dbname
	 , Table_Name       =SCHEMA_NAME(st.Schema_id) + '.'
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
-- ,  'CREATE NONCLUSTERED INDEX ix_IndexName ON '
 -- + s.name
 -- +'.'
 -- + sys.objects.name COLLATE DATABASE_DEFAULT
 -- + ' ( ' + IsNull(mid.equality_columns, '')
 -- +
 -- CASE
  -- WHEN mid.inequality_columns IS NULL
  -- THEN ''
 -- ELSE
 -- CASE
  -- WHEN mid.equality_columns IS NULL
  -- THEN ''
 -- ELSE ',' 
 -- END + mid.inequality_columns
 -- END + ' ) '
 -- + 
 -- CASE
  -- WHEN mid.included_columns IS NULL
  -- THEN ''
 -- ELSE 'INCLUDE (' + mid.included_columns + ')' 
 -- END + ';' AS CreateIndexStatement
  FROM sys.tables st
  join sys.indexes si
    on st.object_id = si.object_id
CROSS APPLY (
            SELECT sc.Name + ', '
              FROM sys.index_columns ic
              JOIN sys.columns sc
                on ic.object_id = sc.object_id
               AND ic.column_id = sc.column_id
             WHERE si.object_id = ic.object_id
               AND is_included_column = 0
               and si.index_id = ic.index_id
               and is_descending_key = 0
             ORDER BY ic.Key_Ordinal
              FOR XML PATH('') ) ixa (ixColumns_asc)
CROSS APPLY (
            SELECT sc.Name + ', '
              FROM sys.index_columns ic
              JOIN sys.columns sc
                on ic.object_id = sc.object_id
               AND ic.column_id = sc.column_id
             WHERE si.object_id = ic.object_id
               AND is_included_column = 0
               and si.index_id = ic.index_id
               and is_descending_key = 1
             ORDER BY ic.Key_Ordinal
              FOR XML PATH('') ) ixd (ixColumns_desc)
CROSS APPLY (
            SELECT sc2.Name + ', '
              FROM sys.index_columns ic2 
			  JOIN sys.columns sc2 
			   on ic2.object_id = sc2.object_id
               AND ic2.column_id = sc2.column_id
             WHERE si.object_id = ic2.object_id
               AND is_included_column = 1
               and si.index_id = ic2.index_id
             ORDER BY ic2.Key_Ordinal
              FOR XML PATH('') ) nc (includedColumns)
CROSS APPLY (
            SELECT sc.Name + ', '
              FROM sys.index_columns ic
              JOIN sys.columns sc
                on ic.object_id = sc.object_id
               AND ic.column_id = sc.column_id
             WHERE si.object_id = ic.object_id
               AND is_included_column = 0
               and si.index_id = ic.index_id
             ORDER BY ic.Key_Ordinal
              FOR XML PATH('') ) ixal (ixColumns_all)
where si.Type_Desc<>'HEAP'