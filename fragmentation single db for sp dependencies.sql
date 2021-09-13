--what the object depends on
SELECT referenced_schema_name, referenced_entity_name
into #refs
FROM sys.dm_sql_referenced_entities ('dbo.WorkQueueTaskSearch', 'OBJECT')
where referenced_minor_name is null and referenced_class_desc <> 'TYPE'

SELECT db_name(db_id()), s.name, t.name,i.name, ps.avg_fragmentation_in_percent, page_count AS [Page Count]
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL,'SAMPLED') AS ps
join sys.indexes i on ps.index_id = i.index_id and ps.object_id=i.object_id
 join sys.tables t on t.object_id = i.object_id
 join sys.schemas s on t.schema_id = s.schema_id
 join #refs r on t.name = r.referenced_entity_name and s.name = r.referenced_schema_name
where ps.index_type_desc<>'HEAP'
order by ps.avg_fragmentation_in_percent desc

drop table #refs