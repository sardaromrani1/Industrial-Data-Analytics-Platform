USE ComprehensiveInstrumentationDB_New;
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    c.column_id AS ColumnId,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
INNER JOIN sys.columns AS c
    ON t.object_id = c.object_id
INNER JOIN sys.types AS ty
    ON c.user_type_id = ty.user_type_id
WHERE
    s.name = N'event'
    AND t.name IN
    (
        N'InstrumentLifecycle',
        N'InstrumentOperationalStatusHistory',
        N'InstrumentBypassHistory'
    )
ORDER BY
    t.name,
    c.column_id;
GO