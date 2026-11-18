USE [ComprehensiveInstrumentationDB_New];
GO

SET NOCOUNT ON;
GO

/* ================================================================
   PHASE 10.7-B
   FINAL INDEX CREATION PREFLIGHT

   PURPOSE:
   - Validate proposed performance indexes
   - Detect existing indexes
   - Detect exact key matches
   - Detect left-prefix support
   - Identify candidates requiring review
   - NO CREATE INDEX
   - NO ALTER INDEX
   - NO DROP INDEX
   ================================================================ */


/* ================================================================
   PART 1 — CANDIDATE INDEX DEFINITIONS
   ================================================================ */

IF OBJECT_ID('tempdb..#CandidateIndexes') IS NOT NULL
    DROP TABLE #CandidateIndexes;
GO

CREATE TABLE #CandidateIndexes
(
    CandidateId INT IDENTITY(1,1) NOT NULL,

    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,

    ProposedIndexName SYSNAME NOT NULL,

    KeyColumns NVARCHAR(1000) NOT NULL,

    IncludeColumns NVARCHAR(1000) NULL,
    FilterDefinition NVARCHAR(1000) NULL,

    PriorityCode VARCHAR(20) NOT NULL,
    SourceCode VARCHAR(50) NOT NULL,

    Reason NVARCHAR(1000) NOT NULL
);
GO


/* ---------------------------------------------------------------
   HIGH PRIORITY PERFORMANCE CANDIDATES
   --------------------------------------------------------------- */

INSERT INTO #CandidateIndexes
(
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    IncludeColumns,
    FilterDefinition,
    PriorityCode,
    SourceCode,
    Reason
)
VALUES
(
    'event',
    'MaintenanceRecords',
    'IX_MaintenanceRecords_InstrumentId_MaintenanceDate',
    'InstrumentId,MaintenanceDate',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument maintenance history lookup by InstrumentId ordered by MaintenanceDate'
),
(
    'event',
    'FailureRecords',
    'IX_FailureRecords_InstrumentId_FailureDate',
    'InstrumentId,FailureDate',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument failure history lookup by InstrumentId ordered by FailureDate'
),
(
    'event',
    'CalibrationRecords',
    'IX_CalibrationRecords_InstrumentId_CalibrationDate',
    'InstrumentId,CalibrationDate',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument calibration history lookup by InstrumentId ordered by CalibrationDate'
),
(
    'event',
    'InstrumentLifecycle',
    'IX_InstrumentLifecycle_InstrumentId_EffectiveFrom',
    'InstrumentId,EffectiveFrom',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Instrument lifecycle history lookup by InstrumentId ordered by EffectiveFrom'
),
(
    'event',
    'InstrumentOperationalStatusHistory',
    'IX_InstrumentOperationalStatusHistory_InstrumentId_EffectiveFrom',
    'InstrumentId,EffectiveFrom',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Operational status history lookup by InstrumentId ordered by EffectiveFrom'
),
(
    'event',
    'InstrumentBypassHistory',
    'IX_InstrumentBypassHistory_InstrumentId_BypassStartDateTime',
    'InstrumentId,BypassStartDateTime',
    NULL,
    NULL,
    'HIGH',
    '10.7-A',
    'Bypass history lookup by InstrumentId ordered by BypassStartDateTime'
);
GO


/* ---------------------------------------------------------------
   MEDIUM PRIORITY PERFORMANCE CANDIDATES
   --------------------------------------------------------------- */

INSERT INTO #CandidateIndexes
(
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    IncludeColumns,
    FilterDefinition,
    PriorityCode,
    SourceCode,
    Reason
)
VALUES
(
    'event',
    'SparePartUsage',
    'IX_SparePartUsage_InstrumentId_UsageDateTime',
    'InstrumentId,UsageDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part usage history lookup by InstrumentId ordered by UsageDateTime'
),
(
    'event',
    'SparePartUsage',
    'IX_SparePartUsage_SparePartId_UsageDateTime',
    'SparePartId,UsageDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part usage history lookup by SparePartId ordered by UsageDateTime'
),
(
    'inv',
    'InventoryTransactions',
    'IX_InventoryTransactions_SparePartId_TransactionDateTime',
    'SparePartId,TransactionDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Inventory transaction history lookup by SparePartId ordered by TransactionDateTime'
),
(
    'inv',
    'InventoryTransactions',
    'IX_InventoryTransactions_InventoryLocationId_TransactionDateTime',
    'InventoryLocationId,TransactionDateTime',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Inventory transaction history lookup by InventoryLocationId ordered by TransactionDateTime'
),
(
    'rel',
    'TripInstruments',
    'IX_TripInstruments_InstrumentId_TripId',
    'InstrumentId,TripId',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Trip lookup by InstrumentId with TripId access'
),
(
    'rel',
    'SparePartInstruments',
    'IX_SparePartInstruments_InstrumentId_SparePartId',
    'InstrumentId,SparePartId',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part compatibility lookup by InstrumentId'
),
(
    'rel',
    'SparePartInstrumentTypes',
    'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId',
    'InstrumentTypeId,SparePartId',
    NULL,
    NULL,
    'MEDIUM',
    '10.7-A',
    'Spare part compatibility lookup by InstrumentTypeId'
);
GO


/* ================================================================
   PART 2 — CANDIDATE INVENTORY
   ================================================================ */

SELECT
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    IncludeColumns,
    FilterDefinition,
    PriorityCode,
    SourceCode,
    Reason
FROM #CandidateIndexes
ORDER BY
    CASE PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END,
    CandidateId;
GO


/* ================================================================
   PART 3 — RESOLVE TABLE OBJECTS
   ================================================================ */

IF OBJECT_ID('tempdb..#ResolvedCandidates') IS NOT NULL
    DROP TABLE #ResolvedCandidates;
GO

CREATE TABLE #ResolvedCandidates
(
    CandidateId INT NOT NULL,

    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,

    ObjectId INT NULL,

    TableExists BIT NOT NULL,

    KeyColumns NVARCHAR(1000) NOT NULL,

    PriorityCode VARCHAR(20) NOT NULL,

    Reason NVARCHAR(1000) NOT NULL
);
GO

INSERT INTO #ResolvedCandidates
(
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    ObjectId,
    TableExists,
    KeyColumns,
    PriorityCode,
    Reason
)
SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,

    o.object_id,

    CASE
        WHEN o.object_id IS NULL THEN 0
        ELSE 1
    END,

    c.KeyColumns,
    c.PriorityCode,
    c.Reason

FROM #CandidateIndexes c

LEFT JOIN sys.objects o
    ON o.schema_id = SCHEMA_ID(c.SchemaName)
    AND o.name = c.TableName
    AND o.type = 'U';
GO


/* ================================================================
   PART 4 — TABLE EXISTENCE CHECK
   ================================================================ */

SELECT
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    TableExists,

    CASE
        WHEN TableExists = 1
            THEN 'TABLE_EXISTS'
        ELSE 'ERROR_TABLE_NOT_FOUND'
    END AS Status

FROM #ResolvedCandidates

ORDER BY CandidateId;
GO


/* ================================================================
   PART 5 — EXISTING INDEX INVENTORY
   ================================================================ */

IF OBJECT_ID('tempdb..#ExistingIndexes') IS NOT NULL
    DROP TABLE #ExistingIndexes;
GO

CREATE TABLE #ExistingIndexes
(
    ObjectId INT NOT NULL,
    IndexId INT NOT NULL,

    IndexName SYSNAME NOT NULL,

    IsUnique BIT NOT NULL,
    IsPrimaryKey BIT NOT NULL,
    IsUniqueConstraint BIT NOT NULL,
    IsDisabled BIT NOT NULL,

    TypeDescription NVARCHAR(60) NOT NULL,

    KeyColumns NVARCHAR(4000) NULL,
    IncludedColumns NVARCHAR(4000) NULL,

    FilterDefinition NVARCHAR(4000) NULL
);
GO


INSERT INTO #ExistingIndexes
(
    ObjectId,
    IndexId,
    IndexName,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,
    TypeDescription,
    KeyColumns,
    IncludedColumns,
    FilterDefinition
)
SELECT
    i.object_id,
    i.index_id,
    i.name,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.is_disabled,
    i.type_desc,

    STUFF
    (
        (
            SELECT
                ',' + QUOTENAME(c.name)

            FROM sys.index_columns ic

            INNER JOIN sys.columns c
                ON c.object_id = ic.object_id
                AND c.column_id = ic.column_id

            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.key_ordinal > 0

            ORDER BY ic.key_ordinal

            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(4000)'),

        1,
        1,
        ''
    ) AS KeyColumns,

    STUFF
    (
        (
            SELECT
                ',' + QUOTENAME(c.name)

            FROM sys.index_columns ic

            INNER JOIN sys.columns c
                ON c.object_id = ic.object_id
                AND c.column_id = ic.column_id

            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.is_included_column = 1

            ORDER BY c.column_id

            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(4000)'),

        1,
        1,
        ''
    ) AS IncludedColumns,

    i.filter_definition

FROM sys.indexes i

WHERE i.object_id IN
(
    SELECT ObjectId
    FROM #ResolvedCandidates
    WHERE TableExists = 1
);
GO


/* ================================================================
   PART 6 — EXISTING INDEXES ON CANDIDATE TABLES
   ================================================================ */

SELECT
    r.CandidateId,
    r.SchemaName,
    r.TableName,
    r.ProposedIndexName,

    e.IndexName AS ExistingIndexName,
    e.TypeDescription,
    e.IsUnique,
    e.IsPrimaryKey,
    e.IsUniqueConstraint,
    e.IsDisabled,

    e.KeyColumns,
    e.IncludedColumns,
    e.FilterDefinition

FROM #ResolvedCandidates r

LEFT JOIN #ExistingIndexes e
    ON e.ObjectId = r.ObjectId

WHERE r.TableExists = 1

ORDER BY
    r.CandidateId,
    e.IndexId;
GO


/* ================================================================
   PART 7 — EXACT INDEX NAME CHECK
   ================================================================ */

SELECT
    r.CandidateId,
    r.SchemaName,
    r.TableName,
    r.ProposedIndexName,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #ExistingIndexes e
            WHERE e.ObjectId = r.ObjectId
              AND e.IndexName = r.ProposedIndexName
        )
        THEN 1
        ELSE 0
    END AS ExactIndexNameExists,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #ExistingIndexes e
            WHERE e.ObjectId = r.ObjectId
              AND e.IndexName = r.ProposedIndexName
        )
        THEN 'REVIEW_EXISTING_NAME'
        ELSE 'NO_NAME_CONFLICT'
    END AS Decision

FROM #ResolvedCandidates r

WHERE r.TableExists = 1

ORDER BY r.CandidateId;
GO


/* ================================================================
   PART 8 — NORMALIZE PROPOSED KEY COLUMNS

   IMPORTANT:
   - No STRING_SPLIT(...,1)
   - No [key]
   - Compatibility-level independent for current 2-column
     candidate definitions.
   ================================================================ */

IF OBJECT_ID('tempdb..#CandidateKeyColumns') IS NOT NULL
    DROP TABLE #CandidateKeyColumns;
GO

CREATE TABLE #CandidateKeyColumns
(
    CandidateId INT NOT NULL,
    KeyOrdinal INT NOT NULL,
    ColumnName SYSNAME NOT NULL,

    CONSTRAINT PK_CandidateKeyColumns
        PRIMARY KEY
        (
            CandidateId,
            KeyOrdinal
        )
);
GO


/* First key column */

INSERT INTO #CandidateKeyColumns
(
    CandidateId,
    KeyOrdinal,
    ColumnName
)
SELECT
    CandidateId,
    1,
    LTRIM(RTRIM
    (
        LEFT
        (
            KeyColumns,
            CHARINDEX(',', KeyColumns + ',') - 1
        )
    ))

FROM #CandidateIndexes;
GO


/* Second key column */

INSERT INTO #CandidateKeyColumns
(
    CandidateId,
    KeyOrdinal,
    ColumnName
)
SELECT
    CandidateId,
    2,
    LTRIM(RTRIM
    (
        SUBSTRING
        (
            KeyColumns,
            CHARINDEX(',', KeyColumns) + 1,
            LEN(KeyColumns)
        )
    ))

FROM #CandidateIndexes

WHERE CHARINDEX(',', KeyColumns) > 0;
GO


SELECT
    CandidateId,
    KeyOrdinal,
    ColumnName

FROM #CandidateKeyColumns

ORDER BY
    CandidateId,
    KeyOrdinal;
GO


/* ================================================================
   PART 9 — EXISTING INDEX KEY COLUMNS
   ================================================================ */

IF OBJECT_ID('tempdb..#ExistingKeyColumns') IS NOT NULL
    DROP TABLE #ExistingKeyColumns;
GO

CREATE TABLE #ExistingKeyColumns
(
    ObjectId INT NOT NULL,
    IndexId INT NOT NULL,

    KeyOrdinal INT NOT NULL,
    ColumnName SYSNAME NOT NULL
);
GO

INSERT INTO #ExistingKeyColumns
(
    ObjectId,
    IndexId,
    KeyOrdinal,
    ColumnName
)
SELECT
    ic.object_id,
    ic.index_id,
    ic.key_ordinal,
    c.name

FROM sys.index_columns ic

INNER JOIN sys.columns c
    ON c.object_id = ic.object_id
    AND c.column_id = ic.column_id

WHERE ic.key_ordinal > 0

AND ic.object_id IN
(
    SELECT ObjectId
    FROM #ResolvedCandidates
    WHERE TableExists = 1
);
GO


/* ================================================================
   PART 10 — EXACT KEY DEFINITION MATCH

   The comparison is calculated first.
   No aggregate/subquery nesting problem.
   ================================================================ */

IF OBJECT_ID('tempdb..#IndexComparison') IS NOT NULL
    DROP TABLE #IndexComparison;
GO

CREATE TABLE #IndexComparison
(
    CandidateId INT NOT NULL,

    ExistingIndexId INT NULL,
    ExistingIndexName SYSNAME NULL,

    ExistingKeyCount INT NOT NULL,
    CandidateKeyCount INT NOT NULL,

    MatchingKeyCount INT NOT NULL,

    ExactKeyMatch BIT NOT NULL,

    ExistingKeyColumns NVARCHAR(4000) NULL,
    CandidateKeyColumns NVARCHAR(4000) NOT NULL
);
GO


INSERT INTO #IndexComparison
(
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    ExistingKeyCount,
    CandidateKeyCount,
    MatchingKeyCount,
    ExactKeyMatch,
    ExistingKeyColumns,
    CandidateKeyColumns
)
SELECT
    c.CandidateId,

    e.IndexId,
    e.IndexName,

    ISNULL(ec.ExistingKeyCount, 0),
    ISNULL(cc.CandidateKeyCount, 0),
    ISNULL(mc.MatchingKeyCount, 0),

    CASE
        WHEN ISNULL(ec.ExistingKeyCount, 0)
             =
             ISNULL(cc.CandidateKeyCount, 0)

         AND ISNULL(ec.ExistingKeyCount, 0)
             =
             ISNULL(mc.MatchingKeyCount, 0)

         AND ISNULL(cc.CandidateKeyCount, 0) > 0
        THEN 1
        ELSE 0
    END AS ExactKeyMatch,

    e.KeyColumns,
    c.KeyColumns

FROM #CandidateIndexes c

INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId

INNER JOIN #ExistingIndexes e
    ON e.ObjectId = r.ObjectId

LEFT JOIN
(
    SELECT
        ObjectId,
        IndexId,
        COUNT(*) AS ExistingKeyCount
    FROM #ExistingKeyColumns
    GROUP BY
        ObjectId,
        IndexId
) ec
    ON ec.ObjectId = r.ObjectId
    AND ec.IndexId = e.IndexId

LEFT JOIN
(
    SELECT
        CandidateId,
        COUNT(*) AS CandidateKeyCount
    FROM #CandidateKeyColumns
    GROUP BY CandidateId
) cc
    ON cc.CandidateId = c.CandidateId

LEFT JOIN
(
    SELECT
        ckc.CandidateId,
        ekc.ObjectId,
        ekc.IndexId,
        COUNT(*) AS MatchingKeyCount

    FROM #CandidateKeyColumns ckc

    INNER JOIN #ResolvedCandidates rc
        ON rc.CandidateId = ckc.CandidateId

    INNER JOIN #ExistingKeyColumns ekc
        ON ekc.ObjectId = rc.ObjectId
        AND ekc.KeyOrdinal = ckc.KeyOrdinal
        AND ekc.ColumnName = ckc.ColumnName

    GROUP BY
        ckc.CandidateId,
        ekc.ObjectId,
        ekc.IndexId
) mc
    ON mc.CandidateId = c.CandidateId
    AND mc.ObjectId = r.ObjectId
    AND mc.IndexId = e.IndexId

WHERE r.TableExists = 1;
GO


SELECT
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    ExistingKeyCount,
    CandidateKeyCount,
    MatchingKeyCount,
    ExactKeyMatch,
    ExistingKeyColumns,
    CandidateKeyColumns

FROM #IndexComparison

ORDER BY
    CandidateId,
    ExistingIndexId;
GO


/* ================================================================
   PART 11 — LEFT PREFIX ANALYSIS

   Prefix support means:

   Candidate:
       A,B

   Existing:
       A,B,C

   => FULL_COVERAGE

   Candidate:
       A,B

   Existing:
       A,C

   => PARTIAL_PREFIX

   Candidate:
       A,B

   Existing:
       C,D

   => NO_PREFIX
   ================================================================ */

IF OBJECT_ID('tempdb..#PrefixAnalysis') IS NOT NULL
    DROP TABLE #PrefixAnalysis;
GO

CREATE TABLE #PrefixAnalysis
(
    CandidateId INT NOT NULL,

    ExistingIndexId INT NOT NULL,
    ExistingIndexName SYSNAME NOT NULL,

    CandidateKeyCount INT NOT NULL,
    ExistingKeyCount INT NOT NULL,

    PrefixColumnCount INT NOT NULL,

    PrefixStatus VARCHAR(40) NOT NULL
);
GO


INSERT INTO #PrefixAnalysis
(
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    CandidateKeyCount,
    ExistingKeyCount,
    PrefixColumnCount,
    PrefixStatus
)
SELECT
    x.CandidateId,
    x.ExistingIndexId,
    x.ExistingIndexName,

    x.CandidateKeyCount,
    x.ExistingKeyCount,

    x.MatchingKeyCount AS PrefixColumnCount,

    CASE

        WHEN x.MatchingKeyCount >= x.CandidateKeyCount
        THEN 'FULL_COVERAGE'

        WHEN x.MatchingKeyCount > 0
        THEN 'PARTIAL_PREFIX'

        ELSE 'NO_PREFIX'

    END AS PrefixStatus

FROM #IndexComparison x;
GO


SELECT
    CandidateId,
    ExistingIndexId,
    ExistingIndexName,
    CandidateKeyCount,
    ExistingKeyCount,
    PrefixColumnCount,
    PrefixStatus

FROM #PrefixAnalysis

ORDER BY
    CandidateId,
    PrefixColumnCount DESC,
    ExistingIndexId;
GO


/* ================================================================
   PART 12 — BEST EXISTING COVERAGE PER CANDIDATE
   ================================================================ */

IF OBJECT_ID('tempdb..#BestCoverage') IS NOT NULL
    DROP TABLE #BestCoverage;
GO

CREATE TABLE #BestCoverage
(
    CandidateId INT NOT NULL,

    BestExistingIndexName SYSNAME NULL,
    BestExistingIndexId INT NULL,

    BestPrefixColumnCount INT NOT NULL,

    BestPrefixStatus VARCHAR(40) NOT NULL
);
GO


INSERT INTO #BestCoverage
(
    CandidateId,
    BestExistingIndexName,
    BestExistingIndexId,
    BestPrefixColumnCount,
    BestPrefixStatus
)
SELECT
    CandidateId,
    ExistingIndexName,
    ExistingIndexId,
    PrefixColumnCount,
    PrefixStatus

FROM
(
    SELECT
        p.*,

        ROW_NUMBER() OVER
        (
            PARTITION BY CandidateId

            ORDER BY
                PrefixColumnCount DESC,

                CASE PrefixStatus
                    WHEN 'FULL_COVERAGE' THEN 1
                    WHEN 'PARTIAL_PREFIX' THEN 2
                    WHEN 'NO_PREFIX' THEN 3
                    ELSE 4
                END,

                ExistingIndexId
        ) AS rn

    FROM #PrefixAnalysis p
) x

WHERE rn = 1;
GO


SELECT
    CandidateId,
    BestExistingIndexName,
    BestExistingIndexId,
    BestPrefixColumnCount,
    BestPrefixStatus

FROM #BestCoverage

ORDER BY CandidateId;
GO


/* ================================================================
   PART 13 — FINAL PREFLIGHT DECISION
   ================================================================ */

IF OBJECT_ID('tempdb..#PreflightStatus') IS NOT NULL
    DROP TABLE #PreflightStatus;
GO

CREATE TABLE #PreflightStatus
(
    CandidateId INT NOT NULL,

    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,

    ProposedIndexName SYSNAME NOT NULL,

    KeyColumns NVARCHAR(1000) NOT NULL,

    PriorityCode VARCHAR(20) NOT NULL,

    PreflightDecision VARCHAR(80) NOT NULL,

    BestExistingIndexName SYSNAME NULL,

    ExistingCoverage VARCHAR(40) NOT NULL,

    Reason NVARCHAR(1000) NOT NULL
);
GO


INSERT INTO #PreflightStatus
(
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    PriorityCode,
    PreflightDecision,
    BestExistingIndexName,
    ExistingCoverage,
    Reason
)
SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumns,
    c.PriorityCode,

    CASE

        WHEN r.TableExists = 0
        THEN 'ERROR_TABLE_NOT_FOUND'

        WHEN EXISTS
        (
            SELECT 1
            FROM #ExistingIndexes e
            WHERE e.ObjectId = r.ObjectId
              AND e.IndexName = c.ProposedIndexName
        )
        THEN 'REVIEW_EXISTING_NAME'

        WHEN EXISTS
        (
            SELECT 1
            FROM #IndexComparison x
            WHERE x.CandidateId = c.CandidateId
              AND x.ExactKeyMatch = 1
        )
        THEN 'DO_NOT_CREATE_EXACT_KEY_MATCH'

        WHEN ISNULL(b.BestPrefixStatus, 'NO_EXISTING_INDEX')
             =
             'FULL_COVERAGE'
        THEN 'REVIEW_FULL_COVERAGE'

        WHEN ISNULL(b.BestPrefixStatus, 'NO_EXISTING_INDEX')
             =
             'PARTIAL_PREFIX'
        THEN 'CREATE_CANDIDATE_PARTIAL_SUPPORT'

        WHEN ISNULL(b.BestPrefixStatus, 'NO_EXISTING_INDEX')
             =
             'NO_PREFIX'
        THEN 'CREATE_CANDIDATE_NO_EXISTING_PREFIX'

        ELSE
            'CREATE_CANDIDATE'

    END AS PreflightDecision,

    b.BestExistingIndexName,

    ISNULL
    (
        b.BestPrefixStatus,
        'NO_EXISTING_INDEX'
    ) AS ExistingCoverage,

    c.Reason

FROM #CandidateIndexes c

INNER JOIN #ResolvedCandidates r
    ON r.CandidateId = c.CandidateId

LEFT JOIN #BestCoverage b
    ON b.CandidateId = c.CandidateId;
GO


SELECT
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    PriorityCode,
    PreflightDecision,
    BestExistingIndexName,
    ExistingCoverage,
    Reason

FROM #PreflightStatus

ORDER BY
    CASE PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END,
    CandidateId;
GO


/* ================================================================
   PART 14 — FINAL SUMMARY

   IMPORTANT:
   No aggregate function contains EXISTS or another subquery.

   All logical decisions were calculated in #PreflightStatus first.
   ================================================================ */

SELECT
    COUNT(*) AS TotalCandidates,

    SUM
    (
        CASE
            WHEN PreflightDecision <> 'ERROR_TABLE_NOT_FOUND'
            THEN 1
            ELSE 0
        END
    ) AS TablesFound,

    SUM
    (
        CASE
            WHEN PreflightDecision = 'ERROR_TABLE_NOT_FOUND'
            THEN 1
            ELSE 0
        END
    ) AS TablesMissing,

    SUM
    (
        CASE
            WHEN PreflightDecision = 'REVIEW_EXISTING_NAME'
            THEN 1
            ELSE 0
        END
    ) AS ExistingIndexNameConflicts,

    SUM
    (
        CASE
            WHEN PreflightDecision = 'DO_NOT_CREATE_EXACT_KEY_MATCH'
            THEN 1
            ELSE 0
        END
    ) AS ExactKeyMatches,

    SUM
    (
        CASE
            WHEN PreflightDecision = 'REVIEW_FULL_COVERAGE'
            THEN 1
            ELSE 0
        END
    ) AS FullCoverageReviews,

    SUM
    (
        CASE
            WHEN PreflightDecision = 'CREATE_CANDIDATE_PARTIAL_SUPPORT'
            THEN 1
            ELSE 0
        END
    ) AS PartialSupportCandidates,

    SUM
    (
        CASE
            WHEN PreflightDecision = 'CREATE_CANDIDATE_NO_EXISTING_PREFIX'
            THEN 1
            ELSE 0
        END
    ) AS NoPrefixCandidates,

    SUM
    (
        CASE
            WHEN PreflightDecision LIKE 'CREATE_CANDIDATE%'
            THEN 1
            ELSE 0
        END
    ) AS TotalCreateCandidates

FROM #PreflightStatus;
GO


/* ================================================================
   PART 15 — CREATE-CANDIDATE REVIEW LIST

   This is NOT a CREATE INDEX script.
   It is only a review list.
   ================================================================ */

SELECT
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    ExistingCoverage,
    BestExistingIndexName,
    PreflightDecision,
    Reason

FROM #PreflightStatus

WHERE PreflightDecision LIKE 'CREATE_CANDIDATE%'

ORDER BY
    CASE PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END,
    CandidateId;
GO


/* ================================================================
   PART 16 — REVIEW / BLOCKED ITEMS
   ================================================================ */

SELECT
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumns,
    ExistingCoverage,
    BestExistingIndexName,
    PreflightDecision,
    Reason

FROM #PreflightStatus

WHERE PreflightDecision NOT LIKE 'CREATE_CANDIDATE%'

ORDER BY
    CASE PriorityCode
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END,
    CandidateId;
GO


/* ================================================================
   PART 17 — FINAL PREFLIGHT STATUS
   ================================================================ */

SELECT

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #PreflightStatus
            WHERE PreflightDecision = 'ERROR_TABLE_NOT_FOUND'
        )
        THEN 'FAIL'

        WHEN EXISTS
        (
            SELECT 1
            FROM #PreflightStatus
            WHERE PreflightDecision = 'REVIEW_EXISTING_NAME'
        )
        THEN 'REVIEW_REQUIRED'

        ELSE 'PREFLIGHT_COMPLETED'

    END AS PHASE_10_7_B_STATUS,

    (
        SELECT COUNT(*)
        FROM #PreflightStatus
    ) AS TotalCandidates,

    (
        SELECT COUNT(*)
        FROM #PreflightStatus
        WHERE PreflightDecision LIKE 'CREATE_CANDIDATE%'
    ) AS CreateCandidates,

    (
        SELECT COUNT(*)
        FROM #PreflightStatus
        WHERE PreflightDecision = 'DO_NOT_CREATE_EXACT_KEY_MATCH'
    ) AS ExactKeyMatches,

    (
        SELECT COUNT(*)
        FROM #PreflightStatus
        WHERE PreflightDecision = 'REVIEW_FULL_COVERAGE'
    ) AS FullCoverageReviews,

    (
        SELECT COUNT(*)
        FROM #PreflightStatus
        WHERE PreflightDecision = 'REVIEW_EXISTING_NAME'
    ) AS NameConflicts,

    (
        SELECT COUNT(*)
        FROM #PreflightStatus
        WHERE PreflightDecision = 'ERROR_TABLE_NOT_FOUND'
    ) AS MissingTables;
GO


/* ================================================================
   END OF PHASE 10.7-B
   ================================================================ */