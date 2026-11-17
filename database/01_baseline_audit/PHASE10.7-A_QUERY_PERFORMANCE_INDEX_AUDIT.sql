/*====================================================================
  INDUSTRIAL DATA ANALYTICS PLATFORM
  Database: ComprehensiveInstrumentationDB_New

  PHASE 10.7-A
  QUERY / PERFORMANCE INDEX AUDIT

  PURPOSE
  -------
  1. Audit current physical indexes
  2. Audit index key/include columns
  3. Audit current index usage statistics
  4. Discover real event date/time columns
  5. Define expected query/workload patterns
  6. Compare workload patterns against existing indexes
  7. Identify possible performance-index candidates
  8. Identify overlap with existing FK-supporting indexes
  9. Optionally inspect Query Store
 10. Produce a final summary

  IMPORTANT
  ---------
  READ-ONLY SCRIPT

  This script DOES NOT:
      CREATE INDEX
      ALTER INDEX
      DROP INDEX
      ALTER TABLE
      CREATE CONSTRAINT
      DROP CONSTRAINT

  Temporary tables (#...) are created only inside tempdb and are
  automatically removed at the end of the session.

====================================================================*/

USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
SET XACT_ABORT OFF;

PRINT '==============================================================';
PRINT 'PHASE 10.7-A - QUERY / PERFORMANCE INDEX AUDIT';
PRINT 'Database: ' + DB_NAME();
PRINT 'Start Time: ' + CONVERT(varchar(30), SYSDATETIME(), 121);
PRINT 'READ-ONLY AUDIT';
PRINT '==============================================================';


/*====================================================================
  PART 0 - ENVIRONMENT
====================================================================*/

SELECT
    DB_NAME() AS DatabaseName,
    DB_ID() AS DatabaseId,
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('ProductVersion') AS SQLServerVersion,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('Edition') AS Edition,
    SYSDATETIME() AS AuditStartDateTime;


/*====================================================================
  PART 1 - DATABASE OBJECT / TABLE INVENTORY
====================================================================*/

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    t.object_id AS ObjectId,
    SUM(p.rows) AS ApproxRowCount
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions AS p
    ON p.object_id = t.object_id
   AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY
    s.name,
    t.name,
    t.object_id
ORDER BY
    s.name,
    t.name;


/*====================================================================
  PART 2 - COMPLETE INDEX INVENTORY
====================================================================*/

IF OBJECT_ID('tempdb..#IndexCatalog') IS NOT NULL
    DROP TABLE #IndexCatalog;

CREATE TABLE #IndexCatalog
(
    SchemaName              sysname,
    TableName               sysname,
    ObjectId                int,
    IndexId                 int,
    IndexName               sysname NULL,
    IndexType               nvarchar(60),
    IsUnique                bit,
    IsPrimaryKey            bit,
    IsUniqueConstraint      bit,
    IsDisabled              bit,
    IsHypothetical          bit,
    KeyColumns              nvarchar(max) NULL,
    IncludedColumns         nvarchar(max) NULL,
    FilterDefinition        nvarchar(max) NULL
);

INSERT INTO #IndexCatalog
(
    SchemaName,
    TableName,
    ObjectId,
    IndexId,
    IndexName,
    IndexType,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,
    IsHypothetical,
    KeyColumns,
    IncludedColumns,
    FilterDefinition
)
SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.object_id,
    i.index_id,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.is_disabled,
    i.is_hypothetical,

    /* Key columns */
    STUFF
    (
        (
            SELECT
                ', ' +
                QUOTENAME(c2.name) +
                CASE
                    WHEN ic2.is_descending_key = 1
                        THEN ' DESC'
                    ELSE ' ASC'
                END
            FROM sys.index_columns AS ic2
            INNER JOIN sys.columns AS c2
                ON c2.object_id = ic2.object_id
               AND c2.column_id = ic2.column_id
            WHERE ic2.object_id = i.object_id
              AND ic2.index_id = i.index_id
              AND ic2.key_ordinal > 0
            ORDER BY ic2.key_ordinal
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'),
        1,
        2,
        ''
    ) AS KeyColumns,

    /* Included columns */
    STUFF
    (
        (
            SELECT
                ', ' + QUOTENAME(c3.name)
            FROM sys.index_columns AS ic3
            INNER JOIN sys.columns AS c3
                ON c3.object_id = ic3.object_id
               AND c3.column_id = ic3.column_id
            WHERE ic3.object_id = i.object_id
              AND ic3.index_id = i.index_id
              AND ic3.is_included_column = 1
            ORDER BY c3.name
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'),
        1,
        2,
        ''
    ) AS IncludedColumns,

    i.filter_definition

FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON t.object_id = i.object_id
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE
    i.index_id > 0
    AND i.is_hypothetical = 0
    AND t.is_ms_shipped = 0;


SELECT
    SchemaName,
    TableName,
    IndexId,
    IndexName,
    IndexType,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,
    KeyColumns,
    IncludedColumns,
    FilterDefinition
FROM #IndexCatalog
ORDER BY
    SchemaName,
    TableName,
    IndexId;


/*====================================================================
  PART 3 - INDEX KEY COLUMN DETAIL
====================================================================*/

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.index_id AS IndexId,
    ic.key_ordinal AS KeyOrdinal,
    c.name AS ColumnName,
    ic.is_descending_key AS IsDescending,
    ic.is_included_column AS IsIncluded
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON t.object_id = i.object_id
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE
    i.index_id > 0
    AND i.is_hypothetical = 0
    AND t.is_ms_shipped = 0
ORDER BY
    s.name,
    t.name,
    i.index_id,
    ic.key_ordinal;


/*====================================================================
  PART 4 - INDEX USAGE STATISTICS
====================================================================

  NOTE:
  sys.dm_db_index_usage_stats counters are runtime counters.
  They can reset after SQL Server restart.

====================================================================*/

IF OBJECT_ID('tempdb..#IndexUsage') IS NOT NULL
    DROP TABLE #IndexUsage;

CREATE TABLE #IndexUsage
(
    SchemaName       sysname,
    TableName        sysname,
    IndexName        sysname NULL,
    IndexId          int,
    UserSeeks        bigint NULL,
    UserScans        bigint NULL,
    UserLookups      bigint NULL,
    UserUpdates      bigint NULL,
    LastUserSeek     datetime NULL,
    LastUserScan     datetime NULL,
    LastUserLookup   datetime NULL,
    LastUserUpdate   datetime NULL,
    UsageStatus      varchar(50)
);

BEGIN TRY

    INSERT INTO #IndexUsage
    (
        SchemaName,
        TableName,
        IndexName,
        IndexId,
        UserSeeks,
        UserScans,
        UserLookups,
        UserUpdates,
        LastUserSeek,
        LastUserScan,
        LastUserLookup,
        LastUserUpdate,
        UsageStatus
    )
    SELECT
        s.name,
        t.name,
        i.name,
        i.index_id,

        ISNULL(us.user_seeks, 0),
        ISNULL(us.user_scans, 0),
        ISNULL(us.user_lookups, 0),
        ISNULL(us.user_updates, 0),

        us.last_user_seek,
        us.last_user_scan,
        us.last_user_lookup,
        us.last_user_update,

        CASE
            WHEN us.index_id IS NULL
                THEN 'NO_RUNTIME_STATISTICS'
            WHEN
                ISNULL(us.user_seeks,0)
              + ISNULL(us.user_scans,0)
              + ISNULL(us.user_lookups,0) = 0
                THEN 'NO_USER_READ_USAGE'
            ELSE
                'USED_BY_USER_QUERIES'
        END

    FROM sys.indexes AS i
    INNER JOIN sys.tables AS t
        ON t.object_id = i.object_id
    INNER JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    LEFT JOIN sys.dm_db_index_usage_stats AS us
        ON us.database_id = DB_ID()
       AND us.object_id = i.object_id
       AND us.index_id = i.index_id

    WHERE
        i.index_id > 0
        AND i.is_hypothetical = 0
        AND t.is_ms_shipped = 0;

END TRY
BEGIN CATCH

    INSERT INTO #IndexUsage
    (
        SchemaName,
        TableName,
        IndexName,
        IndexId,
        UsageStatus
    )
    VALUES
    (
        'SYSTEM',
        'SYSTEM',
        NULL,
        -1,
        'DMV_PERMISSION_ERROR'
    );

    PRINT 'WARNING: sys.dm_db_index_usage_stats could not be read.';
    PRINT ERROR_MESSAGE();

END CATCH;


SELECT
    *
FROM #IndexUsage
ORDER BY
    SchemaName,
    TableName,
    IndexId;


/*====================================================================
  PART 5 - SQL SERVER START TIME
====================================================================*/

BEGIN TRY

    SELECT
        sqlserver_start_time AS SqlServerStartTime,
        SYSDATETIME() AS CurrentDateTime,
        DATEDIFF
        (
            DAY,
            sqlserver_start_time,
            SYSDATETIME()
        ) AS DaysSinceEngineStart
    FROM sys.dm_os_sys_info;

END TRY
BEGIN CATCH

    SELECT
        'SQL SERVER START TIME NOT AVAILABLE' AS Status,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


/*====================================================================
  PART 6 - ACTUAL EVENT DATE/TIME COLUMN DISCOVERY
====================================================================

  IMPORTANT:
  This section does NOT assume a date-column name.

  It searches the real database metadata.

====================================================================*/

IF OBJECT_ID('tempdb..#EventDateDiscovery') IS NOT NULL
    DROP TABLE #EventDateDiscovery;

CREATE TABLE #EventDateDiscovery
(
    SchemaName        sysname,
    TableName         sysname,
    ColumnName        sysname,
    DataType          sysname,
    CandidateRole     varchar(100),
    PriorityOrder     int
);


/*--------------------------------------------------------------------
  MaintenanceRecords
--------------------------------------------------------------------*/

INSERT INTO #EventDateDiscovery
SELECT
    s.name,
    t.name,
    c.name,
    ty.name,
    'MaintenanceEventDate',
    CASE c.name
        WHEN 'MaintenanceDateTime' THEN 1
        WHEN 'MaintenanceDate' THEN 2
        WHEN 'EventDateTime' THEN 3
        WHEN 'EventDate' THEN 4
        WHEN 'CreatedDateTime' THEN 5
        ELSE 99
    END
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
WHERE
    s.name = 'event'
    AND t.name = 'MaintenanceRecords'
    AND
    (
        c.name IN
        (
            'MaintenanceDateTime',
            'MaintenanceDate',
            'EventDateTime',
            'EventDate',
            'CreatedDateTime'
        )
    )
    AND ty.name IN
    (
        'date',
        'datetime',
        'datetime2',
        'smalldatetime',
        'datetimeoffset'
    );


/*--------------------------------------------------------------------
  FailureRecords
--------------------------------------------------------------------*/

INSERT INTO #EventDateDiscovery
SELECT
    s.name,
    t.name,
    c.name,
    ty.name,
    'FailureEventDate',
    CASE c.name
        WHEN 'FailureDateTime' THEN 1
        WHEN 'FailureDate' THEN 2
        WHEN 'EventDateTime' THEN 3
        WHEN 'EventDate' THEN 4
        WHEN 'CreatedDateTime' THEN 5
        ELSE 99
    END
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
WHERE
    s.name = 'event'
    AND t.name = 'FailureRecords'
    AND
    (
        c.name IN
        (
            'FailureDateTime',
            'FailureDate',
            'EventDateTime',
            'EventDate',
            'CreatedDateTime'
        )
    )
    AND ty.name IN
    (
        'date',
        'datetime',
        'datetime2',
        'smalldatetime',
        'datetimeoffset'
    );


/*--------------------------------------------------------------------
  CalibrationRecords
--------------------------------------------------------------------*/

INSERT INTO #EventDateDiscovery
SELECT
    s.name,
    t.name,
    c.name,
    ty.name,
    'CalibrationEventDate',
    CASE c.name
        WHEN 'CalibrationDateTime' THEN 1
        WHEN 'CalibrationDate' THEN 2
        WHEN 'EventDateTime' THEN 3
        WHEN 'EventDate' THEN 4
        WHEN 'CreatedDateTime' THEN 5
        ELSE 99
    END
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
WHERE
    s.name = 'event'
    AND t.name = 'CalibrationRecords'
    AND
    (
        c.name IN
        (
            'CalibrationDateTime',
            'CalibrationDate',
            'EventDateTime',
            'EventDate',
            'CreatedDateTime'
        )
    )
    AND ty.name IN
    (
        'date',
        'datetime',
        'datetime2',
        'smalldatetime',
        'datetimeoffset'
    );


/*--------------------------------------------------------------------
  SparePartUsage
--------------------------------------------------------------------*/

INSERT INTO #EventDateDiscovery
SELECT
    s.name,
    t.name,
    c.name,
    ty.name,
    'SparePartUsageEventDate',
    CASE c.name
        WHEN 'UsageDateTime' THEN 1
        WHEN 'UsageDate' THEN 2
        WHEN 'TransactionDateTime' THEN 3
        WHEN 'TransactionDate' THEN 4
        WHEN 'CreatedDateTime' THEN 5
        ELSE 99
    END
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
WHERE
    s.name = 'event'
    AND t.name = 'SparePartUsage'
    AND
    (
        c.name IN
        (
            'UsageDateTime',
            'UsageDate',
            'TransactionDateTime',
            'TransactionDate',
            'CreatedDateTime'
        )
    )
    AND ty.name IN
    (
        'date',
        'datetime',
        'datetime2',
        'smalldatetime',
        'datetimeoffset'
    );


/*--------------------------------------------------------------------
  InventoryTransactions
--------------------------------------------------------------------*/

INSERT INTO #EventDateDiscovery
SELECT
    s.name,
    t.name,
    c.name,
    ty.name,
    'InventoryTransactionDate',
    CASE c.name
        WHEN 'TransactionDateTime' THEN 1
        WHEN 'TransactionDate' THEN 2
        WHEN 'CreatedDateTime' THEN 3
        ELSE 99
    END
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns c
    ON c.object_id = t.object_id
INNER JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
WHERE
    s.name = 'inv'
    AND t.name = 'InventoryTransactions'
    AND
    (
        c.name IN
        (
            'TransactionDateTime',
            'TransactionDate',
            'CreatedDateTime'
        )
    )
    AND ty.name IN
    (
        'date',
        'datetime',
        'datetime2',
        'smalldatetime',
        'datetimeoffset'
    );


SELECT
    SchemaName,
    TableName,
    ColumnName,
    DataType,
    CandidateRole,
    PriorityOrder
FROM #EventDateDiscovery
ORDER BY
    SchemaName,
    TableName,
    CandidateRole,
    PriorityOrder;


/*====================================================================
  PART 7 - TEMPORAL / HISTORY COLUMN VERIFICATION
====================================================================*/

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    TYPE_NAME(c.user_type_id) AS DataType,
    c.is_nullable
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
INNER JOIN sys.columns AS c
    ON c.object_id = t.object_id
WHERE
    (
        s.name = 'event'
        AND t.name IN
        (
            'InstrumentLifecycle',
            'InstrumentOperationalStatusHistory',
            'InstrumentBypassHistory'
        )
    )
    AND
    (
        c.name IN
        (
            'InstrumentId',
            'EffectiveFrom',
            'EffectiveTo',
            'BypassStartDateTime',
            'BypassEndDateTime'
        )
    )
ORDER BY
    s.name,
    t.name,
    c.column_id;


/*====================================================================
  PART 8 - DEFINE EXPECTED QUERY / WORKLOAD CANDIDATES
====================================================================

  These are NOT index creation commands.

  They represent expected application / analytics access patterns.

====================================================================*/

IF OBJECT_ID('tempdb..#WorkloadCandidates') IS NOT NULL
    DROP TABLE #WorkloadCandidates;

CREATE TABLE #WorkloadCandidates
(
    CandidateId             int IDENTITY(1,1),
    PriorityCode             varchar(20),
    WorkloadArea             varchar(100),
    SchemaName               sysname,
    TableName                sysname,
    CandidateKeyColumns      nvarchar(500),
    QueryPattern             nvarchar(1000),
    Reason                   nvarchar(1000)
);


/*--------------------------------------------------------------------
  8.1 Maintenance history
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t
        ON t.object_id = c.object_id
    INNER JOIN sys.schemas s
        ON s.schema_id = t.schema_id
    WHERE
        s.name = 'event'
        AND t.name = 'MaintenanceRecords'
        AND c.name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'MaintenanceRecords'
        AND CandidateRole = 'MaintenanceEventDate'
)
BEGIN

    DECLARE @MaintenanceDateColumn sysname;

    SELECT TOP (1)
        @MaintenanceDateColumn = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'MaintenanceRecords'
        AND CandidateRole = 'MaintenanceEventDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    (
        PriorityCode,
        WorkloadArea,
        SchemaName,
        TableName,
        CandidateKeyColumns,
        QueryPattern,
        Reason
    )
    VALUES
    (
        'HIGH',
        'Maintenance History',
        'event',
        'MaintenanceRecords',
        '[InstrumentId], [' + @MaintenanceDateColumn + ']',
        'WHERE InstrumentId = ? ORDER BY ' + @MaintenanceDateColumn,
        'Frequent instrument maintenance-history retrieval by instrument and event date.'
    );

END;


/*--------------------------------------------------------------------
  8.2 Failure history
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t
        ON t.object_id = c.object_id
    INNER JOIN sys.schemas s
        ON s.schema_id = t.schema_id
    WHERE
        s.name = 'event'
        AND t.name = 'FailureRecords'
        AND c.name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'FailureRecords'
        AND CandidateRole = 'FailureEventDate'
)
BEGIN

    DECLARE @FailureDateColumn sysname;

    SELECT TOP (1)
        @FailureDateColumn = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'FailureRecords'
        AND CandidateRole = 'FailureEventDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'HIGH',
        'Failure History',
        'event',
        'FailureRecords',
        '[InstrumentId], [' + @FailureDateColumn + ']',
        'WHERE InstrumentId = ? ORDER BY ' + @FailureDateColumn,
        'Frequent failure-history retrieval by instrument and failure date.'
    );

END;


/*--------------------------------------------------------------------
  8.3 Calibration history
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t
        ON t.object_id = c.object_id
    INNER JOIN sys.schemas s
        ON s.schema_id = t.schema_id
    WHERE
        s.name = 'event'
        AND t.name = 'CalibrationRecords'
        AND c.name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'CalibrationRecords'
        AND CandidateRole = 'CalibrationEventDate'
)
BEGIN

    DECLARE @CalibrationDateColumn sysname;

    SELECT TOP (1)
        @CalibrationDateColumn = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'CalibrationRecords'
        AND CandidateRole = 'CalibrationEventDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'HIGH',
        'Calibration History',
        'event',
        'CalibrationRecords',
        '[InstrumentId], [' + @CalibrationDateColumn + ']',
        'WHERE InstrumentId = ? ORDER BY ' + @CalibrationDateColumn,
        'Frequent calibration-history retrieval by instrument and calibration date.'
    );

END;


/*--------------------------------------------------------------------
  8.4 Instrument lifecycle
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.InstrumentLifecycle')
      AND name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.InstrumentLifecycle')
      AND name = 'EffectiveFrom'
)
BEGIN

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'HIGH',
        'Instrument Lifecycle',
        'event',
        'InstrumentLifecycle',
        '[InstrumentId], [EffectiveFrom]',
        'WHERE InstrumentId = ? ORDER BY EffectiveFrom',
        'Historical lifecycle lookup and temporal reconstruction.'
    );

END;


/*--------------------------------------------------------------------
  8.5 Instrument operational status history
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.InstrumentOperationalStatusHistory')
      AND name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.InstrumentOperationalStatusHistory')
      AND name = 'EffectiveFrom'
)
BEGIN

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'HIGH',
        'Operational Status History',
        'event',
        'InstrumentOperationalStatusHistory',
        '[InstrumentId], [EffectiveFrom]',
        'WHERE InstrumentId = ? ORDER BY EffectiveFrom',
        'Temporal operational-status analysis.'
    );

END;


/*--------------------------------------------------------------------
  8.6 Instrument bypass history
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.InstrumentBypassHistory')
      AND name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.InstrumentBypassHistory')
      AND name = 'BypassStartDateTime'
)
BEGIN

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'HIGH',
        'Instrument Bypass History',
        'event',
        'InstrumentBypassHistory',
        '[InstrumentId], [BypassStartDateTime]',
        'WHERE InstrumentId = ? ORDER BY BypassStartDateTime',
        'Bypass-duration and bypass-history analysis.'
    );

END;


/*--------------------------------------------------------------------
  8.7 Spare Part Usage by Instrument
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.SparePartUsage')
      AND name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'SparePartUsage'
        AND CandidateRole = 'SparePartUsageEventDate'
)
BEGIN

    DECLARE @SpareUsageDateColumn sysname;

    SELECT TOP (1)
        @SpareUsageDateColumn = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'SparePartUsage'
        AND CandidateRole = 'SparePartUsageEventDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Spare Usage by Instrument',
        'event',
        'SparePartUsage',
        '[InstrumentId], [' + @SpareUsageDateColumn + ']',
        'WHERE InstrumentId = ? ORDER BY ' + @SpareUsageDateColumn,
        'Spare consumption history for an instrument.'
    );

END;


/*--------------------------------------------------------------------
  8.8 Spare Part Usage by Spare Part
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('event.SparePartUsage')
      AND name = 'SparePartId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'SparePartUsage'
        AND CandidateRole = 'SparePartUsageEventDate'
)
BEGIN

    DECLARE @SpareUsageDateColumn2 sysname;

    SELECT TOP (1)
        @SpareUsageDateColumn2 = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'event'
        AND TableName = 'SparePartUsage'
        AND CandidateRole = 'SparePartUsageEventDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Spare Usage by Spare Part',
        'event',
        'SparePartUsage',
        '[SparePartId], [' + @SpareUsageDateColumn2 + ']',
        'WHERE SparePartId = ? ORDER BY ' + @SpareUsageDateColumn2,
        'Spare-part consumption history and usage analytics.'
    );

END;


/*--------------------------------------------------------------------
  8.9 Inventory transactions by Spare Part
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('inv.InventoryTransactions')
      AND name = 'SparePartId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'inv'
        AND TableName = 'InventoryTransactions'
        AND CandidateRole = 'InventoryTransactionDate'
)
BEGIN

    DECLARE @InventoryDateColumn sysname;

    SELECT TOP (1)
        @InventoryDateColumn = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'inv'
        AND TableName = 'InventoryTransactions'
        AND CandidateRole = 'InventoryTransactionDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Inventory by Spare Part',
        'inv',
        'InventoryTransactions',
        '[SparePartId], [' + @InventoryDateColumn + ']',
        'WHERE SparePartId = ? ORDER BY ' + @InventoryDateColumn,
        'Inventory transaction history by spare part.'
    );

END;


/*--------------------------------------------------------------------
  8.10 Inventory transactions by Location
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('inv.InventoryTransactions')
      AND name = 'InventoryLocationId'
)
AND EXISTS
(
    SELECT 1
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'inv'
        AND TableName = 'InventoryTransactions'
        AND CandidateRole = 'InventoryTransactionDate'
)
BEGIN

    DECLARE @InventoryDateColumn2 sysname;

    SELECT TOP (1)
        @InventoryDateColumn2 = ColumnName
    FROM #EventDateDiscovery
    WHERE
        SchemaName = 'inv'
        AND TableName = 'InventoryTransactions'
        AND CandidateRole = 'InventoryTransactionDate'
    ORDER BY PriorityOrder;

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Inventory by Location',
        'inv',
        'InventoryTransactions',
        '[InventoryLocationId], [' + @InventoryDateColumn2 + ']',
        'WHERE InventoryLocationId = ? ORDER BY ' + @InventoryDateColumn2,
        'Inventory movement analysis by warehouse/location.'
    );

END;


/*--------------------------------------------------------------------
  8.11 Trip instruments by Instrument
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('rel.TripInstruments')
      AND name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('rel.TripInstruments')
      AND name = 'TripId'
)
BEGIN

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Trip Lookup by Instrument',
        'rel',
        'TripInstruments',
        '[InstrumentId], [TripId]',
        'WHERE InstrumentId = ?',
        'Instrument-centric lookup of trips/interlocks. Existing PK begins with TripId, not InstrumentId.'
    );

END;


/*--------------------------------------------------------------------
  8.12 SparePartInstruments by Instrument
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('rel.SparePartInstruments')
      AND name = 'InstrumentId'
)
AND EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('rel.SparePartInstruments')
      AND name = 'SparePartId'
)
BEGIN

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Spare Part Compatibility by Instrument',
        'rel',
        'SparePartInstruments',
        '[InstrumentId], [SparePartId]',
        'WHERE InstrumentId = ?',
        'Instrument-centric compatible-spare-part lookup.'
    );

END;


/*--------------------------------------------------------------------
  8.13 SparePartInstrumentTypes by InstrumentType
--------------------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('rel.SparePartInstrumentTypes')
      AND name = 'InstrumentTypeId'
)
AND EXISTS
(
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('rel.SparePartInstrumentTypes')
      AND name = 'SparePartId'
)
BEGIN

    INSERT INTO #WorkloadCandidates
    VALUES
    (
        'MEDIUM',
        'Spare Part Compatibility by Instrument Type',
        'rel',
        'SparePartInstrumentTypes',
        '[InstrumentTypeId], [SparePartId]',
        'WHERE InstrumentTypeId = ?',
        'Instrument-type-centric compatible-spare-part lookup.'
    );

END;


/*--------------------------------------------------------------------
  SHOW WORKLOAD CANDIDATES
--------------------------------------------------------------------*/

SELECT
    CandidateId,
    PriorityCode,
    WorkloadArea,
    SchemaName,
    TableName,
    CandidateKeyColumns,
    QueryPattern,
    Reason
FROM #WorkloadCandidates
ORDER BY
    CASE PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
        ELSE 4
    END,
    CandidateId;


/*====================================================================
  PART 9 - NORMALIZED CANDIDATE COLUMN TABLE
====================================================================*/

IF OBJECT_ID('tempdb..#CandidateColumns') IS NOT NULL
    DROP TABLE #CandidateColumns;

CREATE TABLE #CandidateColumns
(
    CandidateId int,
    ColumnOrdinal int,
    ColumnName sysname
);


/*--------------------------------------------------------------------
  Insert candidate columns explicitly from metadata-independent
  workload definitions.
--------------------------------------------------------------------*/

INSERT INTO #CandidateColumns
SELECT
    wc.CandidateId,
    1,
    REPLACE
    (
        LTRIM(RTRIM
        (
            LEFT
            (
                wc.CandidateKeyColumns,
                CHARINDEX
                (
                    ',',
                    wc.CandidateKeyColumns + ','
                ) - 1
            )
        )),
        '[', ''
    )
FROM #WorkloadCandidates wc;


INSERT INTO #CandidateColumns
SELECT
    wc.CandidateId,
    2,
    REPLACE
    (
        REPLACE
        (
            LTRIM
            (
                RTRIM
                (
                    SUBSTRING
                    (
                        wc.CandidateKeyColumns,
                        CHARINDEX(',', wc.CandidateKeyColumns) + 1,
                        LEN(wc.CandidateKeyColumns)
                    )
                )
            ),
            '[', ''
        ),
        ']', ''
    )
FROM #WorkloadCandidates wc
WHERE CHARINDEX(',', wc.CandidateKeyColumns) > 0;


/* Clean first-column closing bracket */
UPDATE #CandidateColumns
SET ColumnName =
    REPLACE(ColumnName, ']', '');


SELECT
    CandidateId,
    ColumnOrdinal,
    ColumnName
FROM #CandidateColumns
ORDER BY
    CandidateId,
    ColumnOrdinal;


/*====================================================================
  PART 10 - EXISTING INDEX KEY NORMALIZATION
====================================================================*/

IF OBJECT_ID('tempdb..#ExistingIndexKeys') IS NOT NULL
    DROP TABLE #ExistingIndexKeys;

CREATE TABLE #ExistingIndexKeys
(
    SchemaName sysname,
    TableName sysname,
    ObjectId int,
    IndexId int,
    IndexName sysname NULL,
    KeyOrdinal int,
    ColumnName sysname
);

INSERT INTO #ExistingIndexKeys
SELECT
    s.name,
    t.name,
    i.object_id,
    i.index_id,
    i.name,
    ic.key_ordinal,
    c.name
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON t.object_id = i.object_id
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE
    i.index_id > 0
    AND i.is_hypothetical = 0
    AND i.is_disabled = 0
    AND ic.key_ordinal > 0
    AND t.is_ms_shipped = 0;


/*====================================================================
  PART 11 - WORKLOAD CANDIDATE vs EXISTING INDEX AUDIT
====================================================================*/

IF OBJECT_ID('tempdb..#CandidateIndexAudit') IS NOT NULL
    DROP TABLE #CandidateIndexAudit;

CREATE TABLE #CandidateIndexAudit
(
    CandidateId int,
    ExistingIndexId int,
    ExistingIndexName sysname NULL,
    ExistingKeyColumns nvarchar(max) NULL,
    CandidateColumnCount int,
    MatchingColumnCount int,
    FirstColumnMatches bit,
    FullCandidatePrefixSupported bit,
    ExistingIndexUsageStatus varchar(50) NULL,
    UserSeeks bigint NULL,
    UserScans bigint NULL,
    UserLookups bigint NULL,
    UserUpdates bigint NULL
);


/*--------------------------------------------------------------------
  Generate comparison rows
--------------------------------------------------------------------*/

INSERT INTO #CandidateIndexAudit
(
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    ExistingKeyColumns,
    CandidateColumnCount,
    MatchingColumnCount,
    FirstColumnMatches,
    FullCandidatePrefixSupported,
    ExistingIndexUsageStatus,
    UserSeeks,
    UserScans,
    UserLookups,
    UserUpdates
)
SELECT
    wc.CandidateId,
    ei.IndexId,
    ei.IndexName,

    ei.KeyColumns,

    (
        SELECT COUNT(*)
        FROM #CandidateColumns cc
        WHERE cc.CandidateId = wc.CandidateId
    ) AS CandidateColumnCount,

    (
        SELECT COUNT(*)
        FROM #CandidateColumns cc
        INNER JOIN #ExistingIndexKeys eik
            ON eik.ObjectId = OBJECT_ID
            (
                QUOTENAME(wc.SchemaName)
                + '.'
                + QUOTENAME(wc.TableName)
            )
           AND eik.IndexId = ei.IndexId
           AND eik.KeyOrdinal = cc.ColumnOrdinal
           AND eik.ColumnName = cc.ColumnName
        WHERE cc.CandidateId = wc.CandidateId
    ) AS MatchingColumnCount,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #CandidateColumns cc
            INNER JOIN #ExistingIndexKeys eik
                ON eik.ObjectId = OBJECT_ID
                (
                    QUOTENAME(wc.SchemaName)
                    + '.'
                    + QUOTENAME(wc.TableName)
                )
               AND eik.IndexId = ei.IndexId
               AND eik.KeyOrdinal = 1
               AND eik.ColumnName = cc.ColumnName
            WHERE
                cc.CandidateId = wc.CandidateId
                AND cc.ColumnOrdinal = 1
        )
        THEN 1
        ELSE 0
    END AS FirstColumnMatches,

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM #CandidateColumns cc
            INNER JOIN #ExistingIndexKeys eik
                ON eik.ObjectId = OBJECT_ID
                (
                    QUOTENAME(wc.SchemaName)
                    + '.'
                    + QUOTENAME(wc.TableName)
                )
               AND eik.IndexId = ei.IndexId
               AND eik.KeyOrdinal = cc.ColumnOrdinal
               AND eik.ColumnName = cc.ColumnName
            WHERE cc.CandidateId = wc.CandidateId
        )
        =
        (
            SELECT COUNT(*)
            FROM #CandidateColumns cc
            WHERE cc.CandidateId = wc.CandidateId
        )
        THEN 1
        ELSE 0
    END AS FullCandidatePrefixSupported,

    iu.UsageStatus,
    iu.UserSeeks,
    iu.UserScans,
    iu.UserLookups,
    iu.UserUpdates

FROM #WorkloadCandidates wc
INNER JOIN #IndexCatalog ei
    ON ei.SchemaName = wc.SchemaName
   AND ei.TableName = wc.TableName
   AND ei.IsDisabled = 0
   AND ei.IsHypothetical = 0
LEFT JOIN #IndexUsage iu
    ON iu.SchemaName = ei.SchemaName
   AND iu.TableName = ei.TableName
   AND iu.IndexId = ei.IndexId;


/*====================================================================
  PART 12 - FINAL WORKLOAD SUPPORT STATUS
====================================================================*/

IF OBJECT_ID('tempdb..#WorkloadSupport') IS NOT NULL
    DROP TABLE #WorkloadSupport;

CREATE TABLE #WorkloadSupport
(
    CandidateId int,
    WorkloadArea varchar(100),
    SchemaName sysname,
    TableName sysname,
    CandidateKeyColumns nvarchar(500),
    Status varchar(50),
    SupportingIndexName sysname NULL,
    SupportingIndexKeyColumns nvarchar(max) NULL,
    SupportingIndexUsage varchar(50) NULL,
    UserSeeks bigint NULL,
    UserScans bigint NULL,
    UserLookups bigint NULL,
    UserUpdates bigint NULL,
    Reason nvarchar(1000)
);


/*--------------------------------------------------------------------
  One row per workload candidate.

  Important:
  FULL_SUPPORT means candidate key columns are the LEFT-MOST
  key columns of an existing index.

  Merely having those columns somewhere inside an index does NOT
  count as full support.
--------------------------------------------------------------------*/

INSERT INTO #WorkloadSupport
SELECT
    wc.CandidateId,
    wc.WorkloadArea,
    wc.SchemaName,
    wc.TableName,
    wc.CandidateKeyColumns,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #CandidateIndexAudit ca
            WHERE
                ca.CandidateId = wc.CandidateId
                AND ca.FullCandidatePrefixSupported = 1
        )
        THEN 'SUPPORTED'

        WHEN EXISTS
        (
            SELECT 1
            FROM #CandidateIndexAudit ca
            WHERE
                ca.CandidateId = wc.CandidateId
                AND ca.FirstColumnMatches = 1
        )
        THEN 'PARTIAL_PREFIX_SUPPORT'

        ELSE 'NOT_SUPPORTED'
    END AS Status,

    sup.ExistingIndexName,
    sup.ExistingKeyColumns,
    sup.ExistingIndexUsageStatus,
    sup.UserSeeks,
    sup.UserScans,
    sup.UserLookups,
    sup.UserUpdates,

    wc.Reason

FROM #WorkloadCandidates wc

OUTER APPLY
(
    SELECT TOP (1)
        ca.ExistingIndexName,
        ca.ExistingKeyColumns,
        ca.ExistingIndexUsageStatus,
        ca.UserSeeks,
        ca.UserScans,
        ca.UserLookups,
        ca.UserUpdates
    FROM #CandidateIndexAudit ca
    WHERE
        ca.CandidateId = wc.CandidateId
        AND ca.FullCandidatePrefixSupported = 1
    ORDER BY
        ISNULL(ca.UserSeeks,0)
      + ISNULL(ca.UserScans,0)
      + ISNULL(ca.UserLookups,0) DESC
) sup;


/*====================================================================
  PART 13 - WORKLOAD SUPPORT RESULT
====================================================================*/

SELECT
    ws.CandidateId,
    wc.PriorityCode,
    ws.WorkloadArea,
    ws.SchemaName,
    ws.TableName,
    ws.CandidateKeyColumns,
    ws.Status,
    ws.SupportingIndexName,
    ws.SupportingIndexKeyColumns,
    ws.SupportingIndexUsage,
    ws.UserSeeks,
    ws.UserScans,
    ws.UserLookups,
    ws.UserUpdates,
    ws.Reason
FROM #WorkloadSupport AS ws
INNER JOIN #WorkloadCandidates AS wc
    ON wc.CandidateId = ws.CandidateId
ORDER BY
    CASE wc.PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
        ELSE 4
    END,
    ws.CandidateId;

/*====================================================================
  PART 14 - ONLY UNSUPPORTED / PARTIALLY SUPPORTED WORKLOADS
====================================================================*/

SELECT
    wc.CandidateId,
    wc.PriorityCode,
    wc.WorkloadArea,
    wc.SchemaName,
    wc.TableName,
    wc.CandidateKeyColumns,
    ws.Status,
    wc.QueryPattern,
    wc.Reason
FROM #WorkloadSupport ws
INNER JOIN #WorkloadCandidates wc
    ON wc.CandidateId = ws.CandidateId
WHERE
    ws.Status <> 'SUPPORTED'
ORDER BY
    CASE wc.PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
        ELSE 4
    END,
    wc.CandidateId;


/*====================================================================
  PART 15 - INDEXES WITH LOW / NO USER READ ACTIVITY
====================================================================

  IMPORTANT:
  These are NOT automatic DROP recommendations.

====================================================================*/

SELECT
    iu.SchemaName,
    iu.TableName,
    iu.IndexName,
    ic.KeyColumns,
    ic.IncludedColumns,
    iu.UserSeeks,
    iu.UserScans,
    iu.UserLookups,
    iu.UserUpdates,
    iu.UsageStatus,
    CASE
        WHEN
            ISNULL(iu.UserSeeks,0)
          + ISNULL(iu.UserScans,0)
          + ISNULL(iu.UserLookups,0) = 0
        AND ISNULL(iu.UserUpdates,0) > 0
            THEN 'REVIEW_READ_VS_WRITE_COST'

        WHEN
            ISNULL(iu.UserSeeks,0)
          + ISNULL(iu.UserScans,0)
          + ISNULL(iu.UserLookups,0) = 0
            THEN 'NO_OBSERVED_USER_READS'

        ELSE
            'USER_READ_ACTIVITY_PRESENT'
    END AS ReviewStatus
FROM #IndexUsage iu
LEFT JOIN #IndexCatalog ic
    ON ic.SchemaName = iu.SchemaName
   AND ic.TableName = iu.TableName
   AND ic.IndexId = iu.IndexId
WHERE
    iu.IndexId > 0
    AND
    (
        ISNULL(iu.UserSeeks,0)
      + ISNULL(iu.UserScans,0)
      + ISNULL(iu.UserLookups,0) = 0
    )
ORDER BY
    ISNULL(iu.UserUpdates,0) DESC;


/*====================================================================
  PART 16 - HIGH-WRITE / LOW-READ INDEX REVIEW
====================================================================*/

SELECT
    iu.SchemaName,
    iu.TableName,
    iu.IndexName,
    ic.KeyColumns,
    ic.IncludedColumns,
    iu.UserSeeks,
    iu.UserScans,
    iu.UserLookups,
    iu.UserUpdates,
    CASE
        WHEN iu.UserUpdates >= 100
         AND
        (
            ISNULL(iu.UserSeeks,0)
          + ISNULL(iu.UserScans,0)
          + ISNULL(iu.UserLookups,0)
        ) = 0
            THEN 'HIGH_WRITE_LOW_READ_REVIEW'
        ELSE
            'NO_SPECIAL_FLAG'
    END AS ReviewStatus
FROM #IndexUsage iu
LEFT JOIN #IndexCatalog ic
    ON ic.SchemaName = iu.SchemaName
   AND ic.TableName = iu.TableName
   AND ic.IndexId = iu.IndexId
WHERE iu.IndexId > 0
ORDER BY
    CASE
        WHEN iu.UserUpdates >= 100
         AND
        (
            ISNULL(iu.UserSeeks,0)
          + ISNULL(iu.UserScans,0)
          + ISNULL(iu.UserLookups,0)
        ) = 0
            THEN 1
        ELSE 2
    END,
    iu.UserUpdates DESC;


/*====================================================================
  PART 17 - WORKLOAD CANDIDATES THAT ALSO INVOLVE FK COLUMNS
====================================================================

  This is a CROSS-PHASE REVIEW.

  The purpose is to distinguish:
      10.6 FK-supporting requirement
  from
      10.7 workload/performance requirement.

====================================================================*/

SELECT
    wc.CandidateId,
    wc.WorkloadArea,
    wc.SchemaName,
    wc.TableName,
    wc.CandidateKeyColumns,
    fk.name AS ForeignKeyName,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS FKParentSchema,
    OBJECT_NAME(fk.parent_object_id) AS FKParentTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id)
        AS FKParentColumn,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id)
        AS FKReferencedSchema,
    OBJECT_NAME(fk.referenced_object_id)
        AS FKReferencedTable
FROM #WorkloadCandidates wc
INNER JOIN sys.foreign_keys fk
    ON fk.parent_object_id =
       OBJECT_ID
       (
           QUOTENAME(wc.SchemaName)
           + '.'
           + QUOTENAME(wc.TableName)
       )
INNER JOIN sys.foreign_key_columns fkc
    ON fkc.constraint_object_id = fk.object_id
ORDER BY
    wc.CandidateId,
    fk.name,
    fkc.constraint_column_id;


/*====================================================================
  PART 18 - EXISTING INDEX OVERLAP / REDUNDANCY REVIEW
====================================================================

  Finds cases where an existing index has the same leading key
  columns as another index on the same table.

  This does NOT mean either index should be dropped.

====================================================================*/

SELECT
    A.SchemaName,
    A.TableName,

    A.IndexName AS IndexA,
    A.KeyColumns AS IndexAKeys,

    B.IndexName AS IndexB,
    B.KeyColumns AS IndexBKeys,

    'POSSIBLE_INDEX_OVERLAP' AS ReviewStatus

FROM #IndexCatalog A
INNER JOIN #IndexCatalog B
    ON A.SchemaName = B.SchemaName
   AND A.TableName = B.TableName
   AND A.IndexId < B.IndexId

WHERE
    A.IsDisabled = 0
    AND B.IsDisabled = 0
    AND
    (
        A.KeyColumns = B.KeyColumns
        OR
        B.KeyColumns LIKE A.KeyColumns + ',%'
        OR
        A.KeyColumns LIKE B.KeyColumns + ',%'
    )

ORDER BY
    A.SchemaName,
    A.TableName,
    A.IndexName,
    B.IndexName;


/*====================================================================
  PART 19 - QUERY STORE AVAILABILITY
====================================================================*/

BEGIN TRY

    IF OBJECT_ID('sys.database_query_store_options') IS NOT NULL
    BEGIN

        SELECT
            actual_state_desc,
            desired_state_desc,
            readonly_reason,
            current_storage_size_mb,
            max_storage_size_mb,
            interval_length_minutes,
            stale_query_threshold_days,
            query_capture_mode_desc
        FROM sys.database_query_store_options;

    END
    ELSE
    BEGIN

        SELECT
            'QUERY_STORE_METADATA_NOT_AVAILABLE' AS Status;
    END;

END TRY
BEGIN CATCH

    SELECT
        'QUERY_STORE_CHECK_FAILED' AS Status,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


/*====================================================================
  PART 20 - OPTIONAL QUERY STORE WORKLOAD EVIDENCE
====================================================================

  This section runs only when Query Store is available and readable.

====================================================================*/

BEGIN TRY

    IF EXISTS
    (
        SELECT 1
        FROM sys.database_query_store_options
        WHERE actual_state_desc = 'READ_WRITE'
    )
    BEGIN

        SELECT TOP (50)

            OBJECT_SCHEMA_NAME(q.object_id) AS SchemaName,
            OBJECT_NAME(q.object_id) AS ObjectName,

            SUM(rs.count_executions) AS TotalExecutions,

            CAST
            (
                SUM
                (
                    rs.avg_duration
                    * rs.count_executions
                )
                / NULLIF(SUM(rs.count_executions),0)
                AS decimal(20,2)
            ) AS WeightedAvgDurationMicroseconds,

            CAST
            (
                SUM
                (
                    rs.avg_cpu_time
                    * rs.count_executions
                )
                / NULLIF(SUM(rs.count_executions),0)
                AS decimal(20,2)
            ) AS WeightedAvgCPUTimeMicroseconds,

            MAX(rs.last_execution_time) AS LastExecutionTime

        FROM sys.query_store_query AS q
        INNER JOIN sys.query_store_query_text AS qt
            ON qt.query_text_id = q.query_text_id
        INNER JOIN sys.query_store_plan AS p
            ON p.query_id = q.query_id
        INNER JOIN sys.query_store_runtime_stats AS rs
            ON rs.plan_id = p.plan_id

        WHERE
            q.object_id IS NOT NULL

        GROUP BY
            q.object_id

        ORDER BY
            SUM(rs.count_executions) DESC;

    END
    ELSE
    BEGIN

        SELECT
            'QUERY_STORE_NOT_READ_WRITE' AS Status;

    END;

END TRY
BEGIN CATCH

    SELECT
        'QUERY_STORE_RUNTIME_ANALYSIS_FAILED' AS Status,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


/*====================================================================
  PART 21 - FINAL WORKLOAD SUMMARY
====================================================================*/

SELECT
    COUNT(*) AS TotalWorkloadCandidates,

    SUM
    (
        CASE
            WHEN Status = 'SUPPORTED'
                THEN 1
            ELSE 0
        END
    ) AS SupportedWorkloads,

    SUM
    (
        CASE
            WHEN Status = 'PARTIAL_PREFIX_SUPPORT'
                THEN 1
            ELSE 0
        END
    ) AS PartiallySupportedWorkloads,

    SUM
    (
        CASE
            WHEN Status = 'NOT_SUPPORTED'
                THEN 1
            ELSE 0
        END
    ) AS UnsupportedWorkloads

FROM #WorkloadSupport;


/*====================================================================
  PART 22 - HIGH PRIORITY UNSUPPORTED WORKLOADS
====================================================================*/

SELECT
    wc.CandidateId,
    wc.PriorityCode,
    wc.WorkloadArea,
    wc.SchemaName,
    wc.TableName,
    wc.CandidateKeyColumns,
    ws.Status,
    wc.QueryPattern,
    wc.Reason
FROM #WorkloadCandidates wc
INNER JOIN #WorkloadSupport ws
    ON ws.CandidateId = wc.CandidateId
WHERE
    wc.PriorityCode = 'HIGH'
    AND ws.Status <> 'SUPPORTED'
ORDER BY
    wc.CandidateId;


/*====================================================================
  PART 23 - FINAL INDEX / WORKLOAD AUDIT SUMMARY
====================================================================*/

SELECT
    'PHASE 10.7-A' AS Phase,
    'QUERY / PERFORMANCE INDEX AUDIT' AS AuditName,
    DB_NAME() AS DatabaseName,

    (
        SELECT COUNT(*)
        FROM #IndexCatalog
    ) AS TotalExistingIndexes,

    (
        SELECT COUNT(*)
        FROM #WorkloadCandidates
    ) AS TotalWorkloadCandidates,

    (
        SELECT COUNT(*)
        FROM #WorkloadSupport
        WHERE Status = 'SUPPORTED'
    ) AS SupportedWorkloads,

    (
        SELECT COUNT(*)
        FROM #WorkloadSupport
        WHERE Status = 'PARTIAL_PREFIX_SUPPORT'
    ) AS PartialWorkloads,

    (
        SELECT COUNT(*)
        FROM #WorkloadSupport
        WHERE Status = 'NOT_SUPPORTED'
    ) AS UnsupportedWorkloads,

    SYSDATETIME() AS AuditEndDateTime;


/*====================================================================
  END
====================================================================*/

PRINT '==============================================================';
PRINT 'PHASE 10.7-A COMPLETED';
PRINT 'No permanent database object was created or modified.';
PRINT '==============================================================';