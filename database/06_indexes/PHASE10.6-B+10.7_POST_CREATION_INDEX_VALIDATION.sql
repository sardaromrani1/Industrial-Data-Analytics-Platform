/* ============================================================
   PHASE 10.6-B + 10.7
   POST-CREATION INDEX VALIDATION

   READ-ONLY
   No CREATE
   No DROP
   No ALTER
   ============================================================ */

SET NOCOUNT ON;

PRINT '============================================================';
PRINT 'POST-CREATION INDEX VALIDATION';
PRINT '============================================================';


/* ============================================================
   PART 9 — INDEX EXISTENCE AND STATUS
   ============================================================ */

PRINT '';
PRINT 'PART 9 — INDEX EXISTENCE AND STATUS';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.index_id AS IndexId,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique_constraint AS IsUniqueConstraint,
    i.is_disabled AS IsDisabled
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
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
    i.name;


/* ============================================================
   PART 10 — INDEX KEY COLUMN VALIDATION
   ============================================================ */

PRINT '';
PRINT 'PART 10 — INDEX KEY COLUMN VALIDATION';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    ic.key_ordinal AS KeyOrdinal,
    c.name AS ColumnName,
    CASE
        WHEN ic.is_descending_key = 1
            THEN 'DESC'
        ELSE 'ASC'
    END AS SortDirection
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
        AND ic.key_ordinal > 0
    )
    OR
    (
        s.name = N'rel'
        AND t.name = N'SparePartInstrumentTypes'
        AND i.name = N'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId'
        AND ic.key_ordinal > 0
    )
ORDER BY
    t.name,
    i.name,
    ic.key_ordinal;