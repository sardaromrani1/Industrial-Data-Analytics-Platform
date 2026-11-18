/* ================================================================
   PHASE 10.6-B + 10.7
   FINAL INDEX APPROVAL PREFLIGHT
   ADDITIONAL PARTS: 11, 13, 14, 17

   READ-ONLY
   NO CREATE INDEX
   NO ALTER INDEX
   NO DROP INDEX

   Purpose:
     PART 11 = FK Supporting Candidates
     PART 13 = Preliminary Final Decision Matrix
     PART 14 = Summary
     PART 17 = Final Preflight Status
   ================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('tempdb..#Candidates') IS NOT NULL
    DROP TABLE #Candidates;

IF OBJECT_ID('tempdb..#FKSupport') IS NOT NULL
    DROP TABLE #FKSupport;

IF OBJECT_ID('tempdb..#Decision') IS NOT NULL
    DROP TABLE #Decision;

IF OBJECT_ID('tempdb..#Validation') IS NOT NULL
    DROP TABLE #Validation;


---------------------------------------------------------------
-- PART 0
-- Candidate Definition
---------------------------------------------------------------

CREATE TABLE #Candidates
(
    CandidateNo INT NOT NULL PRIMARY KEY,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,
    KeyColumn1 SYSNAME NOT NULL,
    KeyColumn2 SYSNAME NOT NULL,
    PriorityCode VARCHAR(20) NOT NULL
);

INSERT INTO #Candidates
(
    CandidateNo,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyColumn1,
    KeyColumn2,
    PriorityCode
)
VALUES
(1,
 'event',
 'MaintenanceRecords',
 'IX_MaintenanceRecords_InstrumentId_MaintenanceDate',
 'InstrumentId',
 'MaintenanceDate',
 'HIGH'),

(2,
 'event',
 'FailureRecords',
 'IX_FailureRecords_InstrumentId_FailureDate',
 'InstrumentId',
 'FailureDate',
 'HIGH'),

(3,
 'event',
 'CalibrationRecords',
 'IX_CalibrationRecords_InstrumentId_CalibrationDate',
 'InstrumentId',
 'CalibrationDate',
 'HIGH'),

(4,
 'event',
 'InstrumentLifecycle',
 'IX_InstrumentLifecycle_InstrumentId_EffectiveFrom',
 'InstrumentId',
 'EffectiveFrom',
 'HIGH'),

(5,
 'event',
 'InstrumentOperationalStatusHistory',
 'IX_InstrumentOperationalStatusHistory_InstrumentId_EffectiveFrom',
 'InstrumentId',
 'EffectiveFrom',
 'HIGH'),

(6,
 'event',
 'InstrumentBypassHistory',
 'IX_InstrumentBypassHistory_InstrumentId_BypassStartDateTime',
 'InstrumentId',
 'BypassStartDateTime',
 'HIGH'),

(7,
 'rel',
 'SparePartInstruments',
 'IX_SparePartInstruments_InstrumentId_SparePartId',
 'InstrumentId',
 'SparePartId',
 'MEDIUM'),

(8,
 'rel',
 'SparePartInstrumentTypes',
 'IX_SparePartInstrumentTypes_InstrumentTypeId_SparePartId',
 'InstrumentTypeId',
 'SparePartId',
 'MEDIUM');


---------------------------------------------------------------
-- PART 11
-- FK SUPPORTING CANDIDATES
--
-- Determines whether the proposed two-column index starts
-- with the first column of an existing FK.
--
-- This is READ-ONLY.
---------------------------------------------------------------

CREATE TABLE #FKSupport
(
    CandidateNo INT NOT NULL,
    FKName SYSNAME NOT NULL,
    FKColumn SYSNAME NOT NULL,
    FKColumnPosition INT NOT NULL,
    SupportStatus VARCHAR(50) NOT NULL
);

INSERT INTO #FKSupport
(
    CandidateNo,
    FKName,
    FKColumn,
    FKColumnPosition,
    SupportStatus
)
SELECT
    c.CandidateNo,
    fk.name AS FKName,
    col.name AS FKColumn,
    fkc.constraint_column_id AS FKColumnPosition,

    CASE
        WHEN fkc.constraint_column_id = 1
             AND col.name = c.KeyColumn1
        THEN 'PROPOSED_INDEX_SUPPORTS_FK'

        ELSE 'NO_DIRECT_SUPPORT'
    END AS SupportStatus

FROM #Candidates c

INNER JOIN sys.tables t
    ON t.name = c.TableName

INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
   AND s.name = c.SchemaName

INNER JOIN sys.foreign_keys fk
    ON fk.parent_object_id = t.object_id

INNER JOIN sys.foreign_key_columns fkc
    ON fkc.constraint_object_id = fk.object_id

INNER JOIN sys.columns col
    ON col.object_id = t.object_id
   AND col.column_id = fkc.parent_column_id;


SELECT
    CandidateNo,
    FKName,
    FKColumn,
    FKColumnPosition,
    SupportStatus
FROM #FKSupport
ORDER BY
    CandidateNo,
    FKName,
    FKColumnPosition;


---------------------------------------------------------------
-- PART 13
-- PRELIMINARY FINAL DECISION MATRIX
--
-- Current decision logic:
--
-- Candidates 7 and 8:
--   Strong reverse-access-path candidates.
--   Existing PK starts with the opposite column order.
--   APPROVE.
--
-- Candidates 1-6:
--   Existing InstrumentId FK indexes already provide a
--   single-column prefix.
--   New composite index adds date/time ordering.
--   However, because the current database has essentially
--   no operational workload, keep them REVIEW.
--
-- No index is created here.
---------------------------------------------------------------

CREATE TABLE #Decision
(
    CandidateNo INT NOT NULL PRIMARY KEY,
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ProposedIndexName SYSNAME NOT NULL,
    KeyDefinition VARCHAR(300) NOT NULL,
    PriorityCode VARCHAR(20) NOT NULL,
    ExistingPrefixSupport VARCHAR(50) NOT NULL,
    FKSupport VARCHAR(50) NOT NULL,
    PreliminaryDecision VARCHAR(20) NOT NULL,
    DecisionReason VARCHAR(500) NOT NULL
);

INSERT INTO #Decision
(
    CandidateNo,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyDefinition,
    PriorityCode,
    ExistingPrefixSupport,
    FKSupport,
    PreliminaryDecision,
    DecisionReason
)
SELECT
    c.CandidateNo,
    c.SchemaName,
    c.TableName,
    c.ProposedIndexName,

    '(' +
    c.KeyColumn1 +
    ', ' +
    c.KeyColumn2 +
    ')' AS KeyDefinition,

    c.PriorityCode,

    CASE
        WHEN c.CandidateNo IN (7,8)
        THEN 'REVERSE_PK_ORDER'
        ELSE 'SINGLE_COLUMN_PREFIX'
    END AS ExistingPrefixSupport,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #FKSupport f
            WHERE f.CandidateNo = c.CandidateNo
              AND f.SupportStatus = 'PROPOSED_INDEX_SUPPORTS_FK'
        )
        THEN 'YES'
        ELSE 'NO'
    END AS FKSupport,

    CASE
        WHEN c.CandidateNo IN (7,8)
        THEN 'APPROVE'
        ELSE 'REVIEW'
    END AS PreliminaryDecision,

    CASE
        WHEN c.CandidateNo = 7
        THEN
            'Provides reverse access path for InstrumentId and supports the Instrument FK.'

        WHEN c.CandidateNo = 8
        THEN
            'Provides reverse access path for InstrumentTypeId and supports the InstrumentType FK.'

        WHEN c.CandidateNo = 1
        THEN
            'Existing InstrumentId index provides prefix support; additional MaintenanceDate ordering requires workload confirmation.'

        WHEN c.CandidateNo = 2
        THEN
            'Existing InstrumentId index provides prefix support; additional FailureDate ordering requires workload confirmation.'

        WHEN c.CandidateNo = 3
        THEN
            'Existing InstrumentId index provides prefix support; additional CalibrationDate ordering requires workload confirmation.'

        WHEN c.CandidateNo = 4
        THEN
            'Existing InstrumentId index provides prefix support; EffectiveFrom ordering requires workload confirmation.'

        WHEN c.CandidateNo = 5
        THEN
            'Existing InstrumentId index provides prefix support; EffectiveFrom ordering requires workload confirmation.'

        WHEN c.CandidateNo = 6
        THEN
            'Existing InstrumentId index provides prefix support; BypassStartDateTime ordering requires workload confirmation.'

        ELSE
            'Requires further review.'
    END AS DecisionReason

FROM #Candidates c;


SELECT
    CandidateNo,
    SchemaName,
    TableName,
    ProposedIndexName,
    KeyDefinition,
    PriorityCode,
    ExistingPrefixSupport,
    FKSupport,
    PreliminaryDecision,
    DecisionReason
FROM #Decision
ORDER BY CandidateNo;


---------------------------------------------------------------
-- PART 14
-- SUMMARY
---------------------------------------------------------------

IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
    DROP TABLE #Summary;

CREATE TABLE #Summary
(
    PreliminaryDecision VARCHAR(20) NOT NULL,
    CandidateCount INT NOT NULL,
    SortOrder INT NOT NULL
);

INSERT INTO #Summary
(
    PreliminaryDecision,
    CandidateCount,
    SortOrder
)
SELECT
    PreliminaryDecision,
    COUNT(*),
    CASE
        WHEN PreliminaryDecision = 'APPROVE' THEN 1
        WHEN PreliminaryDecision = 'REVIEW' THEN 2
        ELSE 3
    END
FROM #Decision
GROUP BY PreliminaryDecision;

INSERT INTO #Summary
(
    PreliminaryDecision,
    CandidateCount,
    SortOrder
)
SELECT
    'TOTAL',
    COUNT(*),
    3
FROM #Decision;

SELECT
    PreliminaryDecision,
    CandidateCount
FROM #Summary
ORDER BY SortOrder;
---------------------------------------------------------------
-- PART 17
-- FINAL PREFLIGHT STATUS
--
-- This does NOT authorize CREATE INDEX.
-- It only confirms that the additional preflight checks
-- completed successfully and that the decision matrix
-- contains all 8 candidates.
---------------------------------------------------------------

CREATE TABLE #Validation
(
    CheckName VARCHAR(100) NOT NULL,
    ExpectedValue INT NOT NULL,
    ActualValue INT NOT NULL,
    Status VARCHAR(20) NOT NULL
);


INSERT INTO #Validation
(
    CheckName,
    ExpectedValue,
    ActualValue,
    Status
)
SELECT
    'Candidate count',
    8,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 8 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM #Candidates;


INSERT INTO #Validation
(
    CheckName,
    ExpectedValue,
    ActualValue,
    Status
)
SELECT
    'Decision matrix count',
    8,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 8 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM #Decision;


INSERT INTO #Validation
(
    CheckName,
    ExpectedValue,
    ActualValue,
    Status
)
SELECT
    'APPROVE candidates',
    2,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM #Decision
WHERE PreliminaryDecision = 'APPROVE';


INSERT INTO #Validation
(
    CheckName,
    ExpectedValue,
    ActualValue,
    Status
)
SELECT
    'REVIEW candidates',
    6,
    COUNT(*),
    CASE
        WHEN COUNT(*) = 6 THEN 'PASS'
        ELSE 'FAIL'
    END
FROM #Decision
WHERE PreliminaryDecision = 'REVIEW';


SELECT
    CheckName,
    ExpectedValue,
    ActualValue,
    Status
FROM #Validation
ORDER BY CheckName;


---------------------------------------------------------------
-- FINAL STATUS
---------------------------------------------------------------

SELECT
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #Validation
            WHERE Status = 'FAIL'
        )
        THEN 'FAIL'
        ELSE 'PASS'
    END AS PHASE_10_6B_10_7_FINAL_INDEX_PREFLIGHT_STATUS;


---------------------------------------------------------------
-- SAFETY CONFIRMATION
---------------------------------------------------------------

SELECT
    'READ_ONLY_NO_INDEX_CHANGES' AS ExecutionMode,
    'NO_CREATE_INDEX' AS CreateIndexStatus,
    'NO_ALTER_INDEX' AS AlterIndexStatus,
    'NO_DROP_INDEX' AS DropIndexStatus;