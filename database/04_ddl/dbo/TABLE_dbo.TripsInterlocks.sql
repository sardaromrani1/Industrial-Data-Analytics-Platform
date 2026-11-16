USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


/* ============================================================
   INDUSTRIAL DATA ANALYTICS PLATFORM
   PHASE 9 — GAP CORRECTION

   Entity:
       dbo.TripsInterlocks

   Purpose:
       Master definition of Trips / Interlocks.

   Relationship:
       dbo.TripsInterlocks
              |
              | 1 : N
              v
       rel.TripInstruments

   Temporary Decision:
       Personnel Foreign Keys are intentionally deferred.

       CreatedBy -> dbo.Personnel(PersonnelId)
       UpdatedBy -> dbo.Personnel(PersonnelId)

       The columns remain in the table.
       Only their Foreign Key constraints are deferred.

   Important:
       rel.TripInstruments already exists.
       This script does NOT recreate it.
   ============================================================ */


BEGIN TRY

    BEGIN TRANSACTION;


    /* ========================================================
       1. PRECHECKS
       ======================================================== */

    IF OBJECT_ID(N'dbo.ProcessUnits', N'U') IS NULL
        THROW 52001,
              'Required table dbo.ProcessUnits does not exist.',
              1;

    IF OBJECT_ID(N'rel.TripInstruments', N'U') IS NULL
        THROW 52001,
              'Required table rel.TripInstruments does not exist.',
              1;


    /* ========================================================
       2. VERIFY rel.TripInstruments.TripId
       ======================================================== */

    IF COL_LENGTH(N'rel.TripInstruments', N'TripId') IS NULL
        THROW 52002,
              'Column rel.TripInstruments.TripId does not exist.',
              1;


    /* ========================================================
       3. CREATE dbo.TripsInterlocks
       ======================================================== */

    IF OBJECT_ID(N'dbo.TripsInterlocks', N'U') IS NULL
    BEGIN

        CREATE TABLE dbo.TripsInterlocks
        (
            TripId INT IDENTITY(1,1) NOT NULL,

            /* ------------------------------------------------
               Business Identification
               ------------------------------------------------ */

            TripCode VARCHAR(100) NOT NULL,

            TripName NVARCHAR(200) NOT NULL,


            /* ------------------------------------------------
               Classification
               ------------------------------------------------ */

            TripTypeCode VARCHAR(50) NOT NULL,

            TripCategoryCode VARCHAR(50) NULL,


            /* ------------------------------------------------
               Operational Scope
               ------------------------------------------------ */

            ProcessUnitId INT NULL,


            /* ------------------------------------------------
               Functional Definition
               ------------------------------------------------ */

            Description NVARCHAR(1000) NULL,

            CauseDescription NVARCHAR(2000) NULL,

            ActionDescription NVARCHAR(2000) NULL,

            LogicDescription NVARCHAR(2000) NULL,

            ResetTypeCode VARCHAR(50) NULL,


            /* ------------------------------------------------
               Status
               ------------------------------------------------ */

            IsActive BIT NOT NULL
                CONSTRAINT DF_TripsInterlocks_IsActive
                DEFAULT (1),


            /* ------------------------------------------------
               Additional Information
               ------------------------------------------------ */

            Notes NVARCHAR(2000) NULL,


            /* ------------------------------------------------
               Audit
               ------------------------------------------------ */

            CreatedDateTime DATETIME2(0) NOT NULL
                CONSTRAINT DF_TripsInterlocks_CreatedDateTime
                DEFAULT (SYSUTCDATETIME()),

            CreatedBy INT NULL,

            UpdatedDateTime DATETIME2(0) NULL,

            UpdatedBy INT NULL,


            /* ------------------------------------------------
               Primary Key
               ------------------------------------------------ */

            CONSTRAINT PK_TripsInterlocks
                PRIMARY KEY (TripId),


            /* ------------------------------------------------
               Business Key
               ------------------------------------------------ */

            CONSTRAINT UQ_TripsInterlocks_TripCode
                UNIQUE (TripCode),


            /* ------------------------------------------------
               Foreign Key
               ------------------------------------------------
               
               ProcessUnit FK remains active because
               dbo.ProcessUnits already exists.
               
               Personnel FKs are intentionally deferred.
               ------------------------------------------------ */

            CONSTRAINT FK_TripsInterlocks_ProcessUnit
                FOREIGN KEY (ProcessUnitId)
                REFERENCES dbo.ProcessUnits(UnitId)
        );

        PRINT 'Created table: dbo.TripsInterlocks';

    END
    ELSE
    BEGIN

        PRINT 'Table already exists: dbo.TripsInterlocks';

    END;


    /* ========================================================
       4. VERIFY TripId COMPATIBILITY
       ======================================================== */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.columns c
        INNER JOIN sys.types t
            ON c.user_type_id = t.user_type_id
        WHERE c.object_id =
              OBJECT_ID(N'dbo.TripsInterlocks')
          AND c.name = N'TripId'
          AND t.name = N'int'
    )
    BEGIN

        THROW 52003,
              'dbo.TripsInterlocks.TripId is not INT. It must match rel.TripInstruments.TripId.',
              1;

    END;


    /* ========================================================
       5. VERIFY rel.TripInstruments.TripId TYPE
       ======================================================== */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.columns c
        INNER JOIN sys.types t
            ON c.user_type_id = t.user_type_id
        WHERE c.object_id =
              OBJECT_ID(N'rel.TripInstruments')
          AND c.name = N'TripId'
          AND t.name = N'int'
    )
    BEGIN

        THROW 52004,
              'rel.TripInstruments.TripId is not INT.',
              1;

    END;


    /* ========================================================
       6. ADD FK:
          rel.TripInstruments.TripId
              ->
          dbo.TripsInterlocks.TripId
       ======================================================== */

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
        REFERENCES dbo.TripsInterlocks(TripId);

        ALTER TABLE rel.TripInstruments
        CHECK CONSTRAINT FK_TripInstruments_Trip;

        PRINT 'Created FK: FK_TripInstruments_Trip';

    END
    ELSE
    BEGIN

        PRINT 'FK already exists: FK_TripInstruments_Trip';

    END;


    /* ========================================================
       7. VERIFY FK
       ======================================================== */

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.foreign_keys
        WHERE name = N'FK_TripInstruments_Trip'
          AND parent_object_id =
              OBJECT_ID(N'rel.TripInstruments')
          AND referenced_object_id =
              OBJECT_ID(N'dbo.TripsInterlocks')
          AND is_disabled = 0
          AND is_not_trusted = 0
    )
    BEGIN

        THROW 52005,
              'FK_TripInstruments_Trip was not created or is not trusted.',
              1;

    END;


    /* ========================================================
       8. COMMIT
       ======================================================== */

    COMMIT TRANSACTION;


    PRINT '';
    PRINT '============================================================';
    PRINT 'Trips / Interlocks Master successfully created.';
    PRINT '============================================================';
    PRINT '';
    PRINT 'Master Table: dbo.TripsInterlocks';
    PRINT 'Relationship: rel.TripInstruments';
    PRINT 'Foreign Key: FK_TripInstruments_Trip';
    PRINT 'ProcessUnit FK: Enabled';
    PRINT 'Personnel FKs: Deferred';
    PRINT 'FK Status: Enabled and Trusted';
    PRINT '';
    PRINT 'Phase 9 Gap Correction completed successfully.';
    PRINT '============================================================';


END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '';
    PRINT '============================================================';
    PRINT 'ERROR — Trips / Interlocks creation failed.';
    PRINT 'All changes were rolled back.';
    PRINT '============================================================';
    PRINT '';

    THROW;

END CATCH;
GO