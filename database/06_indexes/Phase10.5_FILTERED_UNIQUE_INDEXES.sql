USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   PHASE 10.5 — FILTERED UNIQUE INDEXES
   Temporal Open-Record Integrity
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.5 — PREFLIGHT';
PRINT '============================================================';


/* ------------------------------------------------------------
   10.5.1 PRECHECK — Required tables and columns
   ------------------------------------------------------------ */

IF OBJECT_ID(N'event.InstrumentLifecycle', N'U') IS NULL
    THROW 51001, 'Required table event.InstrumentLifecycle does not exist.', 1;

IF OBJECT_ID(N'event.InstrumentOperationalStatusHistory', N'U') IS NULL
    THROW 51002, 'Required table event.InstrumentOperationalStatusHistory does not exist.', 1;

IF OBJECT_ID(N'event.InstrumentBypassHistory', N'U') IS NULL
    THROW 51003, 'Required table event.InstrumentBypassHistory does not exist.', 1;


IF COL_LENGTH(N'event.InstrumentLifecycle', N'InstrumentId') IS NULL
    THROW 51004, 'event.InstrumentLifecycle.InstrumentId does not exist.', 1;

IF COL_LENGTH(N'event.InstrumentLifecycle', N'EffectiveTo') IS NULL
    THROW 51005, 'event.InstrumentLifecycle.EffectiveTo does not exist.', 1;


IF COL_LENGTH(N'event.InstrumentOperationalStatusHistory', N'InstrumentId') IS NULL
    THROW 51006, 'event.InstrumentOperationalStatusHistory.InstrumentId does not exist.', 1;

IF COL_LENGTH(N'event.InstrumentOperationalStatusHistory', N'EffectiveTo') IS NULL
    THROW 51007, 'event.InstrumentOperationalStatusHistory.EffectiveTo does not exist.', 1;


IF COL_LENGTH(N'event.InstrumentBypassHistory', N'InstrumentId') IS NULL
    THROW 51008, 'event.InstrumentBypassHistory.InstrumentId does not exist.', 1;

IF COL_LENGTH(N'event.InstrumentBypassHistory', N'BypassEndDateTime') IS NULL
    THROW 51009, 'event.InstrumentBypassHistory.BypassEndDateTime does not exist.', 1;


PRINT 'Preflight checks passed.';
GO


/* ============================================================
   10.5.2 — AUDIT EXISTING OPEN-RECORD DUPLICATES
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.5 — EXISTING OPEN-RECORD AUDIT';
PRINT '============================================================';


/* InstrumentLifecycle */

SELECT
    InstrumentId,
    COUNT(*) AS OpenRecordCount
FROM event.InstrumentLifecycle
WHERE EffectiveTo IS NULL
GROUP BY InstrumentId
HAVING COUNT(*) > 1;
GO


/* InstrumentOperationalStatusHistory */

SELECT
    InstrumentId,
    COUNT(*) AS OpenRecordCount
FROM event.InstrumentOperationalStatusHistory
WHERE EffectiveTo IS NULL
GROUP BY InstrumentId
HAVING COUNT(*) > 1;
GO


/* InstrumentBypassHistory */

SELECT
    InstrumentId,
    COUNT(*) AS OpenRecordCount
FROM event.InstrumentBypassHistory
WHERE BypassEndDateTime IS NULL
GROUP BY InstrumentId
HAVING COUNT(*) > 1;
GO


/* ============================================================
   10.5.3 — CREATE FILTERED UNIQUE INDEXES
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.5 — CREATE FILTERED UNIQUE INDEXES';
PRINT '============================================================';


/* ------------------------------------------------------------
   Instrument Lifecycle
   Maximum one open lifecycle record per Instrument
   ------------------------------------------------------------ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'event.InstrumentLifecycle')
      AND name = N'UX_InstrumentLifecycle_OpenRecord'
)
BEGIN

    CREATE UNIQUE NONCLUSTERED INDEX UX_InstrumentLifecycle_OpenRecord
    ON event.InstrumentLifecycle (InstrumentId)
    WHERE EffectiveTo IS NULL;

    PRINT 'Created UX_InstrumentLifecycle_OpenRecord';

END
ELSE
BEGIN

    PRINT 'UX_InstrumentLifecycle_OpenRecord already exists';

END;
GO


/* ------------------------------------------------------------
   Operational Status History
   Maximum one open operational-status record per Instrument
   ------------------------------------------------------------ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'event.InstrumentOperationalStatusHistory')
      AND name = N'UX_InstrumentOperationalStatusHistory_OpenRecord'
)
BEGIN

    CREATE UNIQUE NONCLUSTERED INDEX UX_InstrumentOperationalStatusHistory_OpenRecord
    ON event.InstrumentOperationalStatusHistory (InstrumentId)
    WHERE EffectiveTo IS NULL;

    PRINT 'Created UX_InstrumentOperationalStatusHistory_OpenRecord';

END
ELSE
BEGIN

    PRINT 'UX_InstrumentOperationalStatusHistory_OpenRecord already exists';

END;
GO


/* ------------------------------------------------------------
   Bypass History
   Maximum one open bypass record per Instrument
   ------------------------------------------------------------ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'event.InstrumentBypassHistory')
      AND name = N'UX_InstrumentBypassHistory_OpenRecord'
)
BEGIN

    CREATE UNIQUE NONCLUSTERED INDEX UX_InstrumentBypassHistory_OpenRecord
    ON event.InstrumentBypassHistory (InstrumentId)
    WHERE BypassEndDateTime IS NULL;

    PRINT 'Created UX_InstrumentBypassHistory_OpenRecord';

END
ELSE
BEGIN

    PRINT 'UX_InstrumentBypassHistory_OpenRecord already exists';

END;
GO


/* ============================================================
   10.5.4 — INDEX VALIDATION
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.5 — INDEX VALIDATION';
PRINT '============================================================';


SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_disabled AS IsDisabled,
    i.has_filter AS HasFilter,
    i.filter_definition AS FilterDefinition
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE
    s.name = N'event'
    AND
    (
        i.name = N'UX_InstrumentLifecycle_OpenRecord'
        OR
        i.name = N'UX_InstrumentOperationalStatusHistory_OpenRecord'
        OR
        i.name = N'UX_InstrumentBypassHistory_OpenRecord'
    )
ORDER BY
    t.name;
GO


/* ============================================================
   10.5.5 — FINAL OPEN-RECORD VALIDATION
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.5 — FINAL VALIDATION';
PRINT '============================================================';


SELECT
    'InstrumentLifecycle' AS TemporalTable,
    COUNT(*) AS DuplicateOpenGroups
FROM
(
    SELECT InstrumentId
    FROM event.InstrumentLifecycle
    WHERE EffectiveTo IS NULL
    GROUP BY InstrumentId
    HAVING COUNT(*) > 1
) AS X

UNION ALL

SELECT
    'InstrumentOperationalStatusHistory',
    COUNT(*)
FROM
(
    SELECT InstrumentId
    FROM event.InstrumentOperationalStatusHistory
    WHERE EffectiveTo IS NULL
    GROUP BY InstrumentId
    HAVING COUNT(*) > 1
) AS X

UNION ALL

SELECT
    'InstrumentBypassHistory',
    COUNT(*)
FROM
(
    SELECT InstrumentId
    FROM event.InstrumentBypassHistory
    WHERE BypassEndDateTime IS NULL
    GROUP BY InstrumentId
    HAVING COUNT(*) > 1
) AS X;
GO


PRINT '============================================================';
PRINT 'PHASE 10.5 COMPLETED';
PRINT '============================================================';
GO