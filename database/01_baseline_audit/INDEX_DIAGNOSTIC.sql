/* ============================================================
   INDEX DIAGNOSTIC - READ ONLY
   ============================================================ */

SET NOCOUNT ON;

SELECT
    DB_NAME() AS CurrentDatabase,
    @@SERVERNAME AS ServerName;


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.index_id AS IndexId,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_disabled AS IsDisabled,
    i.is_hypothetical AS IsHypothetical
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
WHERE
    (
        s.name = N'rel'
        AND t.name = N'SparePartInstruments'
    )
    OR
    (
        s.name = N'rel'
        AND t.name = N'SparePartInstrumentTypes'
    )
ORDER BY
    t.name,
    i.index_id;


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    ic.key_ordinal AS KeyOrdinal,
    c.name AS ColumnName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
INNER JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
   AND i.index_id = ic.index_id
INNER JOIN sys.columns c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE
    (
        s.name = N'rel'
        AND t.name = N'SparePartInstruments'
        AND i.name = N'IX_SparePartInstruments_InstrumentId_SparePartId'
    )
    OR
    (
        s.name = N'rel'
        AND t.name = N'SparePartInstrumentTypes'
        AND i.name = N'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId'
    )
ORDER BY
    t.name,
    i.name,
    ic.key_ordinal;