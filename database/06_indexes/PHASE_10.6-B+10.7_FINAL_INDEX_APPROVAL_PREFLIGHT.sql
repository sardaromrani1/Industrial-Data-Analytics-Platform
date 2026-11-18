/* ================================================================
   PHASE 10.6-B + 10.7
   FINAL INDEX APPROVAL PREFLIGHT

   Purpose:
       Final read-only validation before creating new indexes.

   Scope:
       8 current performance/index candidates

   IMPORTANT:
       - READ ONLY
       - NO CREATE INDEX
       - NO ALTER INDEX
       - NO DROP INDEX
       - NO DATA MODIFICATION

   Decision values:
       APPROVE
       MERGE
       REDUNDANT
       DEFER
       REVIEW
================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '===============================================================';
PRINT 'PHASE 10.6-B + 10.7 FINAL INDEX APPROVAL PREFLIGHT';
PRINT 'READ-ONLY';
PRINT '===============================================================';


/* ================================================================
   PART 1
   Candidate Index Definitions
================================================================ */

IF OBJECT_ID('tempdb..#Candidates') IS NOT NULL
    DROP TABLE #Candidates;

CREATE TABLE #Candidates
(
    CandidateId INT NOT NULL,
    PriorityCode VARCHAR(20) NOT NULL,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,
    KeyColumn1 SYSNAME NOT NULL,
    KeyColumn2 SYSNAME NOT NULL,
    SourceCode VARCHAR(50) NOT NULL
);

INSERT INTO #Candidates
(
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumn1,
    KeyColumn2,
    SourceCode
)
VALUES
(1, 'HIGH',
 'event',
 'MaintenanceRecords',
 'IX_MaintenanceRecords_InstrumentId_MaintenanceDate',
 'InstrumentId',
 'MaintenanceDate',
 'PHASE10.7'),

(2, 'HIGH',
 'event',
 'FailureRecords',
 'IX_FailureRecords_InstrumentId_FailureDate',
 'InstrumentId',
 'FailureDate',
 'PHASE10.7'),

(3, 'HIGH',
 'event',
 'CalibrationRecords',
 'IX_CalibrationRecords_InstrumentId_CalibrationDate',
 'InstrumentId',
 'CalibrationDate',
 'PHASE10.7'),

(4, 'HIGH',
 'event',
 'InstrumentLifecycle',
 'IX_InstrumentLifecycle_InstrumentId_EffectiveFrom',
 'InstrumentId',
 'EffectiveFrom',
 'PHASE10.7'),

(5, 'HIGH',
 'event',
 'InstrumentOperationalStatusHistory',
 'IX_InstrumentOperationalStatusHistory_InstrumentId_EffectiveFrom',
 'InstrumentId',
 'EffectiveFrom',
 'PHASE10.7'),

(6, 'HIGH',
 'event',
 'InstrumentBypassHistory',
 'IX_InstrumentBypassHistory_InstrumentId_BypassStartDateTime',
 'InstrumentId',
 'BypassStartDateTime',
 'PHASE10.7'),

(7, 'MEDIUM',
 'rel',
 'SparePartInstruments',
 'IX_SparePartInstruments_InstrumentId_SparePartId',
 'InstrumentId',
 'SparePartId',
 'PHASE10.7'),

(8, 'MEDIUM',
 'rel',
 'SparePartInstrumentTypes',
 'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId',
 'InstrumentTypeId',
 'SparePartId',
 'PHASE10.7');


/* ================================================================
   PART 2
   Candidate List
================================================================ */

SELECT
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumn1,
    KeyColumn2,
    SourceCode
FROM #Candidates
ORDER BY CandidateId;


/* ================================================================
   PART 3
   Table Existence
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    CASE
        WHEN t.object_id IS NOT NULL
            THEN 'PRESENT'
        ELSE 'MISSING'
    END AS TableStatus
FROM #Candidates c
LEFT JOIN sys.tables t
    ON t.name = c.TableName
LEFT JOIN sys.schemas s
    ON s.schema_id = t.schema_id
   AND s.name = c.SchemaName
ORDER BY c.CandidateId;


/* ================================================================
   PART 4
   Column Existence
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.KeyColumn1,
    CASE
        WHEN col1.column_id IS NOT NULL
            THEN 'PRESENT'
        ELSE 'MISSING'
    END AS KeyColumn1Status,
    c.KeyColumn2,
    CASE
        WHEN col2.column_id IS NOT NULL
            THEN 'PRESENT'
        ELSE 'MISSING'
    END AS KeyColumn2Status
FROM #Candidates c
LEFT JOIN sys.tables t
    ON t.name = c.TableName
LEFT JOIN sys.schemas s
    ON s.schema_id = t.schema_id
   AND s.name = c.SchemaName
LEFT JOIN sys.columns col1
    ON col1.object_id = t.object_id
   AND col1.name = c.KeyColumn1
LEFT JOIN sys.columns col2
    ON col2.object_id = t.object_id
   AND col2.name = c.KeyColumn2
ORDER BY c.CandidateId;


/* ================================================================
   PART 5
   Proposed Index Name Conflicts
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    CASE
        WHEN i.object_id IS NOT NULL
            THEN 'NAME_CONFLICT'
        ELSE 'NO_CONFLICT'
    END AS NameStatus,
    i.index_id AS ExistingIndexId,
    i.type_desc AS ExistingIndexType
FROM #Candidates c
LEFT JOIN sys.tables t
    ON t.name = c.TableName
LEFT JOIN sys.schemas s
    ON s.schema_id = t.schema_id
   AND s.name = c.SchemaName
LEFT JOIN sys.indexes i
    ON i.object_id = t.object_id
   AND i.name = c.ProposedIndexName
ORDER BY c.CandidateId;


/* ================================================================
   PART 6
   Existing Indexes on Candidate Tables

   This is deliberately returned as detailed metadata.
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    i.index_id,
    i.name AS ExistingIndexName,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint,
    i.is_disabled,
    ic.key_ordinal,
    col.name AS ColumnName,
    ic.is_descending_key
FROM #Candidates c
JOIN sys.tables t
    ON t.name = c.TableName
JOIN sys.schemas s
    ON s.schema_id = t.schema_id
   AND s.name = c.SchemaName
JOIN sys.indexes i
    ON i.object_id = t.object_id
JOIN sys.index_columns ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
   AND ic.key_ordinal > 0
JOIN sys.columns col
    ON col.object_id = ic.object_id
   AND col.column_id = ic.column_id
WHERE i.type > 0
ORDER BY
    c.CandidateId,
    i.index_id,
    ic.key_ordinal;


/* ================================================================
   PART 7
   Exact Two-Column Key Match

   Checks whether an existing index has exactly:

       KeyColumn1, KeyColumn2

   as its first two key columns.

   Included columns do NOT count as key columns.
================================================================ */

IF OBJECT_ID('tempdb..#ExactMatch') IS NOT NULL
    DROP TABLE #ExactMatch;

CREATE TABLE #ExactMatch
(
    CandidateId INT NOT NULL,
    ExistingIndexName SYSNAME NULL,
    ExistingIndexId INT NULL,
    ExactMatch BIT NOT NULL
);

INSERT INTO #ExactMatch
(
    CandidateId,
    ExistingIndexName,
    ExistingIndexId,
    ExactMatch
)
SELECT
    c.CandidateId,
    MAX(CASE
        WHEN x.Key1 = c.KeyColumn1
         AND x.Key2 = c.KeyColumn2
         AND x.KeyCount = 2
        THEN x.IndexName
    END) AS ExistingIndexName,

    MAX(CASE
        WHEN x.Key1 = c.KeyColumn1
         AND x.Key2 = c.KeyColumn2
         AND x.KeyCount = 2
        THEN x.IndexId
    END) AS ExistingIndexId,

    CASE
        WHEN MAX(CASE
            WHEN x.Key1 = c.KeyColumn1
             AND x.Key2 = c.KeyColumn2
             AND x.KeyCount = 2
            THEN 1
            ELSE 0
        END) = 1
        THEN 1
        ELSE 0
    END AS ExactMatch
FROM #Candidates c
LEFT JOIN
(
    SELECT
        i.object_id,
        i.index_id AS IndexId,
        i.name AS IndexName,

        MAX(CASE
            WHEN ic.key_ordinal = 1
                THEN col.name
        END) AS Key1,

        MAX(CASE
            WHEN ic.key_ordinal = 2
                THEN col.name
        END) AS Key2,

        MAX(ic.key_ordinal) AS KeyCount
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON ic.object_id = i.object_id
       AND ic.index_id = i.index_id
       AND ic.key_ordinal > 0
    JOIN sys.columns col
        ON col.object_id = ic.object_id
       AND col.column_id = ic.column_id
    WHERE i.type > 0
    GROUP BY
        i.object_id,
        i.index_id,
        i.name
) x
    ON x.object_id =
       OBJECT_ID(QUOTENAME(c.SchemaName) + '.' + QUOTENAME(c.TableName))
GROUP BY
    c.CandidateId;


/* ================================================================
   PART 8
   Exact Match Results
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumn1,
    c.KeyColumn2,
    CASE
        WHEN e.ExactMatch = 1
            THEN 'EXACT_MATCH_EXISTS'
        ELSE 'NO_EXACT_MATCH'
    END AS ExactMatchStatus,
    e.ExistingIndexName,
    e.ExistingIndexId
FROM #Candidates c
JOIN #ExactMatch e
    ON e.CandidateId = c.CandidateId
ORDER BY c.CandidateId;


/* ================================================================
   PART 9
   Prefix Coverage

   Determines whether an existing index starts with:

       KeyColumn1

   or:

       KeyColumn1, KeyColumn2

   We distinguish:

       EXACT_TWO_COLUMN
       FIRST_COLUMN_PREFIX
       NO_PREFIX
================================================================ */

IF OBJECT_ID('tempdb..#PrefixCoverage') IS NOT NULL
    DROP TABLE #PrefixCoverage;

CREATE TABLE #PrefixCoverage
(
    CandidateId INT NOT NULL,
    ExistingIndexName SYSNAME NULL,
    ExistingIndexId INT NULL,
    CoverageType VARCHAR(30) NOT NULL
);

INSERT INTO #PrefixCoverage
(
    CandidateId,
    ExistingIndexName,
    ExistingIndexId,
    CoverageType
)
SELECT
    c.CandidateId,
    x.IndexName,
    x.IndexId,

    CASE
        WHEN x.Key1 = c.KeyColumn1
         AND x.Key2 = c.KeyColumn2
         AND x.KeyCount = 2
            THEN 'EXACT_TWO_COLUMN'

        WHEN x.Key1 = c.KeyColumn1
            THEN 'FIRST_COLUMN_PREFIX'

        ELSE 'NO_PREFIX'
    END
FROM #Candidates c
JOIN
(
    SELECT
        i.object_id,
        i.index_id AS IndexId,
        i.name AS IndexName,

        MAX(CASE
            WHEN ic.key_ordinal = 1
                THEN col.name
        END) AS Key1,

        MAX(CASE
            WHEN ic.key_ordinal = 2
                THEN col.name
        END) AS Key2,

        MAX(ic.key_ordinal) AS KeyCount
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON ic.object_id = i.object_id
       AND ic.index_id = i.index_id
       AND ic.key_ordinal > 0
    JOIN sys.columns col
        ON col.object_id = ic.object_id
       AND col.column_id = ic.column_id
    WHERE i.type > 0
    GROUP BY
        i.object_id,
        i.index_id,
        i.name
) x
    ON x.object_id =
       OBJECT_ID(QUOTENAME(c.SchemaName) + '.' + QUOTENAME(c.TableName))
WHERE
       x.Key1 = c.KeyColumn1
    OR
       (
           x.Key1 = c.KeyColumn1
       AND x.Key2 = c.KeyColumn2
       );


/* ================================================================
   PART 10
   Best Existing Prefix Coverage
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #PrefixCoverage p
            WHERE p.CandidateId = c.CandidateId
              AND p.CoverageType = 'EXACT_TWO_COLUMN'
        )
        THEN 'EXACT_TWO_COLUMN'

        WHEN EXISTS
        (
            SELECT 1
            FROM #PrefixCoverage p
            WHERE p.CandidateId = c.CandidateId
              AND p.CoverageType = 'FIRST_COLUMN_PREFIX'
        )
        THEN 'FIRST_COLUMN_PREFIX'

        ELSE 'NO_PREFIX'
    END AS BestCoverageStatus

FROM #Candidates c
ORDER BY c.CandidateId;


/* ================================================================
   PART 11
   Supporting FK Candidates for Candidate Tables

   This does NOT automatically approve FK indexes.
   It only identifies whether the proposed performance index
   could support FK columns beginning with KeyColumn1.
================================================================ */

SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.KeyColumn1,
    c.KeyColumn2,

    fk.name AS ForeignKeyName,
    parent_schema.name AS FKSchemaName,
    parent_table.name AS FKTableName,

    parent_col.name AS FKColumnName,

    CASE
        WHEN parent_col.name = c.KeyColumn1
            THEN 'PROPOSED_INDEX_STARTS_WITH_FK_COLUMN'
        ELSE 'NO_DIRECT_PREFIX'
    END AS FKCoverageAssessment

FROM #Candidates c

JOIN sys.tables parent_table
    ON parent_table.object_id =
       OBJECT_ID(QUOTENAME(c.SchemaName) + '.' + QUOTENAME(c.TableName))

JOIN sys.schemas parent_schema
    ON parent_schema.schema_id = parent_table.schema_id

JOIN sys.foreign_key_columns fkc
    ON fkc.parent_object_id = parent_table.object_id

JOIN sys.foreign_keys fk
    ON fk.object_id = fkc.constraint_object_id

JOIN sys.columns parent_col
    ON parent_col.object_id = fkc.parent_object_id
   AND parent_col.column_id = fkc.parent_column_id

ORDER BY
    c.CandidateId,
    fk.name;


/* ================================================================
   PART 12
   Candidate Decision Matrix

   Important:
       This is a PRELIMINARY AUTOMATED DECISION.

   APPROVE:
       No exact index and no first-column prefix.

   REDUNDANT:
       Exact index already exists.

   REVIEW:
       Existing first-column prefix exists.

   The final human/architectural decision remains explicit.
================================================================ */

IF OBJECT_ID('tempdb..#DecisionMatrix') IS NOT NULL
    DROP TABLE #DecisionMatrix;

CREATE TABLE #DecisionMatrix
(
    CandidateId INT NOT NULL,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,
    PriorityCode VARCHAR(20) NOT NULL,
    ExactMatchStatus VARCHAR(30) NOT NULL,
    BestCoverageStatus VARCHAR(30) NOT NULL,
    PreliminaryDecision VARCHAR(30) NOT NULL
);

INSERT INTO #DecisionMatrix
(
    CandidateId,
    SchemaName,
    TableName,
    ProposedIndexName,
    PriorityCode,
    ExactMatchStatus,
    BestCoverageStatus,
    PreliminaryDecision
)
SELECT
    c.CandidateId,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,
    c.PriorityCode,

    CASE
        WHEN e.ExactMatch = 1
            THEN 'EXACT_MATCH_EXISTS'
        ELSE 'NO_EXACT_MATCH'
    END,

    CASE
        WHEN e.ExactMatch = 1
            THEN 'EXACT_TWO_COLUMN'

        WHEN EXISTS
        (
            SELECT 1
            FROM #PrefixCoverage p
            WHERE p.CandidateId = c.CandidateId
              AND p.CoverageType = 'FIRST_COLUMN_PREFIX'
        )
            THEN 'FIRST_COLUMN_PREFIX'

        ELSE 'NO_PREFIX'
    END,

    CASE
        WHEN e.ExactMatch = 1
            THEN 'REDUNDANT'

        WHEN EXISTS
        (
            SELECT 1
            FROM #PrefixCoverage p
            WHERE p.CandidateId = c.CandidateId
              AND p.CoverageType = 'FIRST_COLUMN_PREFIX'
        )
            THEN 'REVIEW'

        ELSE 'APPROVE'
    END

FROM #Candidates c
JOIN #ExactMatch e
    ON e.CandidateId = c.CandidateId;


/* ================================================================
   PART 13
   FINAL PRELIMINARY MATRIX
================================================================ */

SELECT
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    ExactMatchStatus,
    BestCoverageStatus,
    PreliminaryDecision
FROM #DecisionMatrix
ORDER BY CandidateId;


/* ================================================================
   PART 14
   Summary
================================================================ */

SELECT
    PreliminaryDecision,
    COUNT(*) AS CandidateCount
FROM #DecisionMatrix
GROUP BY PreliminaryDecision
ORDER BY PreliminaryDecision;


/* ================================================================
   PART 15
   High-Priority Candidates Requiring Attention
================================================================ */

SELECT
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    BestCoverageStatus,
    PreliminaryDecision
FROM #DecisionMatrix
WHERE PriorityCode = 'HIGH'
ORDER BY CandidateId;


/* ================================================================
   PART 16
   No-Prefix Candidates
================================================================ */

SELECT
    CandidateId,
    PriorityCode,
    SchemaName,
    TableName,
    ProposedIndexName,
    BestCoverageStatus,
    PreliminaryDecision
FROM #DecisionMatrix
WHERE BestCoverageStatus = 'NO_PREFIX'
ORDER BY CandidateId;


 /*================================================================
   PART 17
   Final Preflight Status

   PASS means:
       - all candidate tables exist
       - all candidate columns exist
       - no name conflict
       - metadata examination completed

   This does NOT mean indexes should automatically be created.
================================================================ */

SELECT
    CASE
        WHEN
            NOT EXISTS
            (
                SELECT 1
                FROM #Candidates c
                LEFT JOIN sys.tables t
                    ON t.name = c.TableName
                LEFT JOIN sys.schemas s
                    ON s.schema_id = t.schema_id
                   AND s.name = c.SchemaName
                WHERE t.object_id IS NULL
            )
        AND
            NOT EXISTS
            (
                SELECT 1
                FROM #Candidates c
                LEFT JOIN sys.tables t
                    ON t.name = c.TableName
                LEFT JOIN sys.schemas s
                    ON s.schema_id = t.schema_id
                   AND s.name = c.SchemaName
                LEFT JOIN sys.columns col1
                    ON col1.object_id = t.object_id
                   AND col1.name = c.KeyColumn1
                LEFT JOIN sys.columns col2
                    ON col2.object_id = t.object_id
                   AND col2.name = c.KeyColumn2
                WHERE col1.column_id IS NULL
                   OR col2.column_id IS NULL
            )
        AND
            NOT EXISTS
            (
                SELECT 1
                FROM #Candidates c
                JOIN sys.tables t
                    ON t.name = c.TableName
                JOIN sys.schemas s
                    ON s.schema_id = t.schema_id
                   AND s.name = c.SchemaName
                JOIN sys.indexes i
                    ON i.object_id = t.object_id
                   AND i.name = c.ProposedIndexName
            )
        THEN 'PHASE_10_6B_10_7_PREFLIGHT_PASS'

        ELSE 'PHASE_10_6B_10_7_PREFLIGHT_REVIEW'
    END AS FinalPreflightStatus;


/* ================================================================
   PART 18
   Safety Confirmation
================================================================ */

SELECT
    'READ_ONLY' AS ExecutionMode,
    'NO CREATE INDEX EXECUTED' AS CreateIndexStatus,
    'NO ALTER INDEX EXECUTED' AS AlterIndexStatus,
    'NO DROP INDEX EXECUTED' AS DropIndexStatus;


/* ================================================================
   END
================================================================ */

PRINT '===============================================================';
PRINT 'PHASE 10.6-B + 10.7 FINAL INDEX APPROVAL PREFLIGHT COMPLETED';
PRINT 'NO INDEX WAS CREATED, ALTERED OR DROPPED';
PRINT '===============================================================';