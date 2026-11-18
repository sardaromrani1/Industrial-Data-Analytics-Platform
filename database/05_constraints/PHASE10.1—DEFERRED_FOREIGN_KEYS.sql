USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


/* ============================================================
   INDUSTRIAL DATA ANALYTICS PLATFORM
   PHASE 10.1 — DEFERRED FOREIGN KEYS

   Purpose:
   Add and validate Foreign Keys that were intentionally
   deferred during Phase 9 because of table dependencies.

   Scope:
   10.1.1 — Preflight Checks
   10.1.2 — Orphan Checks
   10.1.3 — Add Deferred Foreign Keys
   10.1.4 — Validate Foreign Keys
   10.1.5 — Final Verification

   Deferred Foreign Keys:
   1. rel.TripInstruments.TripId
      -> dbo.TripsInterlocks.TripId

   2. inv.InventoryTransactions.MaintenanceId
      -> event.MaintenanceRecords.MaintenanceId

   3. inv.InventoryTransactions.FailureId
      -> event.FailureRecords.FailureId

   4. event.SparePartUsage.MaintenanceId
      -> event.MaintenanceRecords.MaintenanceId

   5. event.SparePartUsage.FailureId
      -> event.FailureRecords.FailureId

   Important:
   - This script does NOT insert or modify business data.
   - It only validates and creates Foreign Key constraints.
   - Existing Foreign Keys are not recreated.
   - The script is transaction-protected.
   ============================================================ */


/* ============================================================
   10.1.1 — PREFLIGHT CHECKS
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.1.1 — PREFLIGHT CHECKS';
PRINT '============================================================';


/* ---------- Required Tables ---------- */

IF OBJECT_ID(N'rel.TripInstruments', N'U') IS NULL
    THROW 51001, 'Missing table: rel.TripInstruments', 1;

IF OBJECT_ID(N'dbo.TripsInterlocks', N'U') IS NULL
    THROW 51001, 'Missing table: dbo.TripsInterlocks', 1;

IF OBJECT_ID(N'inv.InventoryTransactions', N'U') IS NULL
    THROW 51001, 'Missing table: inv.InventoryTransactions', 1;

IF OBJECT_ID(N'event.MaintenanceRecords', N'U') IS NULL
    THROW 51001, 'Missing table: event.MaintenanceRecords', 1;

IF OBJECT_ID(N'event.FailureRecords', N'U') IS NULL
    THROW 51001, 'Missing table: event.FailureRecords', 1;

IF OBJECT_ID(N'event.SparePartUsage', N'U') IS NULL
    THROW 51001, 'Missing table: event.SparePartUsage', 1;


/* ---------- Required Columns ---------- */

IF COL_LENGTH(N'rel.TripInstruments', N'TripId') IS NULL
    THROW 51001, 'Missing column: rel.TripInstruments.TripId', 1;

IF COL_LENGTH(N'dbo.TripsInterlocks', N'TripId') IS NULL
    THROW 51001, 'Missing column: dbo.TripsInterlocks.TripId', 1;


IF COL_LENGTH(N'inv.InventoryTransactions', N'MaintenanceId') IS NULL
    THROW 51001, 'Missing column: inv.InventoryTransactions.MaintenanceId', 1;

IF COL_LENGTH(N'event.MaintenanceRecords', N'MaintenanceId') IS NULL
    THROW 51001, 'Missing column: event.MaintenanceRecords.MaintenanceId', 1;


IF COL_LENGTH(N'inv.InventoryTransactions', N'FailureId') IS NULL
    THROW 51001, 'Missing column: inv.InventoryTransactions.FailureId', 1;

IF COL_LENGTH(N'event.FailureRecords', N'FailureId') IS NULL
    THROW 51001, 'Missing column: event.FailureRecords.FailureId', 1;


IF COL_LENGTH(N'event.SparePartUsage', N'MaintenanceId') IS NULL
    THROW 51001, 'Missing column: event.SparePartUsage.MaintenanceId', 1;

IF COL_LENGTH(N'event.SparePartUsage', N'FailureId') IS NULL
    THROW 51001, 'Missing column: event.SparePartUsage.FailureId', 1;


/* ---------- Preflight Result ---------- */

PRINT 'Preflight checks completed successfully.';
PRINT '';


/* ============================================================
   10.1.2 — ORPHAN CHECKS
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.1.2 — ORPHAN CHECKS';
PRINT '============================================================';


DECLARE @OrphanCount BIGINT;


/* ------------------------------------------------------------
   1. rel.TripInstruments -> dbo.TripsInterlocks
   ------------------------------------------------------------ */

SELECT @OrphanCount = COUNT_BIG(*)
FROM rel.TripInstruments TI
LEFT JOIN dbo.TripsInterlocks T
    ON T.TripId = TI.TripId
WHERE T.TripId IS NULL;

IF @OrphanCount > 0
BEGIN
    THROW 51002,
          'Orphan records found: rel.TripInstruments.TripId -> dbo.TripsInterlocks.TripId',
          1;
END;


/* ------------------------------------------------------------
   2. inv.InventoryTransactions.MaintenanceId
      -> event.MaintenanceRecords.MaintenanceId
   ------------------------------------------------------------ */

SELECT @OrphanCount = COUNT_BIG(*)
FROM inv.InventoryTransactions IT
LEFT JOIN event.MaintenanceRecords MR
    ON MR.MaintenanceId = IT.MaintenanceId
WHERE IT.MaintenanceId IS NOT NULL
  AND MR.MaintenanceId IS NULL;

IF @OrphanCount > 0
BEGIN
    THROW 51002,
          'Orphan records found: inv.InventoryTransactions.MaintenanceId -> event.MaintenanceRecords.MaintenanceId',
          1;
END;


/* ------------------------------------------------------------
   3. inv.InventoryTransactions.FailureId
      -> event.FailureRecords.FailureId
   ------------------------------------------------------------ */

SELECT @OrphanCount = COUNT_BIG(*)
FROM inv.InventoryTransactions IT
LEFT JOIN event.FailureRecords FR
    ON FR.FailureId = IT.FailureId
WHERE IT.FailureId IS NOT NULL
  AND FR.FailureId IS NULL;

IF @OrphanCount > 0
BEGIN
    THROW 51002,
          'Orphan records found: inv.InventoryTransactions.FailureId -> event.FailureRecords.FailureId',
          1;
END;


/* ------------------------------------------------------------
   4. event.SparePartUsage.MaintenanceId
      -> event.MaintenanceRecords.MaintenanceId
   ------------------------------------------------------------ */

SELECT @OrphanCount = COUNT_BIG(*)
FROM event.SparePartUsage SPU
LEFT JOIN event.MaintenanceRecords MR
    ON MR.MaintenanceId = SPU.MaintenanceId
WHERE SPU.MaintenanceId IS NOT NULL
  AND MR.MaintenanceId IS NULL;

IF @OrphanCount > 0
BEGIN
    THROW 51002,
          'Orphan records found: event.SparePartUsage.MaintenanceId -> event.MaintenanceRecords.MaintenanceId',
          1;
END;


/* ------------------------------------------------------------
   5. event.SparePartUsage.FailureId
      -> event.FailureRecords.FailureId
   ------------------------------------------------------------ */

SELECT @OrphanCount = COUNT_BIG(*)
FROM event.SparePartUsage SPU
LEFT JOIN event.FailureRecords FR
    ON FR.FailureId = SPU.FailureId
WHERE SPU.FailureId IS NOT NULL
  AND FR.FailureId IS NULL;

IF @OrphanCount > 0
BEGIN
    THROW 51002,
          'Orphan records found: event.SparePartUsage.FailureId -> event.FailureRecords.FailureId',
          1;
END;


PRINT 'Orphan checks completed successfully.';
PRINT 'No orphan Foreign Key values were found.';
PRINT '';


/* ============================================================
   10.1.3 — ADD DEFERRED FOREIGN KEYS
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.1.3 — ADD DEFERRED FOREIGN KEYS';
PRINT '============================================================';


BEGIN TRY

    BEGIN TRANSACTION;


    /* --------------------------------------------------------
       1. TripInstruments -> TripsInterlocks
       -------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_TripInstruments_Trip'
          AND parent_object_id =
              OBJECT_ID(N'rel.TripInstruments')
    )
    BEGIN

        ALTER TABLE rel.TripInstruments
        WITH CHECK
        ADD CONSTRAINT FK_TripInstruments_Trip
        FOREIGN KEY (TripId)
        REFERENCES dbo.TripsInterlocks (TripId);

        ALTER TABLE rel.TripInstruments
        CHECK CONSTRAINT FK_TripInstruments_Trip;

        PRINT 'Created: FK_TripInstruments_Trip';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: FK_TripInstruments_Trip';

    END;


    /* --------------------------------------------------------
       2. InventoryTransactions.MaintenanceId
          -> MaintenanceRecords.MaintenanceId
       -------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_InventoryTransactions_Maintenance'
          AND parent_object_id =
              OBJECT_ID(N'inv.InventoryTransactions')
    )
    BEGIN

        ALTER TABLE inv.InventoryTransactions
        WITH CHECK
        ADD CONSTRAINT FK_InventoryTransactions_Maintenance
        FOREIGN KEY (MaintenanceId)
        REFERENCES event.MaintenanceRecords (MaintenanceId);

        ALTER TABLE inv.InventoryTransactions
        CHECK CONSTRAINT FK_InventoryTransactions_Maintenance;

        PRINT 'Created: FK_InventoryTransactions_Maintenance';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: FK_InventoryTransactions_Maintenance';

    END;


    /* --------------------------------------------------------
       3. InventoryTransactions.FailureId
          -> FailureRecords.FailureId
       -------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_InventoryTransactions_Failure'
          AND parent_object_id =
              OBJECT_ID(N'inv.InventoryTransactions')
    )
    BEGIN

        ALTER TABLE inv.InventoryTransactions
        WITH CHECK
        ADD CONSTRAINT FK_InventoryTransactions_Failure
        FOREIGN KEY (FailureId)
        REFERENCES event.FailureRecords (FailureId);

        ALTER TABLE inv.InventoryTransactions
        CHECK CONSTRAINT FK_InventoryTransactions_Failure;

        PRINT 'Created: FK_InventoryTransactions_Failure';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: FK_InventoryTransactions_Failure';

    END;


    /* --------------------------------------------------------
       4. SparePartUsage.MaintenanceId
          -> MaintenanceRecords.MaintenanceId
       -------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_SparePartUsage_Maintenance'
          AND parent_object_id =
              OBJECT_ID(N'event.SparePartUsage')
    )
    BEGIN

        ALTER TABLE event.SparePartUsage
        WITH CHECK
        ADD CONSTRAINT FK_SparePartUsage_Maintenance
        FOREIGN KEY (MaintenanceId)
        REFERENCES event.MaintenanceRecords (MaintenanceId);

        ALTER TABLE event.SparePartUsage
        CHECK CONSTRAINT FK_SparePartUsage_Maintenance;

        PRINT 'Created: FK_SparePartUsage_Maintenance';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: FK_SparePartUsage_Maintenance';

    END;


    /* --------------------------------------------------------
       5. SparePartUsage.FailureId
          -> FailureRecords.FailureId
       -------------------------------------------------------- */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_SparePartUsage_Failure'
          AND parent_object_id =
              OBJECT_ID(N'event.SparePartUsage')
    )
    BEGIN

        ALTER TABLE event.SparePartUsage
        WITH CHECK
        ADD CONSTRAINT FK_SparePartUsage_Failure
        FOREIGN KEY (FailureId)
        REFERENCES event.FailureRecords (FailureId);

        ALTER TABLE event.SparePartUsage
        CHECK CONSTRAINT FK_SparePartUsage_Failure;

        PRINT 'Created: FK_SparePartUsage_Failure';

    END
    ELSE
    BEGIN

        PRINT 'Already exists: FK_SparePartUsage_Failure';

    END;


    /* --------------------------------------------------------
       Commit
       -------------------------------------------------------- */

    COMMIT TRANSACTION;

    PRINT '';
    PRINT 'All deferred Foreign Keys were created successfully.';
    PRINT '';

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '';
    PRINT 'ERROR: Phase 10.1.3 failed.';
    PRINT 'All changes in the transaction were rolled back.';
    PRINT '';

    THROW;

END CATCH;


/* ============================================================
   10.1.4 — FOREIGN KEY VALIDATION
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.1.4 — FOREIGN KEY VALIDATION';
PRINT '============================================================';


SELECT
    fk.name AS ForeignKeyName,

    SCHEMA_NAME(parent_object.schema_id)
        + N'.'
        + parent_object.name AS ParentTable,

    parent_column.name AS ParentColumn,

    SCHEMA_NAME(referenced_object.schema_id)
        + N'.'
        + referenced_object.name AS ReferencedTable,

    referenced_column.name AS ReferencedColumn,

    fk.is_disabled AS IsDisabled,

    fk.is_not_trusted AS IsNotTrusted

FROM sys.foreign_keys fk

INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id

INNER JOIN sys.tables parent_object
    ON fk.parent_object_id = parent_object.object_id

INNER JOIN sys.columns parent_column
    ON fkc.parent_object_id = parent_column.object_id
   AND fkc.parent_column_id = parent_column.column_id

INNER JOIN sys.tables referenced_object
    ON fk.referenced_object_id = referenced_object.object_id

INNER JOIN sys.columns referenced_column
    ON fkc.referenced_object_id = referenced_column.object_id
   AND fkc.referenced_column_id = referenced_column.column_id

WHERE fk.name IN
(
    N'FK_TripInstruments_Trip',
    N'FK_InventoryTransactions_Maintenance',
    N'FK_InventoryTransactions_Failure',
    N'FK_SparePartUsage_Maintenance',
    N'FK_SparePartUsage_Failure'
)

ORDER BY fk.name;


PRINT '';
PRINT 'Expected: IsDisabled = 0 and IsNotTrusted = 0.';
PRINT '';


/* ============================================================
   10.1.5 — FINAL VERIFICATION
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.1.5 — FINAL VERIFICATION';
PRINT '============================================================';


DECLARE @ExpectedFKCount INT = 5;
DECLARE @ActualFKCount INT;


/* ---------- Count Expected Foreign Keys ---------- */

SELECT @ActualFKCount = COUNT(*)
FROM sys.foreign_keys
WHERE name IN
(
    N'FK_TripInstruments_Trip',
    N'FK_InventoryTransactions_Maintenance',
    N'FK_InventoryTransactions_Failure',
    N'FK_SparePartUsage_Maintenance',
    N'FK_SparePartUsage_Failure'
);


/* ---------- Verify Count ---------- */

IF @ActualFKCount <> @ExpectedFKCount
BEGIN

    THROW 51003,
          'Phase 10.1 verification failed: expected 5 deferred Foreign Keys.',
          1;

END;


/* ---------- Verify Disabled / Untrusted ---------- */

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE name IN
    (
        N'FK_TripInstruments_Trip',
        N'FK_InventoryTransactions_Maintenance',
        N'FK_InventoryTransactions_Failure',
        N'FK_SparePartUsage_Maintenance',
        N'FK_SparePartUsage_Failure'
    )
    AND
    (
        is_disabled = 1
        OR is_not_trusted = 1
    )
)
BEGIN

    THROW 51004,
          'Phase 10.1 verification failed: one or more Foreign Keys are disabled or not trusted.',
          1;

END;


/* ---------- Final Success ---------- */

PRINT '';
PRINT '============================================================';
PRINT 'PHASE 10.1 COMPLETED SUCCESSFULLY';
PRINT '============================================================';
PRINT '';
PRINT 'Deferred Foreign Keys: 5';
PRINT 'Foreign Keys verified: 5';
PRINT 'Disabled Foreign Keys: 0';
PRINT 'Untrusted Foreign Keys: 0';
PRINT '';
PRINT 'Database is ready for Phase 10.2 —';
PRINT 'Composite / Cross-Table Integrity.';
PRINT '============================================================';
GO