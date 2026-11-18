/* =====================================================================
   INDUSTRIAL DATA ANALYTICS PLATFORM
   PHASE 10.4 — FINAL BUSINESS RULE CONSTRAINTS

   Database:
       ComprehensiveInstrumentationDB_New

   Purpose:
       Enforce confirmed business rules after:

           Phase 10.1 — Deferred Foreign Keys
           Phase 10.2 — Cross-Table Integrity
           Phase 10.3 — Temporal Integrity

   Scope:
       BR-02  Trip / Instrument / ProcessUnit consistency
       BR-08  SparePartUsage.QuantityUsed > 0
       BR-10  CalibrationTestPoints.TestSequence > 0
       BR-11A Instruments.MeasurementRangeMax >= MeasurementRangeMin
       BR-11B Instruments.OutputRangeMax >= OutputRangeMin
       BR-13  InstrumentRedundancy InstrumentId1 <> InstrumentId2
       BR-15  SparePartInterchangeability SparePartId1 <> SparePartId2

   IMPORTANT:
       - This script modifies database constraints/triggers.
       - Execute only after reviewing the preflight/audit output.
       - The entire operation is transactional.
       - If an existing violation is found, execution stops before
         enforcement.
   ===================================================================== */

USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


/* =====================================================================
   10.4.0 — PREFLIGHT
   ===================================================================== */

PRINT '============================================================';
PRINT 'PHASE 10.4 — BUSINESS RULE CONSTRAINTS';
PRINT '10.4.0 PREFLIGHT';
PRINT '============================================================';


/* ---------------------------------------------------------------------
   Required tables
   --------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.Instruments', N'U') IS NULL
    THROW 51000, 'Missing table: dbo.Instruments', 1;

IF OBJECT_ID(N'dbo.TripsInterlocks', N'U') IS NULL
    THROW 51000, 'Missing table: dbo.TripsInterlocks', 1;

IF OBJECT_ID(N'rel.TripInstruments', N'U') IS NULL
    THROW 51000, 'Missing table: rel.TripInstruments', 1;

IF OBJECT_ID(N'rel.InstrumentRedundancy', N'U') IS NULL
    THROW 51000, 'Missing table: rel.InstrumentRedundancy', 1;

IF OBJECT_ID(N'rel.SparePartInterchangeability', N'U') IS NULL
    THROW 51000, 'Missing table: rel.SparePartInterchangeability', 1;

IF OBJECT_ID(N'event.CalibrationTestPoints', N'U') IS NULL
    THROW 51000, 'Missing table: event.CalibrationTestPoints', 1;

IF OBJECT_ID(N'event.SparePartUsage', N'U') IS NULL
    THROW 51000, 'Missing table: event.SparePartUsage', 1;


/* ---------------------------------------------------------------------
   Required columns
   --------------------------------------------------------------------- */

DECLARE @RequiredColumns TABLE
(
    SchemaName SYSNAME,
    TableName  SYSNAME,
    ColumnName SYSNAME
);

INSERT INTO @RequiredColumns
VALUES
    ('dbo',   'Instruments',                    'InstrumentId'),
    ('dbo',   'Instruments',                    'UnitId'),
    ('dbo',   'Instruments',                    'MeasurementRangeMin'),
    ('dbo',   'Instruments',                    'MeasurementRangeMax'),
    ('dbo',   'Instruments',                    'OutputRangeMin'),
    ('dbo',   'Instruments',                    'OutputRangeMax'),

    ('dbo',   'TripsInterlocks',                'TripId'),
    ('dbo',   'TripsInterlocks',                'ProcessUnitId'),

    ('rel',   'TripInstruments',                'TripId'),
    ('rel',   'TripInstruments',                'InstrumentId'),

    ('rel',   'InstrumentRedundancy',           'InstrumentId1'),
    ('rel',   'InstrumentRedundancy',           'InstrumentId2'),

    ('rel',   'SparePartInterchangeability',    'SparePartId1'),
    ('rel',   'SparePartInterchangeability',    'SparePartId2'),

    ('event', 'CalibrationTestPoints',          'CalibrationId'),
    ('event', 'CalibrationTestPoints',          'TestSequence'),

    ('event', 'SparePartUsage',                 'QuantityUsed');


DECLARE
    @SchemaName SYSNAME,
    @TableName  SYSNAME,
    @ColumnName SYSNAME;

DECLARE RequiredColumnCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT
    SchemaName,
    TableName,
    ColumnName
FROM @RequiredColumns;

OPEN RequiredColumnCursor;

FETCH NEXT FROM RequiredColumnCursor
INTO @SchemaName, @TableName, @ColumnName;

WHILE @@FETCH_STATUS = 0
BEGIN

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.tables t
        INNER JOIN sys.schemas s
            ON s.schema_id = t.schema_id
        INNER JOIN sys.columns c
            ON c.object_id = t.object_id
        WHERE s.name = @SchemaName
          AND t.name = @TableName
          AND c.name = @ColumnName
    )
    BEGIN
        CLOSE RequiredColumnCursor;
        DEALLOCATE RequiredColumnCursor;

        THROW 51001,
            'Required column is missing from Phase 10.4 target schema.',
            1;
    END;

    FETCH NEXT FROM RequiredColumnCursor
    INTO @SchemaName, @TableName, @ColumnName;
END;

CLOSE RequiredColumnCursor;
DEALLOCATE RequiredColumnCursor;


PRINT 'Preflight table/column verification: PASSED';


/* =====================================================================
   10.4.1 — DATA AUDIT
   ===================================================================== */

PRINT '';
PRINT '============================================================';
PRINT '10.4.1 DATA AUDIT';
PRINT '============================================================';


/* ---------------------------------------------------------------------
   BR-11A
   Measurement Range
   --------------------------------------------------------------------- */

DECLARE @BR11A_Count BIGINT;

SELECT @BR11A_Count = COUNT_BIG(*)
FROM dbo.Instruments
WHERE MeasurementRangeMin IS NOT NULL
  AND MeasurementRangeMax IS NOT NULL
  AND MeasurementRangeMax < MeasurementRangeMin;

PRINT 'BR-11A Measurement Range violations: '
    + CAST(@BR11A_Count AS VARCHAR(30));


/* ---------------------------------------------------------------------
   BR-11B
   Output Range
   --------------------------------------------------------------------- */

DECLARE @BR11B_Count BIGINT;

SELECT @BR11B_Count = COUNT_BIG(*)
FROM dbo.Instruments
WHERE OutputRangeMin IS NOT NULL
  AND OutputRangeMax IS NOT NULL
  AND OutputRangeMax < OutputRangeMin;

PRINT 'BR-11B Output Range violations: '
    + CAST(@BR11B_Count AS VARCHAR(30));


/* ---------------------------------------------------------------------
   BR-08
   SparePartUsage.QuantityUsed > 0
   --------------------------------------------------------------------- */

DECLARE @BR08_Count BIGINT;

SELECT @BR08_Count = COUNT_BIG(*)
FROM event.SparePartUsage
WHERE QuantityUsed <= 0;

PRINT 'BR-08 QuantityUsed violations: '
    + CAST(@BR08_Count AS VARCHAR(30));


/* ---------------------------------------------------------------------
   BR-10
   CalibrationTestPoints.TestSequence > 0
   --------------------------------------------------------------------- */

DECLARE @BR10_Count BIGINT;

SELECT @BR10_Count = COUNT_BIG(*)
FROM event.CalibrationTestPoints
WHERE TestSequence <= 0;

PRINT 'BR-10 TestSequence violations: '
    + CAST(@BR10_Count AS VARCHAR(30));


/* ---------------------------------------------------------------------
   BR-13
   InstrumentRedundancy InstrumentId1 <> InstrumentId2
   --------------------------------------------------------------------- */

DECLARE @BR13_Count BIGINT;

SELECT @BR13_Count = COUNT_BIG(*)
FROM rel.InstrumentRedundancy
WHERE InstrumentId1 = InstrumentId2;

PRINT 'BR-13 Redundancy self-reference violations: '
    + CAST(@BR13_Count AS VARCHAR(30));


/* ---------------------------------------------------------------------
   BR-15
   SparePartInterchangeability SparePartId1 <> SparePartId2
   --------------------------------------------------------------------- */

DECLARE @BR15_Count BIGINT;

SELECT @BR15_Count = COUNT_BIG(*)
FROM rel.SparePartInterchangeability
WHERE SparePartId1 = SparePartId2;

PRINT 'BR-15 Spare-part self-reference violations: '
    + CAST(@BR15_Count AS VARCHAR(30));


/* =====================================================================
   BR-02
   TRIP / INSTRUMENT / PROCESS UNIT CONSISTENCY
   =====================================================================

   Rule:

       If a Trip has ProcessUnitId populated, every Instrument assigned
       to that Trip must belong to the same ProcessUnit.

   Trip:
       dbo.TripsInterlocks.ProcessUnitId

   Instrument:
       dbo.Instruments.UnitId

   Relationship:
       rel.TripInstruments

   NULL semantics:

       Trip.ProcessUnitId IS NULL
           -> no ProcessUnit consistency requirement is imposed.

       Trip.ProcessUnitId IS NOT NULL
           -> Instrument.UnitId must equal Trip.ProcessUnitId.
   ===================================================================== */

DECLARE @BR02_Count BIGINT;

SELECT @BR02_Count = COUNT_BIG(*)
FROM rel.TripInstruments ti
INNER JOIN dbo.TripsInterlocks tr
    ON tr.TripId = ti.TripId
INNER JOIN dbo.Instruments i
    ON i.InstrumentId = ti.InstrumentId
WHERE tr.ProcessUnitId IS NOT NULL
  AND
  (
       i.UnitId IS NULL
       OR i.UnitId <> tr.ProcessUnitId
  );

PRINT 'BR-02 Trip/Instrument/ProcessUnit violations: '
    + CAST(@BR02_Count AS VARCHAR(30));


/* =====================================================================
   STOP IF EXISTING VIOLATIONS ARE FOUND
   ===================================================================== */

IF
(
       @BR11A_Count > 0
    OR @BR11B_Count > 0
    OR @BR08_Count  > 0
    OR @BR10_Count  > 0
    OR @BR13_Count  > 0
    OR @BR15_Count  > 0
    OR @BR02_Count  > 0
)
BEGIN

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.4 ABORTED';
    PRINT 'Existing business-rule violations were detected.';
    PRINT 'No constraints or triggers were created/modified.';
    PRINT '============================================================';

    THROW 51002,
        'PHASE 10.4 stopped because existing data violates one or more business rules.',
        1;
END;


/* =====================================================================
   10.4.2 — ENFORCEMENT
   ===================================================================== */

PRINT '';
PRINT '============================================================';
PRINT '10.4.2 BUSINESS RULE ENFORCEMENT';
PRINT '============================================================';

BEGIN TRY

    BEGIN TRANSACTION;


    /* ================================================================
       BR-11A
       ================================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_Instruments_MeasurementRange'
          AND parent_object_id = OBJECT_ID(N'dbo.Instruments')
    )
    BEGIN

        ALTER TABLE dbo.Instruments
        ADD CONSTRAINT CK_Instruments_MeasurementRange
        CHECK
        (
            MeasurementRangeMin IS NULL
            OR MeasurementRangeMax IS NULL
            OR MeasurementRangeMax >= MeasurementRangeMin
        );

        PRINT 'Created: CK_Instruments_MeasurementRange';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: CK_Instruments_MeasurementRange';

    END;


    /* ================================================================
       BR-11B
       ================================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_Instruments_OutputRange'
          AND parent_object_id = OBJECT_ID(N'dbo.Instruments')
    )
    BEGIN

        ALTER TABLE dbo.Instruments
        ADD CONSTRAINT CK_Instruments_OutputRange
        CHECK
        (
            OutputRangeMin IS NULL
            OR OutputRangeMax IS NULL
            OR OutputRangeMax >= OutputRangeMin
        );

        PRINT 'Created: CK_Instruments_OutputRange';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: CK_Instruments_OutputRange';

    END;


    /* ================================================================
       BR-08
       ================================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_SparePartUsage_QuantityUsed'
          AND parent_object_id = OBJECT_ID(N'event.SparePartUsage')
    )
    BEGIN

        ALTER TABLE event.SparePartUsage
        ADD CONSTRAINT CK_SparePartUsage_QuantityUsed
        CHECK
        (
            QuantityUsed > 0
        );

        PRINT 'Created: CK_SparePartUsage_QuantityUsed';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: CK_SparePartUsage_QuantityUsed';

    END;


    /* ================================================================
       BR-10
       ================================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_CalibrationTestPoints_TestSequence'
          AND parent_object_id = OBJECT_ID(N'event.CalibrationTestPoints')
    )
    BEGIN

        ALTER TABLE event.CalibrationTestPoints
        ADD CONSTRAINT CK_CalibrationTestPoints_TestSequence
        CHECK
        (
            TestSequence > 0
        );

        PRINT 'Created: CK_CalibrationTestPoints_TestSequence';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: CK_CalibrationTestPoints_TestSequence';

    END;


    /* ================================================================
       BR-13
       ================================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_InstrumentRedundancy_DifferentInstruments'
          AND parent_object_id = OBJECT_ID(N'rel.InstrumentRedundancy')
    )
    BEGIN

        ALTER TABLE rel.InstrumentRedundancy
        ADD CONSTRAINT CK_InstrumentRedundancy_DifferentInstruments
        CHECK
        (
            InstrumentId1 <> InstrumentId2
        );

        PRINT 'Created: CK_InstrumentRedundancy_DifferentInstruments';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: CK_InstrumentRedundancy_DifferentInstruments';

    END;


    /* ================================================================
       BR-15
       ================================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_SparePartInterchangeability_DifferentParts'
          AND parent_object_id =
              OBJECT_ID(N'rel.SparePartInterchangeability')
    )
    BEGIN

        ALTER TABLE rel.SparePartInterchangeability
        ADD CONSTRAINT CK_SparePartInterchangeability_DifferentParts
        CHECK
        (
            SparePartId1 <> SparePartId2
        );

        PRINT 'Created: CK_SparePartInterchangeability_DifferentParts';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: CK_SparePartInterchangeability_DifferentParts';

    END;


    /* =================================================================
       BR-02
       Trigger 1:
       rel.TripInstruments

       Protect INSERT / UPDATE of Trip-Instrument relationship.
       ================================================================= */

    EXEC
    (
    N'
    CREATE OR ALTER TRIGGER rel.TR_TripInstruments_ProcessUnitIntegrity
    ON rel.TripInstruments
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        IF EXISTS
        (
            SELECT 1
            FROM inserted ti
            INNER JOIN dbo.TripsInterlocks tr
                ON tr.TripId = ti.TripId
            INNER JOIN dbo.Instruments i
                ON i.InstrumentId = ti.InstrumentId
            WHERE tr.ProcessUnitId IS NOT NULL
              AND
              (
                   i.UnitId IS NULL
                   OR i.UnitId <> tr.ProcessUnitId
              )
        )
        BEGIN
            THROW 51010,
                ''BR-02 violation: Trip Instrument does not belong to the Trip ProcessUnit.'',
                1;
        END;
    END;
    '
    );

    PRINT 'Created/updated: rel.TR_TripInstruments_ProcessUnitIntegrity';


    /* =================================================================
       BR-02
       Trigger 2:
       dbo.TripsInterlocks

       Protect INSERT / UPDATE of Trip.ProcessUnitId.

       If ProcessUnitId changes, all existing instruments assigned
       to the Trip must belong to the new ProcessUnit.
       ================================================================= */

    EXEC
    (
    N'
    CREATE OR ALTER TRIGGER dbo.TR_TripsInterlocks_ProcessUnitIntegrity
    ON dbo.TripsInterlocks
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        IF EXISTS
        (
            SELECT 1
            FROM inserted tr
            INNER JOIN rel.TripInstruments ti
                ON ti.TripId = tr.TripId
            INNER JOIN dbo.Instruments i
                ON i.InstrumentId = ti.InstrumentId
            WHERE tr.ProcessUnitId IS NOT NULL
              AND
              (
                   i.UnitId IS NULL
                   OR i.UnitId <> tr.ProcessUnitId
              )
        )
        BEGIN
            THROW 51011,
                ''BR-02 violation: Trip ProcessUnit is inconsistent with one or more assigned Instruments.'',
                1;
        END;
    END;
    '
    );

    PRINT 'Created/updated: dbo.TR_TripsInterlocks_ProcessUnitIntegrity';


    /* =================================================================
       BR-02
       Trigger 3:
       dbo.Instruments

       Protect UPDATE of Instrument.UnitId.

       Existing Trip assignments must remain consistent after an
       Instrument changes ProcessUnit.
       ================================================================= */

    EXEC
    (
    N'
    CREATE OR ALTER TRIGGER dbo.TR_Instruments_TripProcessUnitIntegrity
    ON dbo.Instruments
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        IF NOT UPDATE(UnitId)
            RETURN;

        IF EXISTS
        (
            SELECT 1
            FROM inserted i
            INNER JOIN rel.TripInstruments ti
                ON ti.InstrumentId = i.InstrumentId
            INNER JOIN dbo.TripsInterlocks tr
                ON tr.TripId = ti.TripId
            WHERE tr.ProcessUnitId IS NOT NULL
              AND
              (
                   i.UnitId IS NULL
                   OR i.UnitId <> tr.ProcessUnitId
              )
        )
        BEGIN
            THROW 51012,
                ''BR-02 violation: Instrument UnitId change would break Trip ProcessUnit integrity.'',
                1;
        END;
    END;
    '
    );

    PRINT 'Created/updated: dbo.TR_Instruments_TripProcessUnitIntegrity';


    /* ================================================================
       COMMIT
       ================================================================ */

    COMMIT TRANSACTION;

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.4 ENFORCEMENT COMPLETED';
    PRINT '============================================================';

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.4 FAILED';
    PRINT 'TRANSACTION ROLLED BACK';
    PRINT '============================================================';

    THROW;

END CATCH;
GO


/* =====================================================================
   10.4.3 — FINAL VALIDATION
   ===================================================================== */

PRINT '';
PRINT '============================================================';
PRINT '10.4.3 FINAL VALIDATION';
PRINT '============================================================';


/* ---------------------------------------------------------------------
   CHECK CONSTRAINT VALIDATION
   --------------------------------------------------------------------- */

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    cc.name AS ConstraintName,
    cc.is_disabled AS IsDisabled,
    cc.is_not_trusted AS IsNotTrusted
FROM sys.check_constraints cc
INNER JOIN sys.tables t
    ON t.object_id = cc.parent_object_id
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE
       (s.name = 'dbo'
        AND t.name = 'Instruments'
        AND cc.name IN
        (
            'CK_Instruments_MeasurementRange',
            'CK_Instruments_OutputRange'
        ))

    OR

       (s.name = 'event'
        AND t.name = 'SparePartUsage'
        AND cc.name = 'CK_SparePartUsage_QuantityUsed')

    OR

       (s.name = 'event'
        AND t.name = 'CalibrationTestPoints'
        AND cc.name = 'CK_CalibrationTestPoints_TestSequence')

    OR

       (s.name = 'rel'
        AND t.name = 'InstrumentRedundancy'
        AND cc.name = 'CK_InstrumentRedundancy_DifferentInstruments')

    OR

       (s.name = 'rel'
        AND t.name = 'SparePartInterchangeability'
        AND cc.name = 'CK_SparePartInterchangeability_DifferentParts')

ORDER BY
    s.name,
    t.name,
    cc.name;


/* ---------------------------------------------------------------------
   TRIGGER VALIDATION
   --------------------------------------------------------------------- */

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    tr.name AS TriggerName,
    tr.is_disabled AS IsDisabled
FROM sys.triggers tr
INNER JOIN sys.tables t
    ON t.object_id = tr.parent_id
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE tr.name IN
(
    'TR_TripInstruments_ProcessUnitIntegrity',
    'TR_TripsInterlocks_ProcessUnitIntegrity',
    'TR_Instruments_TripProcessUnitIntegrity'
)
ORDER BY
    s.name,
    t.name,
    tr.name;


/* ---------------------------------------------------------------------
   FINAL DATA RECHECK
   --------------------------------------------------------------------- */

SELECT
    'BR-11A Measurement Range' AS BusinessRule,
    COUNT_BIG(*) AS Violations
FROM dbo.Instruments
WHERE MeasurementRangeMin IS NOT NULL
  AND MeasurementRangeMax IS NOT NULL
  AND MeasurementRangeMax < MeasurementRangeMin

UNION ALL

SELECT
    'BR-11B Output Range',
    COUNT_BIG(*)
FROM dbo.Instruments
WHERE OutputRangeMin IS NOT NULL
  AND OutputRangeMax IS NOT NULL
  AND OutputRangeMax < OutputRangeMin

UNION ALL

SELECT
    'BR-08 QuantityUsed > 0',
    COUNT_BIG(*)
FROM event.SparePartUsage
WHERE QuantityUsed <= 0

UNION ALL

SELECT
    'BR-10 TestSequence > 0',
    COUNT_BIG(*)
FROM event.CalibrationTestPoints
WHERE TestSequence <= 0

UNION ALL

SELECT
    'BR-13 Different Instruments',
    COUNT_BIG(*)
FROM rel.InstrumentRedundancy
WHERE InstrumentId1 = InstrumentId2

UNION ALL

SELECT
    'BR-15 Different Spare Parts',
    COUNT_BIG(*)
FROM rel.SparePartInterchangeability
WHERE SparePartId1 = SparePartId2

UNION ALL

SELECT
    'BR-02 Trip / Instrument / ProcessUnit',
    COUNT_BIG(*)
FROM rel.TripInstruments ti
INNER JOIN dbo.TripsInterlocks tr
    ON tr.TripId = ti.TripId
INNER JOIN dbo.Instruments i
    ON i.InstrumentId = ti.InstrumentId
WHERE tr.ProcessUnitId IS NOT NULL
  AND
  (
       i.UnitId IS NULL
       OR i.UnitId <> tr.ProcessUnitId
  );

PRINT '';
PRINT '============================================================';
PRINT 'PHASE 10.4 — FINAL VALIDATION COMPLETED';
PRINT '============================================================';
GO