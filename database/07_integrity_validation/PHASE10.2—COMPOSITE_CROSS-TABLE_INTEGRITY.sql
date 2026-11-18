USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


/* ============================================================
   PHASE 10.2
   COMPOSITE / CROSS-TABLE INTEGRITY
   FINAL EXECUTABLE SCRIPT

   Purpose:
   Enforce cross-table consistency rules that cannot be
   guaranteed by simple single-column foreign keys.

   Rules implemented:

   10.2.1 Instrument -> SubSystem -> ProcessUnit
   10.2.2 Failure -> PreviousFailure -> Instrument
   10.2.3 SparePartUsage -> InventoryTransaction -> SparePart
   10.2.4 OperationalStatus -> Failure/Maintenance -> Instrument
   10.2.5 SparePartUsage -> Maintenance/Failure -> Instrument

   Trip -> TripInstruments -> Instrument -> ProcessUnit
   is intentionally NOT implemented here because it is a
   multi-row business rule and will be handled in Phase 10.4.

   Personnel FKs intentionally remain outside this phase
   where they were explicitly deferred.
   ============================================================ */


BEGIN TRY

    BEGIN TRANSACTION;


    /* =========================================================
       0. PRE-FLIGHT
       ========================================================= */

    PRINT '============================================================';
    PRINT 'PHASE 10.2 - PRE-FLIGHT';
    PRINT '============================================================';


    /* ---------- Required tables ---------- */

    IF OBJECT_ID(N'dbo.Instruments', N'U') IS NULL
        THROW 51001, 'Missing table: dbo.Instruments', 1;

    IF OBJECT_ID(N'dbo.SubSystems', N'U') IS NULL
        THROW 51002, 'Missing table: dbo.SubSystems', 1;

    IF OBJECT_ID(N'dbo.ProcessUnits', N'U') IS NULL
        THROW 51003, 'Missing table: dbo.ProcessUnits', 1;

    IF OBJECT_ID(N'event.FailureRecords', N'U') IS NULL
        THROW 51004, 'Missing table: event.FailureRecords', 1;

    IF OBJECT_ID(N'event.MaintenanceRecords', N'U') IS NULL
        THROW 51005, 'Missing table: event.MaintenanceRecords', 1;

    IF OBJECT_ID(N'inv.InventoryTransactions', N'U') IS NULL
        THROW 51006, 'Missing table: inv.InventoryTransactions', 1;

    IF OBJECT_ID(N'event.SparePartUsage', N'U') IS NULL
        THROW 51007, 'Missing table: event.SparePartUsage', 1;

    IF OBJECT_ID(N'dbo.SpareParts', N'U') IS NULL
        THROW 51008, 'Missing table: dbo.SpareParts', 1;

    IF OBJECT_ID(N'event.InstrumentOperationalStatusHistory', N'U') IS NULL
        THROW 51009,
            'Missing table: event.InstrumentOperationalStatusHistory',
            1;


    /* =========================================================
       Required columns
       ========================================================= */

    IF COL_LENGTH(N'dbo.Instruments', N'InstrumentId') IS NULL
        THROW 51010, 'Missing column: dbo.Instruments.InstrumentId', 1;

    IF COL_LENGTH(N'dbo.Instruments', N'UnitId') IS NULL
        THROW 51011, 'Missing column: dbo.Instruments.UnitId', 1;

    IF COL_LENGTH(N'dbo.Instruments', N'SubSystemId') IS NULL
        THROW 51012, 'Missing column: dbo.Instruments.SubSystemId', 1;


    IF COL_LENGTH(N'dbo.SubSystems', N'SubSystemId') IS NULL
        THROW 51013, 'Missing column: dbo.SubSystems.SubSystemId', 1;

    IF COL_LENGTH(N'dbo.SubSystems', N'UnitId') IS NULL
        THROW 51014, 'Missing column: dbo.SubSystems.UnitId', 1;


    IF COL_LENGTH(N'event.FailureRecords', N'FailureId') IS NULL
        THROW 51015, 'Missing column: event.FailureRecords.FailureId', 1;

    IF COL_LENGTH(N'event.FailureRecords', N'InstrumentId') IS NULL
        THROW 51016,
            'Missing column: event.FailureRecords.InstrumentId',
            1;

    IF COL_LENGTH(N'event.FailureRecords', N'PreviousFailureId') IS NULL
        THROW 51017,
            'Missing column: event.FailureRecords.PreviousFailureId',
            1;


    IF COL_LENGTH(N'event.MaintenanceRecords', N'MaintenanceId') IS NULL
        THROW 51018,
            'Missing column: event.MaintenanceRecords.MaintenanceId',
            1;

    IF COL_LENGTH(N'event.MaintenanceRecords', N'InstrumentId') IS NULL
        THROW 51019,
            'Missing column: event.MaintenanceRecords.InstrumentId',
            1;


    IF COL_LENGTH(N'inv.InventoryTransactions', N'InventoryTransactionId') IS NULL
        THROW 51020,
            'Missing column: inv.InventoryTransactions.InventoryTransactionId',
            1;

    IF COL_LENGTH(N'inv.InventoryTransactions', N'SparePartId') IS NULL
        THROW 51021,
            'Missing column: inv.InventoryTransactions.SparePartId',
            1;


    IF COL_LENGTH(N'event.SparePartUsage', N'SparePartUsageId') IS NULL
        THROW 51022,
            'Missing column: event.SparePartUsage.SparePartUsageId',
            1;

    IF COL_LENGTH(N'event.SparePartUsage', N'InventoryTransactionId') IS NULL
        THROW 51023,
            'Missing column: event.SparePartUsage.InventoryTransactionId',
            1;

    IF COL_LENGTH(N'event.SparePartUsage', N'SparePartId') IS NULL
        THROW 51024,
            'Missing column: event.SparePartUsage.SparePartId',
            1;

    IF COL_LENGTH(N'event.SparePartUsage', N'InstrumentId') IS NULL
        THROW 51025,
            'Missing column: event.SparePartUsage.InstrumentId',
            1;

    IF COL_LENGTH(N'event.SparePartUsage', N'MaintenanceId') IS NULL
        THROW 51026,
            'Missing column: event.SparePartUsage.MaintenanceId',
            1;

    IF COL_LENGTH(N'event.SparePartUsage', N'FailureId') IS NULL
        THROW 51027,
            'Missing column: event.SparePartUsage.FailureId',
            1;


    IF COL_LENGTH(
        N'event.InstrumentOperationalStatusHistory',
        N'InstrumentOperationalStatusHistoryId'
       ) IS NULL
        THROW 51028,
            'Missing column: event.InstrumentOperationalStatusHistory.InstrumentOperationalStatusHistoryId',
            1;

    IF COL_LENGTH(
        N'event.InstrumentOperationalStatusHistory',
        N'InstrumentId'
       ) IS NULL
        THROW 51029,
            'Missing column: event.InstrumentOperationalStatusHistory.InstrumentId',
            1;

    IF COL_LENGTH(
        N'event.InstrumentOperationalStatusHistory',
        N'FailureId'
       ) IS NULL
        THROW 51030,
            'Missing column: event.InstrumentOperationalStatusHistory.FailureId',
            1;

    IF COL_LENGTH(
        N'event.InstrumentOperationalStatusHistory',
        N'MaintenanceId'
       ) IS NULL
        THROW 51031,
            'Missing column: event.InstrumentOperationalStatusHistory.MaintenanceId',
            1;


    PRINT 'Pre-flight checks passed.';
    PRINT '';


    /* =========================================================
       10.2.1
       INSTRUMENT -> SUBSYSTEM -> PROCESS UNIT
       ========================================================= */

    PRINT '------------------------------------------------------------';
    PRINT '10.2.1 Instrument -> SubSystem -> ProcessUnit';
    PRINT '------------------------------------------------------------';


    /* ---------------------------------------------------------
       Audit orphan SubSystem references
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Instruments i
        LEFT JOIN dbo.SubSystems ss
            ON ss.SubSystemId = i.SubSystemId
        WHERE i.SubSystemId IS NOT NULL
          AND ss.SubSystemId IS NULL
    )
    BEGIN
        THROW 51101,
            'Integrity violation: Instruments contains orphan SubSystemId values.',
            1;
    END;


    /* ---------------------------------------------------------
       Audit Unit/SubSystem consistency

       Instrument.UnitId must equal SubSystem.UnitId
       whenever SubSystemId is populated.
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Instruments i
        INNER JOIN dbo.SubSystems ss
            ON ss.SubSystemId = i.SubSystemId
        WHERE i.SubSystemId IS NOT NULL
          AND i.UnitId <> ss.UnitId
    )
    BEGIN
        THROW 51102,
            'Integrity violation: Instrument.UnitId does not match SubSystem.UnitId.',
            1;
    END;


    /* ---------------------------------------------------------
       Supporting candidate key
       --------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints kc
        WHERE kc.parent_object_id =
              OBJECT_ID(N'dbo.SubSystems')
          AND kc.name = N'UQ_SubSystems_SubSystemId_UnitId'
          AND kc.type = 'UQ'
    )
    BEGIN

        ALTER TABLE dbo.SubSystems
        ADD CONSTRAINT UQ_SubSystems_SubSystemId_UnitId
        UNIQUE (SubSystemId, UnitId);

    END;


    /* ---------------------------------------------------------
       Composite FK
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'dbo.FK_Instruments_SubSystem_Unit',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE dbo.Instruments
        WITH CHECK
        ADD CONSTRAINT FK_Instruments_SubSystem_Unit
        FOREIGN KEY (SubSystemId, UnitId)
        REFERENCES dbo.SubSystems
        (
            SubSystemId,
            UnitId
        );

    END;


    ALTER TABLE dbo.Instruments
    CHECK CONSTRAINT FK_Instruments_SubSystem_Unit;


    PRINT '10.2.1 completed.';
    PRINT '';


    /* =========================================================
       10.2.2
       FAILURE -> PREVIOUS FAILURE -> SAME INSTRUMENT
       ========================================================= */

    PRINT '------------------------------------------------------------';
    PRINT '10.2.2 Failure -> PreviousFailure -> Instrument';
    PRINT '------------------------------------------------------------';


    /* ---------------------------------------------------------
       Audit orphan PreviousFailure references
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.FailureRecords f
        LEFT JOIN event.FailureRecords pf
            ON pf.FailureId = f.PreviousFailureId
        WHERE f.PreviousFailureId IS NOT NULL
          AND pf.FailureId IS NULL
    )
    BEGIN
        THROW 51201,
            'Integrity violation: FailureRecords contains orphan PreviousFailureId values.',
            1;
    END;


    /* ---------------------------------------------------------
       PreviousFailure must belong to same Instrument
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.FailureRecords f
        INNER JOIN event.FailureRecords pf
            ON pf.FailureId = f.PreviousFailureId
        WHERE f.PreviousFailureId IS NOT NULL
          AND f.InstrumentId <> pf.InstrumentId
    )
    BEGIN
        THROW 51202,
            'Integrity violation: PreviousFailureId belongs to a different Instrument.',
            1;
    END;


    /* ---------------------------------------------------------
       Supporting candidate key
       --------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints kc
        WHERE kc.parent_object_id =
              OBJECT_ID(N'event.FailureRecords')
          AND kc.name = N'UQ_FailureRecords_FailureId_InstrumentId'
          AND kc.type = 'UQ'
    )
    BEGIN

        ALTER TABLE event.FailureRecords
        ADD CONSTRAINT UQ_FailureRecords_FailureId_InstrumentId
        UNIQUE (FailureId, InstrumentId);

    END;


    /* ---------------------------------------------------------
       Composite FK
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'event.FK_FailureRecords_PreviousFailure_Instrument',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE event.FailureRecords
        WITH CHECK
        ADD CONSTRAINT FK_FailureRecords_PreviousFailure_Instrument
        FOREIGN KEY
        (
            PreviousFailureId,
            InstrumentId
        )
        REFERENCES event.FailureRecords
        (
            FailureId,
            InstrumentId
        );

    END;


    ALTER TABLE event.FailureRecords
    CHECK CONSTRAINT FK_FailureRecords_PreviousFailure_Instrument;


    PRINT '10.2.2 completed.';
    PRINT '';


    /* =========================================================
       10.2.3
       SPARE PART USAGE -> INVENTORY TRANSACTION -> SPARE PART
       ========================================================= */

    PRINT '------------------------------------------------------------';
    PRINT '10.2.3 SparePartUsage -> InventoryTransaction -> SparePart';
    PRINT '------------------------------------------------------------';


    /* ---------------------------------------------------------
       Audit orphan InventoryTransaction references
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        LEFT JOIN inv.InventoryTransactions t
            ON t.InventoryTransactionId = u.InventoryTransactionId
        WHERE u.InventoryTransactionId IS NOT NULL
          AND t.InventoryTransactionId IS NULL
    )
    BEGIN
        THROW 51301,
            'Integrity violation: SparePartUsage contains orphan InventoryTransactionId values.',
            1;
    END;


    /* ---------------------------------------------------------
       SparePartUsage.SparePartId must match
       InventoryTransactions.SparePartId
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        INNER JOIN inv.InventoryTransactions t
            ON t.InventoryTransactionId =
               u.InventoryTransactionId
        WHERE u.SparePartId <> t.SparePartId
    )
    BEGIN
        THROW 51302,
            'Integrity violation: SparePartUsage.SparePartId does not match InventoryTransactions.SparePartId.',
            1;
    END;


    /* ---------------------------------------------------------
       Supporting candidate key
       --------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints kc
        WHERE kc.parent_object_id =
              OBJECT_ID(N'inv.InventoryTransactions')
          AND kc.name = N'UQ_InventoryTransactions_Id_SparePart'
          AND kc.type = 'UQ'
    )
    BEGIN

        ALTER TABLE inv.InventoryTransactions
        ADD CONSTRAINT UQ_InventoryTransactions_Id_SparePart
        UNIQUE
        (
            InventoryTransactionId,
            SparePartId
        );

    END;


    /* ---------------------------------------------------------
       Composite FK
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'event.FK_SparePartUsage_InventoryTransaction_SparePart',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE event.SparePartUsage
        WITH CHECK
        ADD CONSTRAINT FK_SparePartUsage_InventoryTransaction_SparePart
        FOREIGN KEY
        (
            InventoryTransactionId,
            SparePartId
        )
        REFERENCES inv.InventoryTransactions
        (
            InventoryTransactionId,
            SparePartId
        );

    END;


    ALTER TABLE event.SparePartUsage
    CHECK CONSTRAINT FK_SparePartUsage_InventoryTransaction_SparePart;


    PRINT '10.2.3 completed.';
    PRINT '';


    /* =========================================================
       10.2.4
       OPERATIONAL STATUS -> FAILURE / MAINTENANCE -> SAME
       INSTRUMENT
       ========================================================= */

    PRINT '------------------------------------------------------------';
    PRINT '10.2.4 OperationalStatus -> Failure/Maintenance -> Instrument';
    PRINT '------------------------------------------------------------';


    /* ---------------------------------------------------------
       Audit Failure references from Operational Status History
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory s
        LEFT JOIN event.FailureRecords f
            ON f.FailureId = s.FailureId
        WHERE s.FailureId IS NOT NULL
          AND f.FailureId IS NULL
    )
    BEGIN
        THROW 51401,
            'Integrity violation: OperationalStatusHistory contains orphan FailureId values.',
            1;
    END;


    /* ---------------------------------------------------------
       Failure must belong to same Instrument
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory s
        INNER JOIN event.FailureRecords f
            ON f.FailureId = s.FailureId
        WHERE s.FailureId IS NOT NULL
          AND s.InstrumentId <> f.InstrumentId
    )
    BEGIN
        THROW 51402,
            'Integrity violation: OperationalStatusHistory.FailureId belongs to a different Instrument.',
            1;
    END;


    /* ---------------------------------------------------------
       Audit Maintenance references
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory s
        LEFT JOIN event.MaintenanceRecords m
            ON m.MaintenanceId = s.MaintenanceId
        WHERE s.MaintenanceId IS NOT NULL
          AND m.MaintenanceId IS NULL
    )
    BEGIN
        THROW 51403,
            'Integrity violation: OperationalStatusHistory contains orphan MaintenanceId values.',
            1;
    END;


    /* ---------------------------------------------------------
       Maintenance must belong to same Instrument
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory s
        INNER JOIN event.MaintenanceRecords m
            ON m.MaintenanceId = s.MaintenanceId
        WHERE s.MaintenanceId IS NOT NULL
          AND s.InstrumentId <> m.InstrumentId
    )
    BEGIN
        THROW 51404,
            'Integrity violation: OperationalStatusHistory.MaintenanceId belongs to a different Instrument.',
            1;
    END;


    /* ---------------------------------------------------------
       Supporting candidate key for Maintenance
       --------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints kc
        WHERE kc.parent_object_id =
              OBJECT_ID(N'event.MaintenanceRecords')
          AND kc.name = N'UQ_MaintenanceRecords_MaintenanceId_InstrumentId'
          AND kc.type = 'UQ'
    )
    BEGIN

        ALTER TABLE event.MaintenanceRecords
        ADD CONSTRAINT UQ_MaintenanceRecords_MaintenanceId_InstrumentId
        UNIQUE
        (
            MaintenanceId,
            InstrumentId
        );

    END;


    /* ---------------------------------------------------------
       Composite FK:
       StatusHistory -> Failure
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'event.FK_StatusHistory_Failure_Instrument',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE event.InstrumentOperationalStatusHistory
        WITH CHECK
        ADD CONSTRAINT FK_StatusHistory_Failure_Instrument
        FOREIGN KEY
        (
            FailureId,
            InstrumentId
        )
        REFERENCES event.FailureRecords
        (
            FailureId,
            InstrumentId
        );

    END;


    ALTER TABLE event.InstrumentOperationalStatusHistory
    CHECK CONSTRAINT FK_StatusHistory_Failure_Instrument;


    /* ---------------------------------------------------------
       Composite FK:
       StatusHistory -> Maintenance
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'event.FK_StatusHistory_Maintenance_Instrument',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE event.InstrumentOperationalStatusHistory
        WITH CHECK
        ADD CONSTRAINT FK_StatusHistory_Maintenance_Instrument
        FOREIGN KEY
        (
            MaintenanceId,
            InstrumentId
        )
        REFERENCES event.MaintenanceRecords
        (
            MaintenanceId,
            InstrumentId
        );

    END;


    ALTER TABLE event.InstrumentOperationalStatusHistory
    CHECK CONSTRAINT FK_StatusHistory_Maintenance_Instrument;


    PRINT '10.2.4 completed.';
    PRINT '';


    /* =========================================================
       10.2.5
       SPARE PART USAGE -> MAINTENANCE / FAILURE -> SAME
       INSTRUMENT
       ========================================================= */

    PRINT '------------------------------------------------------------';
    PRINT '10.2.5 SparePartUsage -> Maintenance/Failure -> Instrument';
    PRINT '------------------------------------------------------------';


    /* ---------------------------------------------------------
       Audit Maintenance references
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        LEFT JOIN event.MaintenanceRecords m
            ON m.MaintenanceId = u.MaintenanceId
        WHERE u.MaintenanceId IS NOT NULL
          AND m.MaintenanceId IS NULL
    )
    BEGIN
        THROW 51501,
            'Integrity violation: SparePartUsage contains orphan MaintenanceId values.',
            1;
    END;


    /* ---------------------------------------------------------
       Maintenance must belong to same Instrument
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        INNER JOIN event.MaintenanceRecords m
            ON m.MaintenanceId = u.MaintenanceId
        WHERE u.MaintenanceId IS NOT NULL
          AND u.InstrumentId <> m.InstrumentId
    )
    BEGIN
        THROW 51502,
            'Integrity violation: SparePartUsage.MaintenanceId belongs to a different Instrument.',
            1;
    END;


    /* ---------------------------------------------------------
       Audit Failure references
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        LEFT JOIN event.FailureRecords f
            ON f.FailureId = u.FailureId
        WHERE u.FailureId IS NOT NULL
          AND f.FailureId IS NULL
    )
    BEGIN
        THROW 51503,
            'Integrity violation: SparePartUsage contains orphan FailureId values.',
            1;
    END;


    /* ---------------------------------------------------------
       Failure must belong to same Instrument
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        INNER JOIN event.FailureRecords f
            ON f.FailureId = u.FailureId
        WHERE u.FailureId IS NOT NULL
          AND u.InstrumentId <> f.InstrumentId
    )
    BEGIN
        THROW 51504,
            'Integrity violation: SparePartUsage.FailureId belongs to a different Instrument.',
            1;
    END;


    /* ---------------------------------------------------------
       Composite FK:
       SparePartUsage -> Maintenance
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'event.FK_SparePartUsage_Maintenance_Instrument',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE event.SparePartUsage
        WITH CHECK
        ADD CONSTRAINT FK_SparePartUsage_Maintenance_Instrument
        FOREIGN KEY
        (
            MaintenanceId,
            InstrumentId
        )
        REFERENCES event.MaintenanceRecords
        (
            MaintenanceId,
            InstrumentId
        );

    END;


    ALTER TABLE event.SparePartUsage
    CHECK CONSTRAINT FK_SparePartUsage_Maintenance_Instrument;


    /* ---------------------------------------------------------
       Composite FK:
       SparePartUsage -> Failure
       --------------------------------------------------------- */

    IF OBJECT_ID(
        N'event.FK_SparePartUsage_Failure_Instrument',
        N'F'
    ) IS NULL
    BEGIN

        ALTER TABLE event.SparePartUsage
        WITH CHECK
        ADD CONSTRAINT FK_SparePartUsage_Failure_Instrument
        FOREIGN KEY
        (
            FailureId,
            InstrumentId
        )
        REFERENCES event.FailureRecords
        (
            FailureId,
            InstrumentId
        );

    END;


    ALTER TABLE event.SparePartUsage
    CHECK CONSTRAINT FK_SparePartUsage_Failure_Instrument;


    PRINT '10.2.5 completed.';
    PRINT '';


    /* =========================================================
       10.2.6
       FINAL CONSTRAINT VALIDATION
       ========================================================= */

    PRINT '============================================================';
    PRINT '10.2.6 FINAL CONSTRAINT VALIDATION';
    PRINT '============================================================';


    /* ---------------------------------------------------------
       Validate supporting UNIQUE constraints
       --------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints
        WHERE parent_object_id = OBJECT_ID(N'dbo.SubSystems')
          AND name = N'UQ_SubSystems_SubSystemId_UnitId'
          AND type = 'UQ'
    )
        THROW 51601,
            'Validation failed: UQ_SubSystems_SubSystemId_UnitId missing.',
            1;


    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints
        WHERE parent_object_id =
              OBJECT_ID(N'event.FailureRecords')
          AND name = N'UQ_FailureRecords_FailureId_InstrumentId'
          AND type = 'UQ'
    )
        THROW 51602,
            'Validation failed: UQ_FailureRecords_FailureId_InstrumentId missing.',
            1;


    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints
        WHERE parent_object_id =
              OBJECT_ID(N'event.MaintenanceRecords')
          AND name = N'UQ_MaintenanceRecords_MaintenanceId_InstrumentId'
          AND type = 'UQ'
    )
        THROW 51603,
            'Validation failed: UQ_MaintenanceRecords_MaintenanceId_InstrumentId missing.',
            1;


    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints
        WHERE parent_object_id =
              OBJECT_ID(N'inv.InventoryTransactions')
          AND name = N'UQ_InventoryTransactions_Id_SparePart'
          AND type = 'UQ'
    )
        THROW 51604,
            'Validation failed: UQ_InventoryTransactions_Id_SparePart missing.',
            1;


    /* ---------------------------------------------------------
       Validate FK state: enabled + trusted
       --------------------------------------------------------- */

    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_Instruments_SubSystem_Unit'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51611,
            'Validation failed: FK_Instruments_SubSystem_Unit is disabled or untrusted.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name =
              N'FK_FailureRecords_PreviousFailure_Instrument'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51612,
            'Validation failed: FK_FailureRecords_PreviousFailure_Instrument is disabled or untrusted.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name =
              N'FK_SparePartUsage_InventoryTransaction_SparePart'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51613,
            'Validation failed: FK_SparePartUsage_InventoryTransaction_SparePart is disabled or untrusted.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name =
              N'FK_StatusHistory_Failure_Instrument'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51614,
            'Validation failed: FK_StatusHistory_Failure_Instrument is disabled or untrusted.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name =
              N'FK_StatusHistory_Maintenance_Instrument'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51615,
            'Validation failed: FK_StatusHistory_Maintenance_Instrument is disabled or untrusted.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name =
              N'FK_SparePartUsage_Maintenance_Instrument'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51616,
            'Validation failed: FK_SparePartUsage_Maintenance_Instrument is disabled or untrusted.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name =
              N'FK_SparePartUsage_Failure_Instrument'
          AND
          (
              is_disabled = 1
              OR is_not_trusted = 1
          )
    )
        THROW 51617,
            'Validation failed: FK_SparePartUsage_Failure_Instrument is disabled or untrusted.',
            1;


    /* =========================================================
       Final orphan / mismatch re-check
       ========================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Instruments i
        INNER JOIN dbo.SubSystems ss
            ON ss.SubSystemId = i.SubSystemId
        WHERE i.SubSystemId IS NOT NULL
          AND i.UnitId <> ss.UnitId
    )
        THROW 51621,
            'Final validation failed: Instrument/SubSystem Unit mismatch exists.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM event.FailureRecords f
        INNER JOIN event.FailureRecords pf
            ON pf.FailureId = f.PreviousFailureId
        WHERE f.PreviousFailureId IS NOT NULL
          AND f.InstrumentId <> pf.InstrumentId
    )
        THROW 51622,
            'Final validation failed: PreviousFailure belongs to another Instrument.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        INNER JOIN inv.InventoryTransactions t
            ON t.InventoryTransactionId = u.InventoryTransactionId
        WHERE u.SparePartId <> t.SparePartId
    )
        THROW 51623,
            'Final validation failed: SparePartUsage/InventoryTransaction SparePart mismatch.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory s
        INNER JOIN event.FailureRecords f
            ON f.FailureId = s.FailureId
        WHERE s.FailureId IS NOT NULL
          AND s.InstrumentId <> f.InstrumentId
    )
        THROW 51624,
            'Final validation failed: StatusHistory/Failure Instrument mismatch.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory s
        INNER JOIN event.MaintenanceRecords m
            ON m.MaintenanceId = s.MaintenanceId
        WHERE s.MaintenanceId IS NOT NULL
          AND s.InstrumentId <> m.InstrumentId
    )
        THROW 51625,
            'Final validation failed: StatusHistory/Maintenance Instrument mismatch.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        INNER JOIN event.MaintenanceRecords m
            ON m.MaintenanceId = u.MaintenanceId
        WHERE u.MaintenanceId IS NOT NULL
          AND u.InstrumentId <> m.InstrumentId
    )
        THROW 51626,
            'Final validation failed: SparePartUsage/Maintenance Instrument mismatch.',
            1;


    IF EXISTS
    (
        SELECT 1
        FROM event.SparePartUsage u
        INNER JOIN event.FailureRecords f
            ON f.FailureId = u.FailureId
        WHERE u.FailureId IS NOT NULL
          AND u.InstrumentId <> f.InstrumentId
    )
        THROW 51627,
            'Final validation failed: SparePartUsage/Failure Instrument mismatch.',
            1;


    /* =========================================================
       COMMIT
       ========================================================= */

    COMMIT TRANSACTION;


    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.2 COMPLETED SUCCESSFULLY';
    PRINT '============================================================';
    PRINT 'Composite / Cross-Table Integrity constraints are active.';
    PRINT '';
    PRINT 'Implemented rules:';
    PRINT '  10.2.1 Instrument -> SubSystem -> ProcessUnit';
    PRINT '  10.2.2 Failure -> PreviousFailure -> Instrument';
    PRINT '  10.2.3 SparePartUsage -> InventoryTransaction -> SparePart';
    PRINT '  10.2.4 OperationalStatus -> Failure/Maintenance -> Instrument';
    PRINT '  10.2.5 SparePartUsage -> Maintenance/Failure -> Instrument';
    PRINT '';
    PRINT 'Trip -> TripInstruments -> Instrument -> ProcessUnit';
    PRINT 'is intentionally deferred to Phase 10.4 Business Rules.';
    PRINT '============================================================';


END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.2 FAILED - TRANSACTION ROLLED BACK';
    PRINT '============================================================';

    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(20));
    PRINT 'Error Line:   ' + CAST(ERROR_LINE() AS VARCHAR(20));
    PRINT 'Error Message: ' + ERROR_MESSAGE();

    THROW;

END CATCH;
GO