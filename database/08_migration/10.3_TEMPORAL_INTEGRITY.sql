/*
========================================================================
PHASE 10.3 — TEMPORAL INTEGRITY
Database: ComprehensiveInstrumentationDB_New

Purpose:
    Enforce non-overlapping temporal intervals for:
      1. event.InstrumentLifecycle
      2. event.InstrumentOperationalStatusHistory
      3. event.InstrumentBypassHistory

Temporal policy:
    - Intervals use the half-open model [Start, End).
    - NULL End means an open-ended interval.
    - Adjacent intervals are allowed.
    - Equal Start and End values (zero-length intervals) are allowed
      and excluded from overlap detection.
    - At most one open-ended record per InstrumentId per target table.
    - INSERT and UPDATE are enforced set-wise by AFTER triggers.
    - Trigger DDL uses separate CREATE / ALTER dynamic batches for
      compatibility with SQL Server versions supporting THROW (2012+).
    - UPDLOCK / HOLDLOCK provide serializable protection for the trigger
      lookup, but concurrent workloads must still be tested for deadlocks
      and performance with the actual indexes and execution plans.

Execution:
    Run as one standalone batch. Do not insert GO statements anywhere
    between this script's transaction guard and END CATCH.

Important:
    This is an integrated reconstruction from the twelve reviewed
    sections and their approved rules. It has not been executed against
    SQL Server. Review the target database schema and test in a
    non-production environment before production deployment.
========================================================================
*/

USE ComprehensiveInstrumentationDB_New;

/* TRANSACTION EXECUTION GUARD */
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(
        'Phase 10.3 must be executed without an existing transaction.',
        16,
        1
    );
    RETURN;
END;

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    /* ================================================================
       PART 1 — PREFLIGHT: REQUIRED TABLES
       ================================================================ */

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.3 — TEMPORAL INTEGRITY';
    PRINT 'Starting execution...';
    PRINT '============================================================';

    IF OBJECT_ID(N'event.InstrumentLifecycle', N'U') IS NULL

    BEGIN

        ;THROW 51001, 'Missing required table: event.InstrumentLifecycle', 1;

    END;

    IF OBJECT_ID(N'event.InstrumentOperationalStatusHistory', N'U') IS NULL

    BEGIN

        ;THROW 51002, 'Missing required table: event.InstrumentOperationalStatusHistory', 1;

    END;

    IF OBJECT_ID(N'event.InstrumentBypassHistory', N'U') IS NULL

    BEGIN

        ;THROW 51003, 'Missing required table: event.InstrumentBypassHistory', 1;

    END;

    PRINT 'Required tables: OK';

    /* ================================================================
       PART 2 — PREFLIGHT: REQUIRED COLUMNS, TYPES AND PRIMARY KEYS
       ================================================================ */

    DECLARE @RequiredColumnDefinitions TABLE
    (
        SchemaName       SYSNAME NOT NULL,
        TableName        SYSNAME NOT NULL,
        ColumnName       SYSNAME NOT NULL,
        ExpectedType     SYSNAME NOT NULL,
        ExpectedScale    TINYINT NOT NULL,
        ExpectedNullable BIT NOT NULL,
        ExpectedIdentity BIT NOT NULL,
        PRIMARY KEY (SchemaName, TableName, ColumnName)
    );

    INSERT INTO @RequiredColumnDefinitions
    (
        SchemaName, TableName, ColumnName,
        ExpectedType, ExpectedScale, ExpectedNullable, ExpectedIdentity
    )
    VALUES
    (N'event', N'InstrumentLifecycle', N'InstrumentLifecycleId', N'int', 0, 0, 1),
    (N'event', N'InstrumentLifecycle', N'InstrumentId', N'int', 0, 0, 0),
    (N'event', N'InstrumentLifecycle', N'EffectiveFrom', N'datetime2', 0, 0, 0),
    (N'event', N'InstrumentLifecycle', N'EffectiveTo', N'datetime2', 0, 1, 0),

    (N'event', N'InstrumentOperationalStatusHistory', N'InstrumentOperationalStatusHistoryId', N'int', 0, 0, 1),
    (N'event', N'InstrumentOperationalStatusHistory', N'InstrumentId', N'int', 0, 0, 0),
    (N'event', N'InstrumentOperationalStatusHistory', N'EffectiveFrom', N'datetime2', 0, 0, 0),
    (N'event', N'InstrumentOperationalStatusHistory', N'EffectiveTo', N'datetime2', 0, 1, 0),

    (N'event', N'InstrumentBypassHistory', N'InstrumentBypassHistoryId', N'int', 0, 0, 1),
    (N'event', N'InstrumentBypassHistory', N'InstrumentId', N'int', 0, 0, 0),
    (N'event', N'InstrumentBypassHistory', N'BypassStartDateTime', N'datetime2', 0, 0, 0),
    (N'event', N'InstrumentBypassHistory', N'BypassEndDateTime', N'datetime2', 0, 1, 0);

    /* Explicit column-existence checks */
    IF COL_LENGTH(N'event.InstrumentLifecycle', N'InstrumentLifecycleId') IS NULL
    BEGIN
        ;THROW 51005, 'Missing column: event.InstrumentLifecycle.InstrumentLifecycleId', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentLifecycle', N'InstrumentId') IS NULL
    BEGIN
        ;THROW 51006, 'Missing column: event.InstrumentLifecycle.InstrumentId', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentLifecycle', N'EffectiveFrom') IS NULL
    BEGIN
        ;THROW 51007, 'Missing column: event.InstrumentLifecycle.EffectiveFrom', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentLifecycle', N'EffectiveTo') IS NULL
    BEGIN
        ;THROW 51008, 'Missing column: event.InstrumentLifecycle.EffectiveTo', 1;
    END;

    IF COL_LENGTH(N'event.InstrumentOperationalStatusHistory', N'InstrumentOperationalStatusHistoryId') IS NULL

    BEGIN

        ;THROW 51009, 'Missing column: event.InstrumentOperationalStatusHistory.InstrumentOperationalStatusHistoryId', 1;

    END;
    IF COL_LENGTH(N'event.InstrumentOperationalStatusHistory', N'InstrumentId') IS NULL
    BEGIN
        ;THROW 51010, 'Missing column: event.InstrumentOperationalStatusHistory.InstrumentId', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentOperationalStatusHistory', N'EffectiveFrom') IS NULL
    BEGIN
        ;THROW 51011, 'Missing column: event.InstrumentOperationalStatusHistory.EffectiveFrom', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentOperationalStatusHistory', N'EffectiveTo') IS NULL
    BEGIN
        ;THROW 51012, 'Missing column: event.InstrumentOperationalStatusHistory.EffectiveTo', 1;
    END;

    IF COL_LENGTH(N'event.InstrumentBypassHistory', N'InstrumentBypassHistoryId') IS NULL

    BEGIN

        ;THROW 51013, 'Missing column: event.InstrumentBypassHistory.InstrumentBypassHistoryId', 1;

    END;
    IF COL_LENGTH(N'event.InstrumentBypassHistory', N'InstrumentId') IS NULL
    BEGIN
        ;THROW 51014, 'Missing column: event.InstrumentBypassHistory.InstrumentId', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentBypassHistory', N'BypassStartDateTime') IS NULL
    BEGIN
        ;THROW 51015, 'Missing column: event.InstrumentBypassHistory.BypassStartDateTime', 1;
    END;
    IF COL_LENGTH(N'event.InstrumentBypassHistory', N'BypassEndDateTime') IS NULL
    BEGIN
        ;THROW 51016, 'Missing column: event.InstrumentBypassHistory.BypassEndDateTime', 1;
    END;

    /* Validate SQL data type, scale, nullability and identity metadata */
    IF EXISTS
    (
        SELECT 1
        FROM @RequiredColumnDefinitions R
        JOIN sys.schemas S ON S.name = R.SchemaName
        JOIN sys.tables T ON T.schema_id = S.schema_id AND T.name = R.TableName
        JOIN sys.columns C ON C.object_id = T.object_id AND C.name = R.ColumnName
        JOIN sys.types TY ON TY.user_type_id = C.user_type_id
        WHERE TY.name <> R.ExpectedType
           OR C.scale <> R.ExpectedScale
           OR C.is_nullable <> R.ExpectedNullable
           OR C.is_identity <> R.ExpectedIdentity
    )
    BEGIN
        SELECT
            R.SchemaName, R.TableName, R.ColumnName,
            R.ExpectedType, TY.name AS ActualType,
            R.ExpectedScale, C.scale AS ActualScale,
            R.ExpectedNullable, C.is_nullable AS ActualNullable,
            R.ExpectedIdentity, C.is_identity AS ActualIdentity
        FROM @RequiredColumnDefinitions R
        JOIN sys.schemas S ON S.name = R.SchemaName
        JOIN sys.tables T ON T.schema_id = S.schema_id AND T.name = R.TableName
        JOIN sys.columns C ON C.object_id = T.object_id AND C.name = R.ColumnName
        JOIN sys.types TY ON TY.user_type_id = C.user_type_id
        WHERE TY.name <> R.ExpectedType
           OR C.scale <> R.ExpectedScale
           OR C.is_nullable <> R.ExpectedNullable
           OR C.is_identity <> R.ExpectedIdentity;

        ;THROW 51026, 'Required column metadata does not match the expected definition.', 1;
    END;

    /* Each expected primary key must consist of exactly its ID column. */
    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints KC
        JOIN sys.tables T ON T.object_id = KC.parent_object_id
        JOIN sys.schemas S ON S.schema_id = T.schema_id
        JOIN sys.index_columns IC
          ON IC.object_id = KC.parent_object_id
         AND IC.index_id = KC.unique_index_id
        JOIN sys.columns C
          ON C.object_id = IC.object_id
         AND C.column_id = IC.column_id
        WHERE S.name = N'event'
          AND T.name = N'InstrumentLifecycle'
          AND KC.type = 'PK'
          AND C.name = N'InstrumentLifecycleId'
          AND IC.key_ordinal = 1
          AND (SELECT COUNT(*) FROM sys.index_columns IC2
               WHERE IC2.object_id = KC.parent_object_id
                 AND IC2.index_id = KC.unique_index_id
                 AND IC2.key_ordinal > 0) = 1
    )
    BEGIN
        ;THROW 51027, 'InstrumentLifecycle must have InstrumentLifecycleId as its single-column primary key.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints KC
        JOIN sys.tables T ON T.object_id = KC.parent_object_id
        JOIN sys.schemas S ON S.schema_id = T.schema_id
        JOIN sys.index_columns IC
          ON IC.object_id = KC.parent_object_id
         AND IC.index_id = KC.unique_index_id
        JOIN sys.columns C
          ON C.object_id = IC.object_id
         AND C.column_id = IC.column_id
        WHERE S.name = N'event'
          AND T.name = N'InstrumentOperationalStatusHistory'
          AND KC.type = 'PK'
          AND C.name = N'InstrumentOperationalStatusHistoryId'
          AND IC.key_ordinal = 1
          AND (SELECT COUNT(*) FROM sys.index_columns IC2
               WHERE IC2.object_id = KC.parent_object_id
                 AND IC2.index_id = KC.unique_index_id
                 AND IC2.key_ordinal > 0) = 1
    )
    BEGIN
        ;THROW 51028, 'InstrumentOperationalStatusHistory must have InstrumentOperationalStatusHistoryId as its single-column primary key.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.key_constraints KC
        JOIN sys.tables T ON T.object_id = KC.parent_object_id
        JOIN sys.schemas S ON S.schema_id = T.schema_id
        JOIN sys.index_columns IC
          ON IC.object_id = KC.parent_object_id
         AND IC.index_id = KC.unique_index_id
        JOIN sys.columns C
          ON C.object_id = IC.object_id
         AND C.column_id = IC.column_id
        WHERE S.name = N'event'
          AND T.name = N'InstrumentBypassHistory'
          AND KC.type = 'PK'
          AND C.name = N'InstrumentBypassHistoryId'
          AND IC.key_ordinal = 1
          AND (SELECT COUNT(*) FROM sys.index_columns IC2
               WHERE IC2.object_id = KC.parent_object_id
                 AND IC2.index_id = KC.unique_index_id
                 AND IC2.key_ordinal > 0) = 1
    )
    BEGIN
        ;THROW 51029, 'InstrumentBypassHistory must have InstrumentBypassHistoryId as its single-column primary key.', 1;
    END;

    PRINT 'Required columns, metadata and primary keys: OK';

    /* ================================================================
       PART 3 — EXISTING DATA AUDIT: INVALID DATE RANGES
       ================================================================ */

    PRINT '';
    PRINT 'Auditing existing invalid date ranges...';

    IF EXISTS
    (
        SELECT 1 FROM event.InstrumentLifecycle
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom
    )
    BEGIN
        SELECT InstrumentLifecycleId, InstrumentId, EffectiveFrom, EffectiveTo
        FROM event.InstrumentLifecycle
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom;
        ;THROW 51030, 'Existing invalid date ranges found in InstrumentLifecycle.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM event.InstrumentOperationalStatusHistory
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom
    )
    BEGIN
        SELECT InstrumentOperationalStatusHistoryId, InstrumentId, EffectiveFrom, EffectiveTo
        FROM event.InstrumentOperationalStatusHistory
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom;
        ;THROW 51031, 'Existing invalid date ranges found in InstrumentOperationalStatusHistory.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM event.InstrumentBypassHistory
        WHERE BypassEndDateTime IS NOT NULL
          AND BypassEndDateTime < BypassStartDateTime
    )
    BEGIN
        SELECT InstrumentBypassHistoryId, InstrumentId, BypassStartDateTime, BypassEndDateTime
        FROM event.InstrumentBypassHistory
        WHERE BypassEndDateTime IS NOT NULL
          AND BypassEndDateTime < BypassStartDateTime;
        ;THROW 51032, 'Existing invalid date ranges found in InstrumentBypassHistory.', 1;
    END;

    PRINT 'Existing date range audit: PASSED';

    /* ================================================================
       PART 4 — EXISTING DATA AUDIT: OVERLAPPING INTERVALS
       ================================================================ */

    PRINT '';
    PRINT 'Auditing existing overlapping intervals...';

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentLifecycle A
        JOIN event.InstrumentLifecycle B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentLifecycleId < B.InstrumentLifecycleId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo)
    )
    BEGIN
        SELECT A.InstrumentLifecycleId AS RecordA_Id,
               B.InstrumentLifecycleId AS RecordB_Id,
               A.InstrumentId,
               A.EffectiveFrom AS RecordA_Start, A.EffectiveTo AS RecordA_End,
               B.EffectiveFrom AS RecordB_Start, B.EffectiveTo AS RecordB_End
        FROM event.InstrumentLifecycle A
        JOIN event.InstrumentLifecycle B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentLifecycleId < B.InstrumentLifecycleId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo);
        ;THROW 51033, 'Existing overlapping intervals found in InstrumentLifecycle.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory A
        JOIN event.InstrumentOperationalStatusHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentOperationalStatusHistoryId < B.InstrumentOperationalStatusHistoryId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo)
    )
    BEGIN
        SELECT A.InstrumentOperationalStatusHistoryId AS RecordA_Id,
               B.InstrumentOperationalStatusHistoryId AS RecordB_Id,
               A.InstrumentId,
               A.EffectiveFrom AS RecordA_Start, A.EffectiveTo AS RecordA_End,
               B.EffectiveFrom AS RecordB_Start, B.EffectiveTo AS RecordB_End
        FROM event.InstrumentOperationalStatusHistory A
        JOIN event.InstrumentOperationalStatusHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentOperationalStatusHistoryId < B.InstrumentOperationalStatusHistoryId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo);
        ;THROW 51034, 'Existing overlapping intervals found in InstrumentOperationalStatusHistory.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentBypassHistory A
        JOIN event.InstrumentBypassHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentBypassHistoryId < B.InstrumentBypassHistoryId
        WHERE (A.BypassEndDateTime IS NULL OR A.BypassEndDateTime > A.BypassStartDateTime)
          AND (B.BypassEndDateTime IS NULL OR B.BypassEndDateTime > B.BypassStartDateTime)
          AND (A.BypassEndDateTime IS NULL OR B.BypassStartDateTime < A.BypassEndDateTime)
          AND (B.BypassEndDateTime IS NULL OR A.BypassStartDateTime < B.BypassEndDateTime)
    )
    BEGIN
        SELECT A.InstrumentBypassHistoryId AS RecordA_Id,
               B.InstrumentBypassHistoryId AS RecordB_Id,
               A.InstrumentId,
               A.BypassStartDateTime AS RecordA_Start, A.BypassEndDateTime AS RecordA_End,
               B.BypassStartDateTime AS RecordB_Start, B.BypassEndDateTime AS RecordB_End
        FROM event.InstrumentBypassHistory A
        JOIN event.InstrumentBypassHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentBypassHistoryId < B.InstrumentBypassHistoryId
        WHERE (A.BypassEndDateTime IS NULL OR A.BypassEndDateTime > A.BypassStartDateTime)
          AND (B.BypassEndDateTime IS NULL OR B.BypassEndDateTime > B.BypassStartDateTime)
          AND (A.BypassEndDateTime IS NULL OR B.BypassStartDateTime < A.BypassEndDateTime)
          AND (B.BypassEndDateTime IS NULL OR A.BypassStartDateTime < B.BypassEndDateTime);
        ;THROW 51035, 'Existing overlapping intervals found in InstrumentBypassHistory.', 1;
    END;

    PRINT 'Existing overlap audit: PASSED';

    /* ================================================================
       PART 5 — EXISTING DATA AUDIT: MULTIPLE OPEN RECORDS
       ================================================================ */

    PRINT '';
    PRINT 'Auditing multiple open-ended records...';

    IF EXISTS
    (
        SELECT InstrumentId
        FROM event.InstrumentLifecycle
        WHERE EffectiveTo IS NULL
        GROUP BY InstrumentId
        HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        SELECT InstrumentId, COUNT_BIG(*) AS OpenRecordCount
        FROM event.InstrumentLifecycle
        WHERE EffectiveTo IS NULL
        GROUP BY InstrumentId
        HAVING COUNT_BIG(*) > 1;
        ;THROW 51036, 'Multiple open InstrumentLifecycle records found for an instrument.', 1;
    END;

    IF EXISTS
    (
        SELECT InstrumentId
        FROM event.InstrumentOperationalStatusHistory
        WHERE EffectiveTo IS NULL
        GROUP BY InstrumentId
        HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        SELECT InstrumentId, COUNT_BIG(*) AS OpenRecordCount
        FROM event.InstrumentOperationalStatusHistory
        WHERE EffectiveTo IS NULL
        GROUP BY InstrumentId
        HAVING COUNT_BIG(*) > 1;
        ;THROW 51037, 'Multiple open InstrumentOperationalStatusHistory records found for an instrument.', 1;
    END;

    IF EXISTS
    (
        SELECT InstrumentId
        FROM event.InstrumentBypassHistory
        WHERE BypassEndDateTime IS NULL
        GROUP BY InstrumentId
        HAVING COUNT_BIG(*) > 1
    )
    BEGIN
        SELECT InstrumentId, COUNT_BIG(*) AS OpenRecordCount
        FROM event.InstrumentBypassHistory
        WHERE BypassEndDateTime IS NULL
        GROUP BY InstrumentId
        HAVING COUNT_BIG(*) > 1;
        ;THROW 51038, 'Multiple open InstrumentBypassHistory records found for an instrument.', 1;
    END;

    PRINT 'Multiple open record audit: PASSED';

    /* ================================================================
       PART 6 — TRIGGER: INSTRUMENT LIFECYCLE
       ================================================================ */

    DECLARE @TriggerSQL NVARCHAR(MAX);

    /* CREATE or ALTER is selected before executing a dedicated DDL batch. */
    SET @TriggerSQL = N'
CREATE TRIGGER event.TR_InstrumentLifecycle_NoOverlap
ON event.InstrumentLifecycle
AFTER INSERT, UPDATE
AS
BEGIN
    IF ROWCOUNT_BIG() = 0 RETURN;
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN event.InstrumentLifecycle T WITH (UPDLOCK, HOLDLOCK)
          ON T.InstrumentId = I.InstrumentId
         AND T.InstrumentLifecycleId <> I.InstrumentLifecycleId
        WHERE (I.EffectiveTo IS NULL OR I.EffectiveTo > I.EffectiveFrom)
          AND (T.EffectiveTo IS NULL OR T.EffectiveTo > T.EffectiveFrom)
          AND (I.EffectiveTo IS NULL OR T.EffectiveFrom < I.EffectiveTo)
          AND (T.EffectiveTo IS NULL OR I.EffectiveFrom < T.EffectiveTo)
    )
    BEGIN
        ;THROW 51100, ''Temporal integrity violation: overlapping InstrumentLifecycle intervals.'', 1;
    END;
END;';

    IF OBJECT_ID(N'event.TR_InstrumentLifecycle_NoOverlap', N'TR') IS NOT NULL
        SET @TriggerSQL = REPLACE(@TriggerSQL, N'CREATE TRIGGER', N'ALTER TRIGGER');

    EXEC sys.sp_executesql @TriggerSQL;
    ENABLE TRIGGER event.TR_InstrumentLifecycle_NoOverlap
        ON event.InstrumentLifecycle;

    /* ================================================================
       PART 7 — TRIGGER: OPERATIONAL STATUS
       ================================================================ */

    SET @TriggerSQL = N'
CREATE TRIGGER event.TR_InstrumentOperationalStatus_NoOverlap
ON event.InstrumentOperationalStatusHistory
AFTER INSERT, UPDATE
AS
BEGIN
    IF ROWCOUNT_BIG() = 0 RETURN;
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN event.InstrumentOperationalStatusHistory T WITH (UPDLOCK, HOLDLOCK)
          ON T.InstrumentId = I.InstrumentId
         AND T.InstrumentOperationalStatusHistoryId <> I.InstrumentOperationalStatusHistoryId
        WHERE (I.EffectiveTo IS NULL OR I.EffectiveTo > I.EffectiveFrom)
          AND (T.EffectiveTo IS NULL OR T.EffectiveTo > T.EffectiveFrom)
          AND (I.EffectiveTo IS NULL OR T.EffectiveFrom < I.EffectiveTo)
          AND (T.EffectiveTo IS NULL OR I.EffectiveFrom < T.EffectiveTo)
    )
    BEGIN
        ;THROW 51101, ''Temporal integrity violation: overlapping InstrumentOperationalStatusHistory intervals.'', 1;
    END;
END;';

    IF OBJECT_ID(N'event.TR_InstrumentOperationalStatus_NoOverlap', N'TR') IS NOT NULL
        SET @TriggerSQL = REPLACE(@TriggerSQL, N'CREATE TRIGGER', N'ALTER TRIGGER');

    EXEC sys.sp_executesql @TriggerSQL;
    ENABLE TRIGGER event.TR_InstrumentOperationalStatus_NoOverlap
        ON event.InstrumentOperationalStatusHistory;

    /* ================================================================
       PART 8 — TRIGGER: INSTRUMENT BYPASS
       ================================================================ */

    SET @TriggerSQL = N'
CREATE TRIGGER event.TR_InstrumentBypass_NoOverlap
ON event.InstrumentBypassHistory
AFTER INSERT, UPDATE
AS
BEGIN
    IF ROWCOUNT_BIG() = 0 RETURN;
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN event.InstrumentBypassHistory T WITH (UPDLOCK, HOLDLOCK)
          ON T.InstrumentId = I.InstrumentId
         AND T.InstrumentBypassHistoryId <> I.InstrumentBypassHistoryId
        WHERE (I.BypassEndDateTime IS NULL OR I.BypassEndDateTime > I.BypassStartDateTime)
          AND (T.BypassEndDateTime IS NULL OR T.BypassEndDateTime > T.BypassStartDateTime)
          AND (I.BypassEndDateTime IS NULL OR T.BypassStartDateTime < I.BypassEndDateTime)
          AND (T.BypassEndDateTime IS NULL OR I.BypassStartDateTime < T.BypassEndDateTime)
    )
    BEGIN
        ;THROW 51102, ''Temporal integrity violation: overlapping InstrumentBypassHistory intervals.'', 1;
    END;
END;';

    IF OBJECT_ID(N'event.TR_InstrumentBypass_NoOverlap', N'TR') IS NOT NULL
        SET @TriggerSQL = REPLACE(@TriggerSQL, N'CREATE TRIGGER', N'ALTER TRIGGER');

    EXEC sys.sp_executesql @TriggerSQL;
    ENABLE TRIGGER event.TR_InstrumentBypass_NoOverlap
        ON event.InstrumentBypassHistory;

    /* ================================================================
       PART 9 — TRIGGER VALIDATION: EXISTENCE AND ENABLED STATE
       ================================================================ */

    DECLARE @RequiredTriggers TABLE
    (
        SchemaName SYSNAME NOT NULL,
        TableName SYSNAME NOT NULL,
        TriggerName SYSNAME NOT NULL
    );

    INSERT INTO @RequiredTriggers (SchemaName, TableName, TriggerName)
    VALUES
    (N'event', N'InstrumentLifecycle', N'TR_InstrumentLifecycle_NoOverlap'),
    (N'event', N'InstrumentOperationalStatusHistory', N'TR_InstrumentOperationalStatus_NoOverlap'),
    (N'event', N'InstrumentBypassHistory', N'TR_InstrumentBypass_NoOverlap');

    IF EXISTS
    (
        SELECT 1
        FROM @RequiredTriggers R
        LEFT JOIN sys.schemas S ON S.name = R.SchemaName
        LEFT JOIN sys.tables T ON T.schema_id = S.schema_id AND T.name = R.TableName
        LEFT JOIN sys.triggers TR ON TR.name = R.TriggerName AND TR.parent_id = T.object_id
        WHERE S.schema_id IS NULL
           OR T.object_id IS NULL
           OR TR.object_id IS NULL
           OR TR.parent_class <> 1
           OR TR.type <> 'TR'
           OR TR.is_instead_of_trigger = 1
           OR TR.is_disabled <> 0
    )
    BEGIN
        SELECT
            R.SchemaName, R.TableName, R.TriggerName,
            CASE
                WHEN S.schema_id IS NULL THEN 'MISSING SCHEMA'
                WHEN T.object_id IS NULL THEN 'MISSING TABLE'
                WHEN TR.object_id IS NULL THEN 'MISSING TRIGGER OR INCORRECT ATTACHMENT'
                WHEN TR.parent_class <> 1 THEN 'INVALID PARENT CLASS'
                WHEN TR.type <> 'TR' THEN 'INVALID TRIGGER TYPE'
                WHEN TR.is_instead_of_trigger = 1 THEN 'INSTEAD OF TRIGGER; AFTER TRIGGER REQUIRED'
                WHEN TR.is_disabled = 1 THEN 'TRIGGER DISABLED'
                ELSE 'UNKNOWN VALIDATION ERROR'
            END AS ValidationStatus,
            TR.is_disabled, TR.type, TR.parent_class,
            TR.is_instead_of_trigger
        FROM @RequiredTriggers R
        LEFT JOIN sys.schemas S ON S.name = R.SchemaName
        LEFT JOIN sys.tables T ON T.schema_id = S.schema_id AND T.name = R.TableName
        LEFT JOIN sys.triggers TR ON TR.name = R.TriggerName AND TR.parent_id = T.object_id;

        ;THROW 51110, 'Trigger validation failed. Review the preceding validation result.', 1;
    END;

    SELECT
        S.name AS SchemaName,
        T.name AS ParentTable,
        TR.name AS TriggerName,
        TR.type_desc AS TriggerType,
        TR.parent_class_desc AS ParentClass,
        TR.is_instead_of_trigger AS IsInsteadOfTrigger,
        TR.is_disabled AS IsDisabled,
        CASE WHEN TR.is_disabled = 0 THEN 'ENABLED' ELSE 'DISABLED' END AS TriggerStatus
    FROM sys.triggers TR
    JOIN sys.tables T ON T.object_id = TR.parent_id
    JOIN sys.schemas S ON S.schema_id = T.schema_id
    JOIN @RequiredTriggers R
      ON R.SchemaName = S.name
     AND R.TableName = T.name
     AND R.TriggerName = TR.name
    ORDER BY R.TriggerName;

    PRINT 'All required triggers exist, are correctly attached and enabled.';

    /* ================================================================
       PART 10 — FINAL DATA VALIDATION: OVERLAPPING INTERVALS
       ================================================================ */

    PRINT '';
    PRINT 'Final validation: overlapping intervals...';

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentLifecycle A
        JOIN event.InstrumentLifecycle B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentLifecycleId < B.InstrumentLifecycleId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo)
    )
    BEGIN
        SELECT A.InstrumentLifecycleId AS RecordA_Id,
               B.InstrumentLifecycleId AS RecordB_Id,
               A.InstrumentId,
               A.EffectiveFrom AS RecordA_Start, A.EffectiveTo AS RecordA_End,
               B.EffectiveFrom AS RecordB_Start, B.EffectiveTo AS RecordB_End
        FROM event.InstrumentLifecycle A
        JOIN event.InstrumentLifecycle B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentLifecycleId < B.InstrumentLifecycleId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo)
        ORDER BY A.InstrumentId, A.EffectiveFrom, B.EffectiveFrom;
        ;THROW 51120, 'Final validation failed: overlapping InstrumentLifecycle intervals detected.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentOperationalStatusHistory A
        JOIN event.InstrumentOperationalStatusHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentOperationalStatusHistoryId < B.InstrumentOperationalStatusHistoryId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo)
    )
    BEGIN
        SELECT A.InstrumentOperationalStatusHistoryId AS RecordA_Id,
               B.InstrumentOperationalStatusHistoryId AS RecordB_Id,
               A.InstrumentId,
               A.EffectiveFrom AS RecordA_Start, A.EffectiveTo AS RecordA_End,
               B.EffectiveFrom AS RecordB_Start, B.EffectiveTo AS RecordB_End
        FROM event.InstrumentOperationalStatusHistory A
        JOIN event.InstrumentOperationalStatusHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentOperationalStatusHistoryId < B.InstrumentOperationalStatusHistoryId
        WHERE (A.EffectiveTo IS NULL OR A.EffectiveTo > A.EffectiveFrom)
          AND (B.EffectiveTo IS NULL OR B.EffectiveTo > B.EffectiveFrom)
          AND (A.EffectiveTo IS NULL OR B.EffectiveFrom < A.EffectiveTo)
          AND (B.EffectiveTo IS NULL OR A.EffectiveFrom < B.EffectiveTo)
        ORDER BY A.InstrumentId, A.EffectiveFrom, B.EffectiveFrom;
        ;THROW 51121, 'Final validation failed: overlapping InstrumentOperationalStatusHistory intervals detected.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM event.InstrumentBypassHistory A
        JOIN event.InstrumentBypassHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentBypassHistoryId < B.InstrumentBypassHistoryId
        WHERE (A.BypassEndDateTime IS NULL OR A.BypassEndDateTime > A.BypassStartDateTime)
          AND (B.BypassEndDateTime IS NULL OR B.BypassEndDateTime > B.BypassStartDateTime)
          AND (A.BypassEndDateTime IS NULL OR B.BypassStartDateTime < A.BypassEndDateTime)
          AND (B.BypassEndDateTime IS NULL OR A.BypassStartDateTime < B.BypassEndDateTime)
    )
    BEGIN
        SELECT A.InstrumentBypassHistoryId AS RecordA_Id,
               B.InstrumentBypassHistoryId AS RecordB_Id,
               A.InstrumentId,
               A.BypassStartDateTime AS RecordA_Start, A.BypassEndDateTime AS RecordA_End,
               B.BypassStartDateTime AS RecordB_Start, B.BypassEndDateTime AS RecordB_End
        FROM event.InstrumentBypassHistory A
        JOIN event.InstrumentBypassHistory B
          ON B.InstrumentId = A.InstrumentId
         AND A.InstrumentBypassHistoryId < B.InstrumentBypassHistoryId
        WHERE (A.BypassEndDateTime IS NULL OR A.BypassEndDateTime > A.BypassStartDateTime)
          AND (B.BypassEndDateTime IS NULL OR B.BypassEndDateTime > B.BypassStartDateTime)
          AND (A.BypassEndDateTime IS NULL OR B.BypassStartDateTime < A.BypassEndDateTime)
          AND (B.BypassEndDateTime IS NULL OR A.BypassStartDateTime < B.BypassEndDateTime)
        ORDER BY A.InstrumentId, A.BypassStartDateTime, B.BypassStartDateTime;
        ;THROW 51122, 'Final validation failed: overlapping InstrumentBypassHistory intervals detected.', 1;
    END;

    PRINT 'Final overlap validation: PASSED';

    /* ================================================================
       PART 11 — FINAL DATA VALIDATION: INVALID DATE RANGES
       ================================================================ */

    PRINT '';
    PRINT 'Final validation: invalid date ranges...';

    IF EXISTS
    (
        SELECT 1 FROM event.InstrumentLifecycle
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom
    )
    BEGIN
        SELECT InstrumentLifecycleId, InstrumentId, EffectiveFrom, EffectiveTo
        FROM event.InstrumentLifecycle
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom
        ORDER BY InstrumentId, EffectiveFrom;
        ;THROW 51130, 'Final validation failed: invalid InstrumentLifecycle date ranges detected.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM event.InstrumentOperationalStatusHistory
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom
    )
    BEGIN
        SELECT InstrumentOperationalStatusHistoryId, InstrumentId, EffectiveFrom, EffectiveTo
        FROM event.InstrumentOperationalStatusHistory
        WHERE EffectiveTo IS NOT NULL AND EffectiveTo < EffectiveFrom
        ORDER BY InstrumentId, EffectiveFrom;
        ;THROW 51131, 'Final validation failed: invalid InstrumentOperationalStatusHistory date ranges detected.', 1;
    END;

    IF EXISTS
    (
        SELECT 1 FROM event.InstrumentBypassHistory
        WHERE BypassEndDateTime IS NOT NULL
          AND BypassEndDateTime < BypassStartDateTime
    )
    BEGIN
        SELECT InstrumentBypassHistoryId, InstrumentId, BypassStartDateTime, BypassEndDateTime
        FROM event.InstrumentBypassHistory
        WHERE BypassEndDateTime IS NOT NULL
          AND BypassEndDateTime < BypassStartDateTime
        ORDER BY InstrumentId, BypassStartDateTime;
        ;THROW 51132, 'Final validation failed: invalid InstrumentBypassHistory date ranges detected.', 1;
    END;

    PRINT 'Final invalid date range validation: PASSED';

    /* ================================================================
       PART 12 — COMMIT, SUCCESS MESSAGE & ERROR HANDLING
       ================================================================ */

    COMMIT TRANSACTION;

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.3 — TEMPORAL INTEGRITY';
    PRINT 'COMPLETED SUCCESSFULLY';
    PRINT '============================================================';
    PRINT '1. Required tables and columns: PASSED';
    PRINT '2. Existing data audit: PASSED';
    PRINT '3. Invalid date range audit: PASSED';
    PRINT '4. Overlapping interval audit: PASSED';
    PRINT '5. Multiple open records audit: PASSED';
    PRINT '6. Temporal integrity triggers: CREATED / ALTERED';
    PRINT '7. Trigger existence and enabled state: PASSED';
    PRINT '8. Final overlapping interval validation: PASSED';
    PRINT '9. Final invalid date range validation: PASSED';
    PRINT 'All Phase 10.3 operations were committed successfully.';
    PRINT '============================================================';

END TRY
BEGIN CATCH

    DECLARE @ErrorNumber INT;
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorLine INT;
    DECLARE @ErrorProcedure NVARCHAR(128);
    DECLARE @ErrorMessage NVARCHAR(4000);

    SELECT
        @ErrorNumber = ERROR_NUMBER(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorLine = ERROR_LINE(),
        @ErrorProcedure = ERROR_PROCEDURE(),
        @ErrorMessage = ERROR_MESSAGE();

    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Transaction rolled back.';
    END;

    PRINT '';
    PRINT '============================================================';
    PRINT 'PHASE 10.3 — EXECUTION FAILED';
    PRINT '============================================================';
    PRINT 'Error Number: ' + CAST(@ErrorNumber AS VARCHAR(20));
    PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS VARCHAR(20));
    PRINT 'Error State: ' + CAST(@ErrorState AS VARCHAR(20));
    PRINT 'Error Line: ' + CAST(@ErrorLine AS VARCHAR(20));
    PRINT 'Error Procedure: ' + ISNULL(@ErrorProcedure, 'N/A');
    PRINT 'Error Message: ' + @ErrorMessage;
    PRINT '============================================================';

    THROW;

END CATCH;
    END;
