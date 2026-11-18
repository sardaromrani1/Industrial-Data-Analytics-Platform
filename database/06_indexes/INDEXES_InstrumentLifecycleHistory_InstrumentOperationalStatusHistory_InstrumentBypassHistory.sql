USE ComprehensiveInstrumentationDB_New;
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName,

    i.name AS IndexName,
    i.type_desc AS IndexType,

    i.is_primary_key,
    i.is_unique,
    i.is_disabled,

    ic.key_ordinal,
    ic.is_included_column,

    c.name AS ColumnName

FROM sys.tables t

INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id

INNER JOIN sys.indexes i
    ON i.object_id = t.object_id

INNER JOIN sys.index_columns ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id

INNER JOIN sys.columns c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id

WHERE
    s.name = 'event'

AND t.name IN
(
    'InstrumentLifecycle',
    'InstrumentOperationalStatusHistory',
    'InstrumentBypassHistory'
)

AND i.index_id > 0

ORDER BY
    t.name,
    i.index_id,
    ic.is_included_column,
    ic.key_ordinal;
GO