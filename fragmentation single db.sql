SELECT db_name(db_id()), s.name, t.name,i.name, ps.avg_fragmentation_in_percent, page_count AS [Page Count]
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL,'SAMPLED') AS ps
join sys.indexes i on ps.index_id = i.index_id and ps.object_id=i.object_id
 join sys.tables t on t.object_id = i.object_id
 join sys.schemas s on t.schema_id = s.schema_id
where ps.index_type_desc<>'HEAP'
order by ps.avg_fragmentation_in_percent desc
