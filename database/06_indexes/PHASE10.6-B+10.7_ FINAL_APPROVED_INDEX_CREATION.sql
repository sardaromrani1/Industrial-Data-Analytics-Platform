/* ============================================================
   INDUSTRIAL DATA ANALYTICS PLATFORM
   PHASE 10.6-B + 10.7
   FINAL APPROVED INDEX CREATION

   PURPOSE:
       Create ONLY the two indexes approved by the
       Final Index Approval Preflight.

   APPROVED INDEXES:
       1. rel.SparePartInstruments
          (InstrumentId, SparePartId)

       2. rel.SparePartInstrumentTypes
          (InstrumentTypeId, SparePartId)

   SAFETY:
       - READ metadata first
       - No DROP INDEX
       - No ALTER TABLE
       - No modification of existing indexes
       - No INCLUDE columns
       - No other index creation
       - Existing indexes are preserved
       - Exact key-equivalent indexes are not recreated
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '============================================================';
PRINT 'PHASE 10.6-B + 10.7';
PRINT 'FINAL APPROVED INDEX CREATION';
PRINT '============================================================';


/* ============================================================
   PART 1 — REQUIRED OBJECT PRECHECK
   ============================================================ */

PRINT '';
PRINT 'PART 1 — REQUIRED TABLE PRECHECK';


IF OBJECT_ID(N'rel.SparePartInstruments', N'U') IS NULL
BEGIN
    THROW 51001,
        'ABORTED: rel.SparePartInstruments does not exist.',
        1;
END;


IF OBJECT_ID(N'rel.SparePartInstrumentTypes', N'U') IS NULL
BEGIN
    THROW 51002,
        'ABORTED: rel.SparePartInstrumentTypes does not exist.',
        1;
END;


PRINT 'PASS: Both required tables exist.';


/* ============================================================
   PART 2 — REQUIRED COLUMN PRECHECK
   ============================================================ */

PRINT '';
PRINT 'PART 2 — REQUIRED COLUMN PRECHECK';


IF COL_LENGTH(N'rel.SparePartInstruments', N'InstrumentId') IS NULL
BEGIN
    THROW 51003,
        'ABORTED: rel.SparePartInstruments.InstrumentId does not exist.',
        1;
END;


IF COL_LENGTH(N'rel.SparePartInstruments', N'SparePartId') IS NULL
BEGIN
    THROW 51004,
        'ABORTED: rel.SparePartInstruments.SparePartId does not exist.',
        1;
END;


IF COL_LENGTH(N'rel.SparePartInstrumentTypes', N'InstrumentTypeId') IS NULL
BEGIN
    THROW 51005,
        'ABORTED: rel.SparePartInstrumentTypes.InstrumentTypeId does not exist.',
        1;
END;


IF COL_LENGTH(N'rel.SparePartInstrumentTypes', N'SparePartId') IS NULL
BEGIN
    THROW 51006,
        'ABORTED: rel.SparePartInstrumentTypes.SparePartId does not exist.',
        1;
END;


PRINT 'PASS: All required columns exist.';


/* ============================================================
   PART 3 — TARGET INDEX NAME PRECHECK
   ============================================================ */

PRINT '';
PRINT 'PART 3 — TARGET INDEX NAME PRECHECK';


IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'rel.SparePartInstruments')
      AND name = N'IX_SparePartInstruments_InstrumentId_SparePartId'
)
BEGIN
    THROW 51007,
        'ABORTED: Target index IX_SparePartInstruments_InstrumentId_SparePartId already exists.',
        1;
END;


IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'rel.SparePartInstrumentTypes')
      AND name = N'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId'
)
BEGIN
    THROW 51008,
        'ABORTED: Target index IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId already exists.',
        1;
END;


PRINT 'PASS: Neither target index name currently exists.';


/* ============================================================
   PART 4 — EXACT KEY EQUIVALENCE PRECHECK
   ============================================================ */

PRINT '';
PRINT 'PART 4 — EXISTING INDEX KEY EQUIVALENCE PRECHECK';


/*
    Check whether an equivalent index already exists,
    regardless of its name.

    Target 1:
        InstrumentId ASC
        SparePartId ASC

    Target 2:
        InstrumentTypeId ASC
        SparePartId ASC
*/


IF EXISTS
(
    SELECT 1
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic1
        ON i.object_id = ic1.object_id
       AND i.index_id  = ic1.index_id
    INNER JOIN sys.columns c1
        ON ic1.object_id = c1.object_id
       AND ic1.column_id = c1.column_id

    INNER JOIN sys.index_columns ic2
        ON i.object_id = ic2.object_id
       AND i.index_id  = ic2.index_id
       AND ic2.key_ordinal = 2
    INNER JOIN sys.columns c2
        ON ic2.object_id = c2.object_id
       AND ic2.column_id = c2.column_id

    WHERE i.object_id = OBJECT_ID(N'rel.SparePartInstruments')
      AND i.is_hypothetical = 0
      AND i.type IN (1,2)
      AND ic1.key_ordinal = 1
      AND c1.name = N'InstrumentId'
      AND c2.name = N'SparePartId'

      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.index_columns ix
          WHERE ix.object_id = i.object_id
            AND ix.index_id  = i.index_id
            AND ix.key_ordinal > 2
      )
)
BEGIN
    THROW 51009,
        'ABORTED: An equivalent key index already exists on rel.SparePartInstruments.',
        1;
END;


IF EXISTS
(
    SELECT 1
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic1
        ON i.object_id = ic1.object_id
       AND i.index_id  = ic1.index_id
    INNER JOIN sys.columns c1
        ON ic1.object_id = c1.object_id
       AND ic1.column_id = c1.column_id

    INNER JOIN sys.index_columns ic2
        ON i.object_id = ic2.object_id
       AND i.index_id  = ic2.index_id
       AND ic2.key_ordinal = 2
    INNER JOIN sys.columns c2
        ON ic2.object_id = c2.object_id
       AND ic2.column_id = c2.column_id

    WHERE i.object_id = OBJECT_ID(N'rel.SparePartInstrumentTypes')
      AND i.is_hypothetical = 0
      AND i.type IN (1,2)
      AND ic1.key_ordinal = 1
      AND c1.name = N'InstrumentTypeId'
      AND c2.name = N'SparePartId'

      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.index_columns ix
          WHERE ix.object_id = i.object_id
            AND ix.index_id  = i.index_id
            AND ix.key_ordinal > 2
      )
)
BEGIN
    THROW 51010,
        'ABORTED: An equivalent key index already exists on rel.SparePartInstrumentTypes.',
        1;
END;


PRINT 'PASS: No exact equivalent key index exists.';


/* ============================================================
   PART 5 — DISPLAY CURRENT INDEX STATE
   ============================================================ */

PRINT '';
PRINT 'PART 5 — CURRENT INDEX STATE';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.index_id AS IndexId,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique_constraint AS IsUniqueConstraint
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
WHERE s.name = N'rel'
  AND t.name IN
  (
      N'SparePartInstruments',
      N'SparePartInstrumentTypes'
  )
  AND i.index_id > 0
ORDER BY
    t.name,
    i.index_id;


/* ============================================================
   PART 6 — FINAL CREATION CONFIRMATION
   ============================================================ */

PRINT '';
PRINT 'PART 6 — FINAL CREATION DECISION';

PRINT 'APPROVED INDEX 1:';
PRINT '  rel.SparePartInstruments';
PRINT '  (InstrumentId, SparePartId)';

PRINT 'APPROVED INDEX 2:';
PRINT '  rel.SparePartInstrumentTypes';
PRINT '  (InstrumentTypeId, SparePartId)';

PRINT '';
PRINT 'No DROP INDEX operation will be performed.';
PRINT 'No existing index will be modified.';
PRINT 'No other index will be created.';


/* ============================================================
   PART 7 — CREATE INDEX 1
   ============================================================ */

PRINT '';
PRINT 'PART 7 — CREATING INDEX 1';


CREATE NONCLUSTERED INDEX
    IX_SparePartInstruments_InstrumentId_SparePartId
ON
    rel.SparePartInstruments
(
    InstrumentId,
    SparePartId
);


PRINT 'PASS: Index 1 created successfully.';


/* ============================================================
   PART 8 — CREATE INDEX 2
   ============================================================ */

PRINT '';
PRINT 'PART 8 — CREATING INDEX 2';


CREATE NONCLUSTERED INDEX
    IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId
ON
    rel.SparePartInstrumentTypes
(
    InstrumentTypeId,
    SparePartId
);


PRINT 'PASS: Index 2 created successfully.';


/* ============================================================
   PART 9 — POST-CREATION VALIDATION
   ============================================================ */

PRINT '';
PRINT 'PART 9 — POST-CREATION VALIDATION';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
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
   PART 10 — POST-CREATION KEY COLUMN VALIDATION
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
    )
    OR
    (
        s.name = N'rel'
        AND t.name = N'SparePartInstrumentTypes'
        AND i.name = N'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId'
    )
    AND ic.key_ordinal > 0
ORDER BY
    t.name,
    i.name,
    ic.key_ordinal;


/* ============================================================
   PART 11 — FINAL STATUS
   ============================================================ */

PRINT '';
PRINT '============================================================';
PRINT 'PHASE 10.6-B + 10.7 FINAL INDEX CREATION';
PRINT 'COMPLETED';
PRINT '============================================================';
PRINT '';
PRINT 'Created indexes: 2';
PRINT 'Deferred indexes: 6';
PRINT 'Dropped indexes: 0';
PRINT 'Modified existing indexes: 0';
PRINT '============================================================';
