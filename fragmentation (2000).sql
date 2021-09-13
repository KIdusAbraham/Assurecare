--CREATE PROCEDURE [dbo].[sp_selective re-index] AS --RDBAE Script For Selective Re-indexing For All Databases In 2000 Created 05/29/12
--Modified

-- Declare variables

SET NOCOUNT ON;
DECLARE @tablename varchar(255)
DECLARE @indexname varchar(255)
DECLARE @execstr   varchar(400)
DECLARE @objectid  int;
DECLARE @indexid   int;
DECLARE @frag      decimal;
DECLARE @maxfrag   decimal;
declare @database_name sysname
declare @cmd nvarchar(2000)
declare @cmd2 nvarchar(2000)
declare @schema_name sysname
DECLARE DatabaseCursor CURSOR FOR  

-- Database Cursor
--SELECT name FROM MASTER.dbo.sysdatabases
--WHERE name <> 'tempdb'--not in ('tempdb','master','msdb','model') 
select name from sysdatabases
where name not in ('master','model','msdb','tempdb','pubs','Northwind')
and DATABASEPROPERTYEX(name,'status')='ONLINE' and DATABASEPROPERTYEX(name,'updateability')<>'READ_ONLY'
open DatabaseCursor 
fetch next from databasecursor into @database_name
while @@fetch_status = 0 
begin


-- Decide on the maximum fragmentation to allow for.
SELECT @maxfrag = 20.0;


--Create The Table
create table #base_tables
(
table_catalog nvarchar(128),
table_schema nvarchar(128),
table_name nvarchar(128),
table_type nvarchar(10)
)


set @cmd = 'SELECT * ' + ' FROM ' + @database_name + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ' + '''' + 'BASE TABLE' + ''''


insert into #base_tables
exec sp_executesql @cmd


-- Table Cursor for database
DECLARE tables CURSOR FOR
   SELECT TABLE_SCHEMA + '.' + TABLE_NAME
   FROM #base_tables
   WHERE TABLE_TYPE = 'BASE TABLE';




-- Create the table.
CREATE TABLE #fraglist (
   ObjectName char(255),
   ObjectId int,
   IndexName char(255),
   IndexId int,
   Lvl int,
   CountPages int,
   CountRows int,
   MinRecSize int,
   MaxRecSize int,
   AvgRecSize int,
   ForRecCount int,
   Extents int,
   ExtentSwitches int,
   AvgFreeBytes int,
   AvgPageDensity int,
   ScanDensity decimal,
   BestCount int,
   ActualCount int,
   LogicalFrag decimal,
   ExtentFrag decimal)

-- Open the cursor.
OPEN tables;

-- Loop through all the tables in the database.
FETCH NEXT
   FROM tables
   INTO @tablename;

WHILE @@FETCH_STATUS = 0
BEGIN
-- Do the showcontig of all indexes of the table
   
   set @cmd2 = 'use ' + @database_name + '; DBCC SHOWCONTIG (' + '''' + @tablename + '''' + ') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS'
   
   INSERT INTO #fraglist 
   execute sp_executesql @cmd2

   FETCH NEXT
      FROM tables
      INTO @tablename;
END;

-- Close and deallocate the cursor.
CLOSE tables;
DEALLOCATE tables;


-- Declare the cursor for the list of indexes to be defragged.
DECLARE indexes CURSOR FOR
   SELECT ObjectName, ObjectId, IndexId, LogicalFrag,indexname
   FROM #fraglist
   WHERE (LogicalFrag >= @maxfrag) and (IndexName <> '')

select objectname, logicalfrag, (countpages*8/1024) as indexsize_MB from #fraglist ORDER BY LOGICALFRAG DESC
-- Delete the temporary table.
--DROP TABLE #fraglist;
--drop table #base_tables

--Database Cursor Closed
                fetch next from databasecursor into @database_name
end 
close DatabaseCursor
deallocate DatabaseCursor
GO

