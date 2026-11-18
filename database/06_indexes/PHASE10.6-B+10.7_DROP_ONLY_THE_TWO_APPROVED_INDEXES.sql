/* ============================================================
   PHASE 10.6 B + 10.7
   DROP ONLY THE TWO APPROVED INDEXES

   WARNING:
       This script removes ONLY the two specified indexes.
       No other index, constraint, FK, or table is modified.
   ============================================================ */

USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;

PRINT '============================================================';
PRINT 'DROP APPROVED INDEXES';
PRINT '============================================================';


/* ============================================================
   PART 1 — CHECK CURRENT INDEXES
   ============================================================ */

PRINT '';
PRINT 'PART 1 — CURRENT INDEX CHECK';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
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
    );


/* ============================================================
   PART 2 — DROP INDEX 1
   ============================================================ */

PRINT '';
PRINT 'PART 2 — DROP INDEX 1';

IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'rel.SparePartInstruments')
      AND name = N'IX_SparePartInstruments_InstrumentId_SparePartId'
)
BEGIN

    DROP INDEX
        IX_SparePartInstruments_InstrumentId_SparePartId
    ON
        rel.SparePartInstruments;

    PRINT 'PASS: Index 1 dropped successfully.';

END
ELSE
BEGIN

    PRINT 'INFO: Index 1 does not exist. Nothing to drop.';

END;


/* ============================================================
   PART 3 — DROP INDEX 2
   ============================================================ */

PRINT '';
PRINT 'PART 3 — DROP INDEX 2';

IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'rel.SparePartInstrumentTypes')
      AND name = N'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId'
)
BEGIN

    DROP INDEX
        IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId
    ON
        rel.SparePartInstrumentTypes;

    PRINT 'PASS: Index 2 dropped successfully.';

END
ELSE
BEGIN

    PRINT 'INFO: Index 2 does not exist. Nothing to drop.';

END;


/* ============================================================
   PART 4 — POST-DROP VALIDATION
   ============================================================ */

PRINT '';
PRINT 'PART 4 — POST-DROP VALIDATION';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
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
    );


PRINT '';
PRINT '============================================================';
PRINT 'DROP INDEX VALIDATION COMPLETED';
PRINT '============================================================';