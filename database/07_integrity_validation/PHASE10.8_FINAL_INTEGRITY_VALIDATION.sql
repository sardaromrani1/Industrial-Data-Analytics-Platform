USE [ComprehensiveInstrumentationDB_New];
GO

SET NOCOUNT ON;
GO

/* ================================================================
   PHASE 10.8
   PRE-INDEX FINAL INTEGRITY VALIDATION

   Database:
       ComprehensiveInstrumentationDB_New

   PURPOSE:
       Final read-only integrity validation before index creation.

   IMPORTANT:
       This script does NOT:
           CREATE INDEX
           DROP INDEX
           ALTER INDEX
           ALTER TABLE
           CREATE TRIGGER
           DROP TRIGGER
           INSERT
           UPDATE
           DELETE

   ================================================================ */


/* ================================================================
   PART 1
   REQUIRED SCHEMAS
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredSchemas') IS NOT NULL
    DROP TABLE #RequiredSchemas;
GO

CREATE TABLE #RequiredSchemas
(
    SchemaName SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredSchemas
(
    SchemaName
)
VALUES
('dbo'),
('ref'),
('rel'),
('event'),
('inv'),
('doc'),
('analytics');
GO


SELECT
    rs.SchemaName,

    CASE
        WHEN s.schema_id IS NOT NULL
            THEN 'EXISTS'
        ELSE 'MISSING'
    END AS SchemaStatus

FROM #RequiredSchemas rs

LEFT JOIN sys.schemas s
    ON s.name = rs.SchemaName

ORDER BY rs.SchemaName;
GO


/* ================================================================
   PART 2
   REQUIRED TABLES
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredTables') IS NOT NULL
    DROP TABLE #RequiredTables;
GO

CREATE TABLE #RequiredTables
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredTables
(
    SchemaName,
    TableName
)
VALUES
('dbo','Sites'),
('dbo','ProcessUnits'),
('dbo','SubSystems'),
('dbo','InstrumentTypes'),
('dbo','ControlSystems'),
('dbo','Instruments'),
('dbo','Manufacturers'),
('dbo','Personnel'),
('dbo','Suppliers'),
('dbo','Contractors'),
('dbo','ReferenceEquipment'),
('dbo','SpareParts'),
('dbo','TripsInterlocks'),

('ref','Currency'),
('ref','UnitOfMeasure'),
('ref','InstrumentStatus'),
('ref','LifecycleStatus'),

('rel','ProcessUnitControlSystems'),
('rel','InstrumentControlSystems'),
('rel','InstrumentRedundancy'),
('rel','TripInstruments'),
('rel','SparePartInstrumentTypes'),
('rel','SparePartInstruments'),
('rel','SparePartInterchangeability'),

('event','CalibrationRecords'),
('event','CalibrationTestPoints'),
('event','MaintenanceRecords'),
('event','MaintenanceLabor'),
('event','FailureRecords'),
('event','InstrumentLifecycle'),
('event','InstrumentOperationalStatusHistory'),
('event','InstrumentBypassHistory'),
('event','SparePartUsage'),

('inv','InventoryLocations'),
('inv','SparePartInventoryPolicy'),
('inv','SparePartSuppliers'),
('inv','InventoryTransactions'),

('doc','Documents'),
('doc','DocumentFiles'),
('doc','InstrumentDocuments'),
('doc','MaintenanceDocuments'),
('doc','FailureDocuments'),
('doc','CalibrationDocuments'),
('doc','SparePartDocuments');
GO


SELECT
    rt.SchemaName,
    rt.TableName,

    CASE
        WHEN t.object_id IS NOT NULL
            THEN 'EXISTS'
        ELSE 'MISSING'
    END AS TableStatus,

    t.object_id AS ObjectId

FROM #RequiredTables rt

LEFT JOIN sys.schemas s
    ON s.name = rt.SchemaName

LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = rt.TableName

ORDER BY
    rt.SchemaName,
    rt.TableName;
GO


/* ================================================================
   PART 3
   MISSING SCHEMA / TABLE SUMMARY
   ================================================================ */

DECLARE @MissingSchemas INT;
DECLARE @MissingTables INT;

SELECT
    @MissingSchemas = COUNT(*)
FROM #RequiredSchemas rs
LEFT JOIN sys.schemas s
    ON s.name = rs.SchemaName
WHERE s.schema_id IS NULL;

SELECT
    @MissingTables = COUNT(*)
FROM #RequiredTables rt
LEFT JOIN sys.schemas s
    ON s.name = rt.SchemaName
LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = rt.TableName
WHERE t.object_id IS NULL;

SELECT
    @MissingSchemas AS MissingSchemaCount,
    @MissingTables AS MissingTableCount;
GO


/* ================================================================
   PART 4
   PRIMARY KEY VALIDATION
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredPKTables') IS NOT NULL
    DROP TABLE #RequiredPKTables;
GO

CREATE TABLE #RequiredPKTables
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredPKTables
VALUES
('dbo','Sites'),
('dbo','ProcessUnits'),
('dbo','SubSystems'),
('dbo','InstrumentTypes'),
('dbo','ControlSystems'),
('dbo','Instruments'),
('dbo','Manufacturers'),
('dbo','Personnel'),
('dbo','Suppliers'),
('dbo','Contractors'),
('dbo','ReferenceEquipment'),
('dbo','SpareParts'),
('dbo','TripsInterlocks'),
('ref','Currency'),
('ref','UnitOfMeasure'),
('ref','InstrumentStatus'),
('ref','LifecycleStatus'),
('event','CalibrationRecords'),
('event','CalibrationTestPoints'),
('event','MaintenanceRecords'),
('event','MaintenanceLabor'),
('event','FailureRecords'),
('event','InstrumentLifecycle'),
('event','InstrumentOperationalStatusHistory'),
('event','InstrumentBypassHistory'),
('event','SparePartUsage'),
('inv','InventoryLocations'),
('inv','SparePartInventoryPolicy'),
('inv','SparePartSuppliers'),
('inv','InventoryTransactions'),
('doc','Documents'),
('doc','DocumentFiles'),
('doc','InstrumentDocuments'),
('doc','MaintenanceDocuments'),
('doc','FailureDocuments'),
('doc','CalibrationDocuments'),
('doc','SparePartDocuments');
GO


SELECT
    p.SchemaName,
    p.TableName,

    CASE
        WHEN pk.object_id IS NOT NULL
            THEN 'PK_EXISTS'
        ELSE 'PK_MISSING'
    END AS PKStatus,

    pk.name AS PKName

FROM #RequiredPKTables p

LEFT JOIN sys.schemas s
    ON s.name = p.SchemaName

LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = p.TableName

LEFT JOIN sys.key_constraints pk
    ON pk.parent_object_id = t.object_id
    AND pk.type = 'PK'

ORDER BY
    p.SchemaName,
    p.TableName;
GO


/* ================================================================
   PART 5
   ALL FOREIGN KEY HEALTH
   ================================================================ */

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    fk.name AS ForeignKeyName,

    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted,

    CASE
        WHEN fk.is_disabled = 0
         AND fk.is_not_trusted = 0
            THEN 'HEALTHY'
        ELSE 'REVIEW'
    END AS FKStatus

FROM sys.foreign_keys fk

INNER JOIN sys.tables t
    ON t.object_id = fk.parent_object_id

INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id

ORDER BY
    s.name,
    t.name,
    fk.name;
GO


/* ================================================================
   PART 6
   REQUIRED FOREIGN KEYS
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredFKs') IS NOT NULL
    DROP TABLE #RequiredFKs;
GO

CREATE TABLE #RequiredFKs
(
    FKName SYSNAME NOT NULL,
    ParentSchema SYSNAME NOT NULL,
    ParentTable SYSNAME NOT NULL,
    ReferencedSchema SYSNAME NOT NULL,
    ReferencedTable SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredFKs
VALUES
(
    'FK_TripInstruments_Trip',
    'rel',
    'TripInstruments',
    'dbo',
    'TripsInterlocks'
),
(
    'FK_InventoryTransactions_Maintenance',
    'inv',
    'InventoryTransactions',
    'event',
    'MaintenanceRecords'
),
(
    'FK_InventoryTransactions_Failure',
    'inv',
    'InventoryTransactions',
    'event',
    'FailureRecords'
),
(
    'FK_SparePartUsage_Maintenance',
    'event',
    'SparePartUsage',
    'event',
    'MaintenanceRecords'
),
(
    'FK_SparePartUsage_Failure',
    'event',
    'SparePartUsage',
    'event',
    'FailureRecords'
),
(
    'FK_Instruments_SubSystem_Unit',
    'dbo',
    'Instruments',
    'dbo',
    'SubSystems'
),
(
    'FK_FailureRecords_PreviousFailure_Instrument',
    'event',
    'FailureRecords',
    'event',
    'FailureRecords'
),
(
    'FK_SparePartUsage_InventoryTransaction_SparePart',
    'event',
    'SparePartUsage',
    'inv',
    'InventoryTransactions'
),
(
    'FK_StatusHistory_Failure_Instrument',
    'event',
    'InstrumentOperationalStatusHistory',
    'event',
    'FailureRecords'
),
(
    'FK_StatusHistory_Maintenance_Instrument',
    'event',
    'InstrumentOperationalStatusHistory',
    'event',
    'MaintenanceRecords'
),
(
    'FK_SparePartUsage_Maintenance_Instrument',
    'event',
    'SparePartUsage',
    'event',
    'MaintenanceRecords'
),
(
    'FK_SparePartUsage_Failure_Instrument',
    'event',
    'SparePartUsage',
    'event',
    'FailureRecords'
);
GO


SELECT
    r.FKName,

    r.ParentSchema,
    r.ParentTable,

    r.ReferencedSchema,
    r.ReferencedTable,

    CASE
        WHEN fk.object_id IS NULL
            THEN 'MISSING'
        WHEN fk.is_disabled = 1
            THEN 'DISABLED'
        WHEN fk.is_not_trusted = 1
            THEN 'UNTRUSTED'
        ELSE 'HEALTHY'
    END AS FKStatus

FROM #RequiredFKs r

LEFT JOIN sys.schemas ps
    ON ps.name = r.ParentSchema

LEFT JOIN sys.tables pt
    ON pt.schema_id = ps.schema_id
    AND pt.name = r.ParentTable

LEFT JOIN sys.foreign_keys fk
    ON fk.name = r.FKName
    AND fk.parent_object_id = pt.object_id

ORDER BY r.FKName;
GO


/* ================================================================
   PART 7
   ORPHAN CHECK — INSTRUMENT / SUBSYSTEM / UNIT
   ================================================================ */

SELECT
    COUNT(*) AS OrphanInstrumentSubSystemUnitCount

FROM dbo.Instruments i

INNER JOIN dbo.SubSystems ss
    ON ss.SubSystemId = i.SubSystemId

WHERE i.SubSystemId IS NOT NULL
  AND ss.UnitId <> i.UnitId;
GO


/* ================================================================
   PART 8
   PREVIOUS FAILURE INTEGRITY
   ================================================================ */

SELECT
    COUNT(*) AS InvalidPreviousFailureCount

FROM event.FailureRecords f

INNER JOIN event.FailureRecords pf
    ON pf.FailureId = f.PreviousFailureId

WHERE f.PreviousFailureId IS NOT NULL
  AND pf.InstrumentId <> f.InstrumentId;
GO


/* ================================================================
   PART 9
   SPARE PART USAGE / INVENTORY TRANSACTION INTEGRITY
   ================================================================ */

SELECT
    COUNT(*) AS InvalidSparePartInventoryTransactionCount

FROM event.SparePartUsage u

INNER JOIN inv.InventoryTransactions it
    ON it.InventoryTransactionId = u.InventoryTransactionId

WHERE it.SparePartId <> u.SparePartId;
GO


/* ================================================================
   PART 10
   STATUS HISTORY / FAILURE INSTRUMENT INTEGRITY
   ================================================================ */

SELECT
    COUNT(*) AS InvalidStatusFailureInstrumentCount

FROM event.InstrumentOperationalStatusHistory sh

INNER JOIN event.FailureRecords f
    ON f.FailureId = sh.FailureId

WHERE sh.FailureId IS NOT NULL
  AND f.InstrumentId <> sh.InstrumentId;
GO


/* ================================================================
   PART 11
   STATUS HISTORY / MAINTENANCE INSTRUMENT INTEGRITY
   ================================================================ */

SELECT
    COUNT(*) AS InvalidStatusMaintenanceInstrumentCount

FROM event.InstrumentOperationalStatusHistory sh

INNER JOIN event.MaintenanceRecords m
    ON m.MaintenanceId = sh.MaintenanceId

WHERE sh.MaintenanceId IS NOT NULL
  AND m.InstrumentId <> sh.InstrumentId;
GO


/* ================================================================
   PART 12
   SPARE PART USAGE / MAINTENANCE INSTRUMENT INTEGRITY
   ================================================================ */

SELECT
    COUNT(*) AS InvalidUsageMaintenanceInstrumentCount

FROM event.SparePartUsage u

INNER JOIN event.MaintenanceRecords m
    ON m.MaintenanceId = u.MaintenanceId

WHERE u.MaintenanceId IS NOT NULL
  AND u.InstrumentId IS NOT NULL
  AND m.InstrumentId <> u.InstrumentId;
GO


/* ================================================================
   PART 13
   SPARE PART USAGE / FAILURE INSTRUMENT INTEGRITY
   ================================================================ */

SELECT
    COUNT(*) AS InvalidUsageFailureInstrumentCount

FROM event.SparePartUsage u

INNER JOIN event.FailureRecords f
    ON f.FailureId = u.FailureId

WHERE u.FailureId IS NOT NULL
  AND u.InstrumentId IS NOT NULL
  AND f.InstrumentId <> u.InstrumentId;
GO


/* ================================================================
   PART 14
   TRIP / INSTRUMENT / PROCESS UNIT INTEGRITY
   ================================================================ */


/* TripInstruments → Instrument / Trip ProcessUnit */

SELECT
    COUNT(*) AS InvalidTripInstrumentProcessUnitCount

FROM rel.TripInstruments ti

INNER JOIN dbo.Instruments i
    ON i.InstrumentId = ti.InstrumentId

INNER JOIN dbo.TripsInterlocks t
    ON t.TripId = ti.TripId

WHERE t.ProcessUnitId IS NOT NULL
  AND i.UnitId <> t.ProcessUnitId;
GO


/* ================================================================
   PART 15
   TEMPORAL SAME-ROW VALIDATION
   ================================================================ */


/* Lifecycle */

SELECT
    COUNT(*) AS InvalidLifecycleDateRangeCount

FROM event.InstrumentLifecycle

WHERE EffectiveTo IS NOT NULL
  AND EffectiveTo < EffectiveFrom;
GO


/* Operational status */

SELECT
    COUNT(*) AS InvalidOperationalStatusDateRangeCount

FROM event.InstrumentOperationalStatusHistory

WHERE EffectiveTo IS NOT NULL
  AND EffectiveTo < EffectiveFrom;
GO


/* Bypass */

SELECT
    COUNT(*) AS InvalidBypassDateRangeCount

FROM event.InstrumentBypassHistory

WHERE BypassEndDateTime IS NOT NULL
  AND BypassEndDateTime < BypassStartDateTime;
GO


/* ================================================================
   PART 16
   TEMPORAL OVERLAP VALIDATION
   ================================================================ */


/* Lifecycle overlap */

SELECT
    COUNT(*) AS LifecycleOverlapCount

FROM event.InstrumentLifecycle a

INNER JOIN event.InstrumentLifecycle b
    ON a.InstrumentId = b.InstrumentId
    AND a.InstrumentLifecycleId < b.InstrumentLifecycleId

WHERE
    a.EffectiveFrom < ISNULL
    (
        b.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    )

AND
    b.EffectiveFrom < ISNULL
    (
        a.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    );
GO


/* Operational status overlap */

SELECT
    COUNT(*) AS OperationalStatusOverlapCount

FROM event.InstrumentOperationalStatusHistory a

INNER JOIN event.InstrumentOperationalStatusHistory b
    ON a.InstrumentId = b.InstrumentId
    AND a.InstrumentOperationalStatusHistoryId
        < b.InstrumentOperationalStatusHistoryId

WHERE
    a.EffectiveFrom < ISNULL
    (
        b.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    )

AND
    b.EffectiveFrom < ISNULL
    (
        a.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    );
GO


/* Bypass overlap */

SELECT
    COUNT(*) AS BypassOverlapCount

FROM event.InstrumentBypassHistory a

INNER JOIN event.InstrumentBypassHistory b
    ON a.InstrumentId = b.InstrumentId
    AND a.InstrumentBypassHistoryId
        < b.InstrumentBypassHistoryId

WHERE
    a.BypassStartDateTime < ISNULL
    (
        b.BypassEndDateTime,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    )

AND
    b.BypassStartDateTime < ISNULL
    (
        a.BypassEndDateTime,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    );
GO


/* ================================================================
   PART 17
   OPEN RECORD COUNTS
   ================================================================ */

SELECT
    COUNT(*) AS OpenLifecycleRecordCount
FROM event.InstrumentLifecycle
WHERE EffectiveTo IS NULL;
GO


SELECT
    COUNT(*) AS OpenOperationalStatusRecordCount
FROM event.InstrumentOperationalStatusHistory
WHERE EffectiveTo IS NULL;
GO


SELECT
    COUNT(*) AS OpenBypassRecordCount
FROM event.InstrumentBypassHistory
WHERE BypassEndDateTime IS NULL;
GO


/* ================================================================
   PART 18
   BUSINESS RULE CHECKS
   ================================================================ */


/* Measurement range */

SELECT
    COUNT(*) AS MeasurementRangeViolationCount

FROM dbo.Instruments

WHERE MeasurementRangeMin IS NOT NULL
  AND MeasurementRangeMax IS NOT NULL
  AND MeasurementRangeMax < MeasurementRangeMin;
GO


/* Output range */

SELECT
    COUNT(*) AS OutputRangeViolationCount

FROM dbo.Instruments

WHERE OutputRangeMin IS NOT NULL
  AND OutputRangeMax IS NOT NULL
  AND OutputRangeMax < OutputRangeMin;
GO


/* SparePartUsage Quantity */

SELECT
    COUNT(*) AS SparePartUsageQuantityViolationCount

FROM event.SparePartUsage

WHERE QuantityUsed <= 0;
GO


/* Calibration Test Sequence */

SELECT
    COUNT(*) AS CalibrationTestSequenceViolationCount

FROM event.CalibrationTestPoints

WHERE TestSequence <= 0;
GO


/* Instrument redundancy self-pair */

SELECT
    COUNT(*) AS InstrumentRedundancySelfPairCount

FROM rel.InstrumentRedundancy

WHERE InstrumentId1 = InstrumentId2;
GO


/* Spare part interchangeability self-pair */

SELECT
    COUNT(*) AS SparePartInterchangeabilitySelfPairCount

FROM rel.SparePartInterchangeability

WHERE SparePartId1 = SparePartId2;
GO


/* ================================================================
   PART 19
   REQUIRED TRIGGER VALIDATION
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredTriggers') IS NOT NULL
    DROP TABLE #RequiredTriggers;
GO

CREATE TABLE #RequiredTriggers
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    TriggerName SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredTriggers
VALUES
(
    'dbo',
    'Instruments',
    'TR_Instruments_TripProcessUnitIntegrity'
),
(
    'dbo',
    'TripsInterlocks',
    'TR_TripsInterlocks_ProcessUnitIntegrity'
),
(
    'rel',
    'TripInstruments',
    'TR_TripInstruments_ProcessUnitIntegrity'
);
GO


SELECT
    rt.SchemaName,
    rt.TableName,
    rt.TriggerName,

    CASE
        WHEN tr.object_id IS NULL
            THEN 'MISSING'

        WHEN tr.is_disabled = 1
            THEN 'DISABLED'

        ELSE 'ENABLED'
    END AS TriggerStatus

FROM #RequiredTriggers rt

LEFT JOIN sys.schemas s
    ON s.name = rt.SchemaName

LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = rt.TableName

LEFT JOIN sys.triggers tr
    ON tr.parent_id = t.object_id
    AND tr.name = rt.TriggerName

ORDER BY
    rt.SchemaName,
    rt.TableName,
    rt.TriggerName;
GO


/* ================================================================
   PART 20
   REQUIRED CHECK CONSTRAINTS
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredChecks') IS NOT NULL
    DROP TABLE #RequiredChecks;
GO

CREATE TABLE #RequiredChecks
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    ConstraintName SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredChecks
VALUES
(
    'dbo',
    'Instruments',
    'CK_Instruments_MeasurementRange'
),
(
    'dbo',
    'Instruments',
    'CK_Instruments_OutputRange'
),
(
    'event',
    'CalibrationTestPoints',
    'CK_CalibrationTestPoints_TestSequence'
),
(
    'event',
    'SparePartUsage',
    'CK_SparePartUsage_QuantityUsed'
),
(
    'rel',
    'InstrumentRedundancy',
    'CK_InstrumentRedundancy_DifferentInstruments'
),
(
    'rel',
    'SparePartInterchangeability',
    'CK_SparePartInterchangeability_DifferentParts'
);
GO


SELECT
    rc.SchemaName,
    rc.TableName,
    rc.ConstraintName,

    CASE
        WHEN cc.object_id IS NULL
            THEN 'MISSING'

        WHEN cc.is_disabled = 1
            THEN 'DISABLED'

        ELSE 'ENABLED'
    END AS ConstraintStatus

FROM #RequiredChecks rc

LEFT JOIN sys.schemas s
    ON s.name = rc.SchemaName

LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = rc.TableName

LEFT JOIN sys.check_constraints cc
    ON cc.parent_object_id = t.object_id
    AND cc.name = rc.ConstraintName

ORDER BY
    rc.SchemaName,
    rc.TableName,
    rc.ConstraintName;
GO


/* ================================================================
   PART 21
   BUSINESS KEY DUPLICATE VALIDATION
   ================================================================ */


/* Instrument TagNumber */

SELECT
    COUNT(*) AS DuplicateInstrumentTagGroups

FROM
(
    SELECT
        TagNumber

    FROM dbo.Instruments

    GROUP BY TagNumber

    HAVING COUNT(*) > 1
) x;
GO


/* InstrumentType Code */

SELECT
    COUNT(*) AS DuplicateInstrumentTypeCodeGroups

FROM
(
    SELECT
        InstrumentTypeCode

    FROM dbo.InstrumentTypes

    GROUP BY InstrumentTypeCode

    HAVING COUNT(*) > 1
) x;
GO


/* Manufacturer Code */

SELECT
    COUNT(*) AS DuplicateManufacturerCodeGroups

FROM
(
    SELECT
        ManufacturerCode

    FROM dbo.Manufacturers

    GROUP BY ManufacturerCode

    HAVING COUNT(*) > 1
) x;
GO


/* Manufacturer Name */

SELECT
    COUNT(*) AS DuplicateManufacturerNameGroups

FROM
(
    SELECT
        ManufacturerName

    FROM dbo.Manufacturers

    GROUP BY ManufacturerName

    HAVING COUNT(*) > 1
) x;
GO


/* SparePart Number */

SELECT
    COUNT(*) AS DuplicateSparePartNumberGroups

FROM
(
    SELECT
        PartNumber

    FROM dbo.SpareParts

    GROUP BY PartNumber

    HAVING COUNT(*) > 1
) x;
GO


/* Trip Code */

SELECT
    COUNT(*) AS DuplicateTripCodeGroups

FROM
(
    SELECT
        TripCode

    FROM dbo.TripsInterlocks

    GROUP BY TripCode

    HAVING COUNT(*) > 1
) x;
GO


/* ================================================================
   PART 22
   FILTERED UNIQUE INDEX VALIDATION
   ================================================================ */

IF OBJECT_ID('tempdb..#RequiredFilteredIndexes') IS NOT NULL
    DROP TABLE #RequiredFilteredIndexes;
GO

CREATE TABLE #RequiredFilteredIndexes
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    IndexName SYSNAME NOT NULL
);
GO

INSERT INTO #RequiredFilteredIndexes
VALUES
(
    'event',
    'InstrumentLifecycle',
    'UX_InstrumentLifecycle_OpenRecord'
),
(
    'event',
    'InstrumentOperationalStatusHistory',
    'UX_InstrumentOperationalStatusHistory_OpenRecord'
),
(
    'event',
    'InstrumentBypassHistory',
    'UX_InstrumentBypassHistory_OpenRecord'
);
GO


SELECT
    rfi.SchemaName,
    rfi.TableName,
    rfi.IndexName,

    CASE
        WHEN i.object_id IS NULL
            THEN 'MISSING'

        WHEN i.is_disabled = 1
            THEN 'DISABLED'

        WHEN i.is_unique = 0
            THEN 'NOT_UNIQUE'

        WHEN i.filter_definition IS NULL
            THEN 'NO_FILTER'

        ELSE 'PRESENT'
    END AS FilteredIndexStatus,

    i.filter_definition AS FilterDefinition

FROM #RequiredFilteredIndexes rfi

LEFT JOIN sys.schemas s
    ON s.name = rfi.SchemaName

LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = rfi.TableName

LEFT JOIN sys.indexes i
    ON i.object_id = t.object_id
    AND i.name = rfi.IndexName

ORDER BY
    rfi.SchemaName,
    rfi.TableName,
    rfi.IndexName;
GO


/* ================================================================
   PART 23
   DISABLED / UNTRUSTED CONSTRAINTS AND FOREIGN KEYS
   ================================================================ */

SELECT
    'FOREIGN_KEY' AS ObjectType,
    s.name AS SchemaName,
    t.name AS TableName,
    fk.name AS ObjectName,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted

FROM sys.foreign_keys fk

INNER JOIN sys.tables t
    ON t.object_id = fk.parent_object_id

INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id

WHERE fk.is_disabled = 1
   OR fk.is_not_trusted = 1

UNION ALL

SELECT
    'CHECK_CONSTRAINT' AS ObjectType,
    s.name AS SchemaName,
    t.name AS TableName,
    cc.name AS ObjectName,
    cc.is_disabled AS IsDisabled,
    cc.is_not_trusted AS IsNotTrusted

FROM sys.check_constraints cc

INNER JOIN sys.tables t
    ON t.object_id = cc.parent_object_id

INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id

WHERE cc.is_disabled = 1
   OR cc.is_not_trusted = 1

ORDER BY
    ObjectType,
    SchemaName,
    TableName,
    ObjectName;
GO


/* ================================================================
   PART 24
   TABLE DATA VOLUME
   ================================================================ */

IF OBJECT_ID('tempdb..#TableVolumes') IS NOT NULL
    DROP TABLE #TableVolumes;
GO

CREATE TABLE #TableVolumes
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,
    RowCountValue BIGINT NOT NULL
);
GO


INSERT INTO #TableVolumes
(
    SchemaName,
    TableName,
    RowCountValue
)
SELECT
    s.name,
    t.name,
    SUM(p.rows)

FROM sys.tables t

INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id

INNER JOIN sys.partitions p
    ON p.object_id = t.object_id
    AND p.index_id IN (0,1)

GROUP BY
    s.name,
    t.name;
GO


SELECT
    SchemaName,
    TableName,
    RowCountValue
FROM #TableVolumes
ORDER BY
    SchemaName,
    TableName;
GO


/* ================================================================
   PART 25
   STRUCTURAL SUMMARY
   ================================================================ */

DECLARE @TotalTables INT;
DECLARE @TotalForeignKeys INT;
DECLARE @TotalIndexes INT;
DECLARE @TotalTriggers INT;
DECLARE @TotalCheckConstraints INT;

SELECT
    @TotalTables = COUNT(*)
FROM sys.tables;

SELECT
    @TotalForeignKeys = COUNT(*)
FROM sys.foreign_keys;

SELECT
    @TotalIndexes = COUNT(*)
FROM sys.indexes
WHERE index_id > 0;

SELECT
    @TotalTriggers = COUNT(*)
FROM sys.triggers
WHERE parent_class = 1;

SELECT
    @TotalCheckConstraints = COUNT(*)
FROM sys.check_constraints;


SELECT
    @TotalTables AS TotalTables,
    @TotalForeignKeys AS TotalForeignKeys,
    @TotalIndexes AS TotalIndexes,
    @TotalTriggers AS TotalTableTriggers,
    @TotalCheckConstraints AS TotalCheckConstraints;
GO


/* ================================================================
   PART 26
   FINAL INTEGRITY SUMMARY

   All values are calculated independently first.
   No aggregate contains a subquery.
   ================================================================ */

DECLARE
    @MissingSchemaCount INT,
    @MissingTableCount INT,
    @UnhealthyFKCount INT,
    @OrphanInstrumentCount INT,
    @PreviousFailureViolationCount INT,
    @InventoryTransactionViolationCount INT,
    @StatusFailureViolationCount INT,
    @StatusMaintenanceViolationCount INT,
    @UsageMaintenanceViolationCount INT,
    @UsageFailureViolationCount INT,
    @TripProcessUnitViolationCount INT,
    @LifecycleDateViolationCount INT,
    @OperationalDateViolationCount INT,
    @BypassDateViolationCount INT,
    @LifecycleOverlapCount INT,
    @OperationalOverlapCount INT,
    @BypassOverlapCount INT,
    @MeasurementRangeViolationCount INT,
    @OutputRangeViolationCount INT,
    @QuantityViolationCount INT,
    @TestSequenceViolationCount INT,
    @RedundancySelfPairCount INT,
    @InterchangeabilitySelfPairCount INT,
    @DisabledOrUntrustedCount INT;


/* Schemas */

SELECT
    @MissingSchemaCount = COUNT(*)

FROM #RequiredSchemas rs

LEFT JOIN sys.schemas s
    ON s.name = rs.SchemaName

WHERE s.schema_id IS NULL;


/* Tables */

SELECT
    @MissingTableCount = COUNT(*)

FROM #RequiredTables rt

LEFT JOIN sys.schemas s
    ON s.name = rt.SchemaName

LEFT JOIN sys.tables t
    ON t.schema_id = s.schema_id
    AND t.name = rt.TableName

WHERE t.object_id IS NULL;


/* FK health */

SELECT
    @UnhealthyFKCount = COUNT(*)

FROM sys.foreign_keys

WHERE is_disabled = 1
   OR is_not_trusted = 1;


/* Orphan / cross-table checks */

SELECT
    @OrphanInstrumentCount = COUNT(*)

FROM dbo.Instruments i

INNER JOIN dbo.SubSystems ss
    ON ss.SubSystemId = i.SubSystemId

WHERE i.SubSystemId IS NOT NULL
  AND ss.UnitId <> i.UnitId;


SELECT
    @PreviousFailureViolationCount = COUNT(*)

FROM event.FailureRecords f

INNER JOIN event.FailureRecords pf
    ON pf.FailureId = f.PreviousFailureId

WHERE f.PreviousFailureId IS NOT NULL
  AND pf.InstrumentId <> f.InstrumentId;


SELECT
    @InventoryTransactionViolationCount = COUNT(*)

FROM event.SparePartUsage u

INNER JOIN inv.InventoryTransactions it
    ON it.InventoryTransactionId = u.InventoryTransactionId

WHERE it.SparePartId <> u.SparePartId;


SELECT
    @StatusFailureViolationCount = COUNT(*)

FROM event.InstrumentOperationalStatusHistory sh

INNER JOIN event.FailureRecords f
    ON f.FailureId = sh.FailureId

WHERE sh.FailureId IS NOT NULL
  AND f.InstrumentId <> sh.InstrumentId;


SELECT
    @StatusMaintenanceViolationCount = COUNT(*)

FROM event.InstrumentOperationalStatusHistory sh

INNER JOIN event.MaintenanceRecords m
    ON m.MaintenanceId = sh.MaintenanceId

WHERE sh.MaintenanceId IS NOT NULL
  AND m.InstrumentId <> sh.InstrumentId;


SELECT
    @UsageMaintenanceViolationCount = COUNT(*)

FROM event.SparePartUsage u

INNER JOIN event.MaintenanceRecords m
    ON m.MaintenanceId = u.MaintenanceId

WHERE u.MaintenanceId IS NOT NULL
  AND u.InstrumentId IS NOT NULL
  AND m.InstrumentId <> u.InstrumentId;


SELECT
    @UsageFailureViolationCount = COUNT(*)

FROM event.SparePartUsage u

INNER JOIN event.FailureRecords f
    ON f.FailureId = u.FailureId

WHERE u.FailureId IS NOT NULL
  AND u.InstrumentId IS NOT NULL
  AND f.InstrumentId <> u.InstrumentId;


SELECT
    @TripProcessUnitViolationCount = COUNT(*)

FROM rel.TripInstruments ti

INNER JOIN dbo.Instruments i
    ON i.InstrumentId = ti.InstrumentId

INNER JOIN dbo.TripsInterlocks t
    ON t.TripId = ti.TripId

WHERE t.ProcessUnitId IS NOT NULL
  AND i.UnitId <> t.ProcessUnitId;


/* Temporal */

SELECT
    @LifecycleDateViolationCount = COUNT(*)
FROM event.InstrumentLifecycle
WHERE EffectiveTo IS NOT NULL
  AND EffectiveTo < EffectiveFrom;


SELECT
    @OperationalDateViolationCount = COUNT(*)
FROM event.InstrumentOperationalStatusHistory
WHERE EffectiveTo IS NOT NULL
  AND EffectiveTo < EffectiveFrom;


SELECT
    @BypassDateViolationCount = COUNT(*)
FROM event.InstrumentBypassHistory
WHERE BypassEndDateTime IS NOT NULL
  AND BypassEndDateTime < BypassStartDateTime;


SELECT
    @LifecycleOverlapCount = COUNT(*)

FROM event.InstrumentLifecycle a

INNER JOIN event.InstrumentLifecycle b
    ON a.InstrumentId = b.InstrumentId
    AND a.InstrumentLifecycleId < b.InstrumentLifecycleId

WHERE
    a.EffectiveFrom < ISNULL
    (
        b.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    )
AND
    b.EffectiveFrom < ISNULL
    (
        a.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    );


SELECT
    @OperationalOverlapCount = COUNT(*)

FROM event.InstrumentOperationalStatusHistory a

INNER JOIN event.InstrumentOperationalStatusHistory b
    ON a.InstrumentId = b.InstrumentId
    AND a.InstrumentOperationalStatusHistoryId
        < b.InstrumentOperationalStatusHistoryId

WHERE
    a.EffectiveFrom < ISNULL
    (
        b.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    )
AND
    b.EffectiveFrom < ISNULL
    (
        a.EffectiveTo,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    );


SELECT
    @BypassOverlapCount = COUNT(*)

FROM event.InstrumentBypassHistory a

INNER JOIN event.InstrumentBypassHistory b
    ON a.InstrumentId = b.InstrumentId
    AND a.InstrumentBypassHistoryId
        < b.InstrumentBypassHistoryId

WHERE
    a.BypassStartDateTime < ISNULL
    (
        b.BypassEndDateTime,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    )
AND
    b.BypassStartDateTime < ISNULL
    (
        a.BypassEndDateTime,
        CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
    );


/* Business rules */

SELECT
    @MeasurementRangeViolationCount = COUNT(*)
FROM dbo.Instruments
WHERE MeasurementRangeMin IS NOT NULL
  AND MeasurementRangeMax IS NOT NULL
  AND MeasurementRangeMax < MeasurementRangeMin;


SELECT
    @OutputRangeViolationCount = COUNT(*)
FROM dbo.Instruments
WHERE OutputRangeMin IS NOT NULL
  AND OutputRangeMax IS NOT NULL
  AND OutputRangeMax < OutputRangeMin;


SELECT
    @QuantityViolationCount = COUNT(*)
FROM event.SparePartUsage
WHERE QuantityUsed <= 0;


SELECT
    @TestSequenceViolationCount = COUNT(*)
FROM event.CalibrationTestPoints
WHERE TestSequence <= 0;


SELECT
    @RedundancySelfPairCount = COUNT(*)
FROM rel.InstrumentRedundancy
WHERE InstrumentId1 = InstrumentId2;


SELECT
    @InterchangeabilitySelfPairCount = COUNT(*)
FROM rel.SparePartInterchangeability
WHERE SparePartId1 = SparePartId2;


/* Disabled / untrusted */

SELECT
    @DisabledOrUntrustedCount =
        (
            SELECT COUNT(*)
            FROM sys.foreign_keys
            WHERE is_disabled = 1
               OR is_not_trusted = 1
        )
        +
        (
            SELECT COUNT(*)
            FROM sys.check_constraints
            WHERE is_disabled = 1
               OR is_not_trusted = 1
        );


/* Final result */

SELECT

    @MissingSchemaCount
        AS MissingSchemaCount,

    @MissingTableCount
        AS MissingTableCount,

    @UnhealthyFKCount
        AS UnhealthyForeignKeyCount,

    @OrphanInstrumentCount
        AS InstrumentHierarchyViolationCount,

    @PreviousFailureViolationCount
        AS PreviousFailureViolationCount,

    @InventoryTransactionViolationCount
        AS InventoryTransactionSparePartViolationCount,

    @StatusFailureViolationCount
        AS StatusFailureInstrumentViolationCount,

    @StatusMaintenanceViolationCount
        AS StatusMaintenanceInstrumentViolationCount,

    @UsageMaintenanceViolationCount
        AS SpareUsageMaintenanceInstrumentViolationCount,

    @UsageFailureViolationCount
        AS SpareUsageFailureInstrumentViolationCount,

    @TripProcessUnitViolationCount
        AS TripProcessUnitViolationCount,

    @LifecycleDateViolationCount
        AS LifecycleDateViolationCount,

    @OperationalDateViolationCount
        AS OperationalStatusDateViolationCount,

    @BypassDateViolationCount
        AS BypassDateViolationCount,

    @LifecycleOverlapCount
        AS LifecycleOverlapCount,

    @OperationalOverlapCount
        AS OperationalStatusOverlapCount,

    @BypassOverlapCount
        AS BypassOverlapCount,

    @MeasurementRangeViolationCount
        AS MeasurementRangeViolationCount,

    @OutputRangeViolationCount
        AS OutputRangeViolationCount,

    @QuantityViolationCount
        AS SparePartUsageQuantityViolationCount,

    @TestSequenceViolationCount
        AS CalibrationTestSequenceViolationCount,

    @RedundancySelfPairCount
        AS InstrumentRedundancySelfPairCount,

    @InterchangeabilitySelfPairCount
        AS SparePartInterchangeabilitySelfPairCount,

    @DisabledOrUntrustedCount
        AS DisabledOrUntrustedObjectCount;
GO


/* ================================================================
   PART 27
   FINAL DECISION
   ================================================================ */

DECLARE
    @FinalStatus VARCHAR(30);


/*
   Structural failure conditions
*/

IF EXISTS
(
    SELECT 1
    FROM #RequiredSchemas rs
    LEFT JOIN sys.schemas s
        ON s.name = rs.SchemaName
    WHERE s.schema_id IS NULL
)
OR EXISTS
(
    SELECT 1
    FROM #RequiredTables rt
    LEFT JOIN sys.schemas s
        ON s.name = rt.SchemaName
    LEFT JOIN sys.tables t
        ON t.schema_id = s.schema_id
        AND t.name = rt.TableName
    WHERE t.object_id IS NULL
)
OR EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE is_disabled = 1
       OR is_not_trusted = 1
)
OR EXISTS
(
    SELECT 1
    FROM dbo.Instruments i
    INNER JOIN dbo.SubSystems ss
        ON ss.SubSystemId = i.SubSystemId
    WHERE i.SubSystemId IS NOT NULL
      AND ss.UnitId <> i.UnitId
)
OR EXISTS
(
    SELECT 1
    FROM event.FailureRecords f
    INNER JOIN event.FailureRecords pf
        ON pf.FailureId = f.PreviousFailureId
    WHERE f.PreviousFailureId IS NOT NULL
      AND pf.InstrumentId <> f.InstrumentId
)
OR EXISTS
(
    SELECT 1
    FROM event.SparePartUsage u
    INNER JOIN inv.InventoryTransactions it
        ON it.InventoryTransactionId = u.InventoryTransactionId
    WHERE it.SparePartId <> u.SparePartId
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentOperationalStatusHistory sh
    INNER JOIN event.FailureRecords f
        ON f.FailureId = sh.FailureId
    WHERE sh.FailureId IS NOT NULL
      AND f.InstrumentId <> sh.InstrumentId
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentOperationalStatusHistory sh
    INNER JOIN event.MaintenanceRecords m
        ON m.MaintenanceId = sh.MaintenanceId
    WHERE sh.MaintenanceId IS NOT NULL
      AND m.InstrumentId <> sh.InstrumentId
)
OR EXISTS
(
    SELECT 1
    FROM event.SparePartUsage u
    INNER JOIN event.MaintenanceRecords m
        ON m.MaintenanceId = u.MaintenanceId
    WHERE u.MaintenanceId IS NOT NULL
      AND u.InstrumentId IS NOT NULL
      AND m.InstrumentId <> u.InstrumentId
)
OR EXISTS
(
    SELECT 1
    FROM event.SparePartUsage u
    INNER JOIN event.FailureRecords f
        ON f.FailureId = u.FailureId
    WHERE u.FailureId IS NOT NULL
      AND u.InstrumentId IS NOT NULL
      AND f.InstrumentId <> u.InstrumentId
)
OR EXISTS
(
    SELECT 1
    FROM rel.TripInstruments ti
    INNER JOIN dbo.Instruments i
        ON i.InstrumentId = ti.InstrumentId
    INNER JOIN dbo.TripsInterlocks t
        ON t.TripId = ti.TripId
    WHERE t.ProcessUnitId IS NOT NULL
      AND i.UnitId <> t.ProcessUnitId
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentLifecycle
    WHERE EffectiveTo IS NOT NULL
      AND EffectiveTo < EffectiveFrom
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentOperationalStatusHistory
    WHERE EffectiveTo IS NOT NULL
      AND EffectiveTo < EffectiveFrom
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentBypassHistory
    WHERE BypassEndDateTime IS NOT NULL
      AND BypassEndDateTime < BypassStartDateTime
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentLifecycle a
    INNER JOIN event.InstrumentLifecycle b
        ON a.InstrumentId = b.InstrumentId
        AND a.InstrumentLifecycleId < b.InstrumentLifecycleId
    WHERE
        a.EffectiveFrom < ISNULL
        (
            b.EffectiveTo,
            CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
        )
        AND
        b.EffectiveFrom < ISNULL
        (
            a.EffectiveTo,
            CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
        )
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentOperationalStatusHistory a
    INNER JOIN event.InstrumentOperationalStatusHistory b
        ON a.InstrumentId = b.InstrumentId
        AND a.InstrumentOperationalStatusHistoryId
            < b.InstrumentOperationalStatusHistoryId
    WHERE
        a.EffectiveFrom < ISNULL
        (
            b.EffectiveTo,
            CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
        )
        AND
        b.EffectiveFrom < ISNULL
        (
            a.EffectiveTo,
            CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
        )
)
OR EXISTS
(
    SELECT 1
    FROM event.InstrumentBypassHistory a
    INNER JOIN event.InstrumentBypassHistory b
        ON a.InstrumentId = b.InstrumentId
        AND a.InstrumentBypassHistoryId
            < b.InstrumentBypassHistoryId
    WHERE
        a.BypassStartDateTime < ISNULL
        (
            b.BypassEndDateTime,
            CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
        )
        AND
        b.BypassStartDateTime < ISNULL
        (
            a.BypassEndDateTime,
            CONVERT(datetime2(6),'9999-12-31 23:59:59.999999')
        )
)
OR EXISTS
(
    SELECT 1
    FROM dbo.Instruments
    WHERE MeasurementRangeMin IS NOT NULL
      AND MeasurementRangeMax IS NOT NULL
      AND MeasurementRangeMax < MeasurementRangeMin
)
OR EXISTS
(
    SELECT 1
    FROM dbo.Instruments
    WHERE OutputRangeMin IS NOT NULL
      AND OutputRangeMax IS NOT NULL
      AND OutputRangeMax < OutputRangeMin
)
OR EXISTS
(
    SELECT 1
    FROM event.SparePartUsage
    WHERE QuantityUsed <= 0
)
OR EXISTS
(
    SELECT 1
    FROM event.CalibrationTestPoints
    WHERE TestSequence <= 0
)
OR EXISTS
(
    SELECT 1
    FROM rel.InstrumentRedundancy
    WHERE InstrumentId1 = InstrumentId2
)
OR EXISTS
(
    SELECT 1
    FROM rel.SparePartInterchangeability
    WHERE SparePartId1 = SparePartId2
)
BEGIN

    SET @FinalStatus = 'FAIL';

END
ELSE
BEGIN

    SET @FinalStatus = 'PASS';

END;


SELECT
    @FinalStatus AS PHASE_10_8_PREINDEX_STATUS;
GO


/* ================================================================
   END OF PHASE 10.8 PRE-INDEX VALIDATION
   ================================================================ */