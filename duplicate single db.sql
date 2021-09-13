/* Duplicate Indexes */
WITH    indexcols
          AS ( SELECT
                object_id AS id ,
                index_id AS indid ,
                name ,
                ( SELECT
                    CASE keyno
                      WHEN 0 THEN NULL
                      ELSE colid
                    END AS [data()]
                  FROM
                    sys.sysindexkeys AS k
                  WHERE
                    k.id = i.object_id
                    AND k.indid = i.index_id
                  ORDER BY
                    keyno ,
                    colid
                FOR
                  XML PATH('')
                ) AS cols ,
                ( SELECT
                    CASE keyno
                      WHEN 0 THEN colid
                      ELSE NULL
                    END AS [data()]
                  FROM
                    sys.sysindexkeys AS k
                  WHERE
                    k.id = i.object_id
                    AND k.indid = i.index_id
                  ORDER BY
                    colid
                FOR
                  XML PATH('')
                ) AS inc
               FROM
                sys.indexes AS i
             )
    SELECT
                                @@servername AS [Server Name],
                                db_name() AS [Database Name],
        object_schema_name(c1.id) + '.' + OBJECT_NAME(c1.id) AS [Table Name],
        c1.name AS [Index Name],
        c2.name AS [Duplicate Index Name]
    FROM
        indexcols AS c1
        JOIN indexcols AS c2 ON c1.id = c2.id
                                AND c1.indid < c2.indid
                                AND c1.cols = c2.cols
                                AND c1.inc = c2.inc
