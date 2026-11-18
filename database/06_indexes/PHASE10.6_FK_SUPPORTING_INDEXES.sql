USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   PHASE 10.6
   FOREIGN KEY SUPPORTING INDEXES

   Purpose:
   - Inspect all actual Foreign Keys
   - Inspect all actual indexes
   - Detect whether each FK has a supporting index
   - Create only missing supporting indexes
   - Avoid duplicate / redundant FK indexes

   Important:
   - This script is metadata-driven.
   - It does NOT rely on a hard-coded FK list.
   - It does NOT create indexes on parent tables.
   - It evaluates indexes on the CHILD side of each FK.
   ============================================================ */


/* ============================================================
   10.6.1 PREFLIGHT
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.6 — PREFLIGHT';
PRINT '============================================================';

IF DB_NAME() <> N'ComprehensiveInstrumentationDB_New'
BEGIN
    THROW 51100,
          'Phase 10.6 must be executed in ComprehensiveInstrumentationDB_New.',
          1;
END;

PRINT 'Database check passed.';
PRINT '';


/* ============================================================
   10.6.2 FOREIGN KEY INVENTORY
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.6 — FOREIGN KEY INVENTORY';
PRINT '============================================================';

SELECT
    fk.object_id AS ForeignKeyObjectId,
    SCHEMA_NAME(childTable.schema_id) AS ChildSchema,
    childTable.name AS ChildTable,
    fk.name AS ForeignKeyName,
    SCHEMA_NAME(parentTable.schema_id) AS ParentSchema,
    parentTable.name AS ParentTable,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS childTable
    ON fk.parent_object_id = childTable.object_id
INNER JOIN sys.tables AS parentTable
    ON fk.referenced_object_id = parentTable.object_id
ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName;
GO


/* ============================================================
   10.6.3 BUILD ACTUAL FK METADATA
   ============================================================ */

IF OBJECT_ID('tempdb..#FKColumns') IS NOT NULL
    DROP TABLE #FKColumns;

CREATE TABLE #FKColumns
(
    ForeignKeyObjectId INT NOT NULL,
    ForeignKeyName SYSNAME NOT NULL,
    ChildSchema SYSNAME NOT NULL,
    ChildTable SYSNAME NOT NULL,
    ParentSchema SYSNAME NOT NULL,
    ParentTable SYSNAME NOT NULL,
    ColumnOrdinal INT NOT NULL,
    ChildColumn SYSNAME NOT NULL
);

INSERT INTO #FKColumns
(
    ForeignKeyObjectId,
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    ColumnOrdinal,
    ChildColumn
)
SELECT
    fk.object_id,
    fk.name,
    childSchema.name,
    childTable.name,
    parentSchema.name,
    parentTable.name,
    fkc.constraint_column_id,
    childColumn.name
FROM sys.foreign_keys AS fk

INNER JOIN sys.tables AS childTable
    ON fk.parent_object_id = childTable.object_id

INNER JOIN sys.schemas AS childSchema
    ON childTable.schema_id = childSchema.schema_id

INNER JOIN sys.tables AS parentTable
    ON fk.referenced_object_id = parentTable.object_id

INNER JOIN sys.schemas AS parentSchema
    ON parentTable.schema_id = parentSchema.schema_id

INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id

INNER JOIN sys.columns AS childColumn
    ON fkc.parent_object_id = childColumn.object_id
   AND fkc.parent_column_id = childColumn.column_id;


/* ============================================================
   10.6.4 CREATE FK SIGNATURES
   ============================================================ */

IF OBJECT_ID('tempdb..#FKSignatures') IS NOT NULL
    DROP TABLE #FKSignatures;

SELECT
    ForeignKeyObjectId,
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    STRING_AGG(
        QUOTENAME(ChildColumn),
        N','
    ) WITHIN GROUP
    (
        ORDER BY ColumnOrdinal
    ) AS FKColumnSignature,
    COUNT(*) AS FKColumnCount
INTO #FKSignatures
FROM #FKColumns
GROUP BY
    ForeignKeyObjectId,
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable;
GO


/* ============================================================
   10.6.5 DISPLAY ACTUAL FK COLUMN STRUCTURE
   ============================================================ */

PRINT '============================================================';
PRINT 'PHASE 10.6 — FK COLUMN STRUCTURE';
PRINT '============================================================';

SELECT
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    FKColumnCount,
    FKColumnSignature
FROM #FKSignatures
ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName;
GO


/* ============================================================
   10.6.6 FIND EXISTING INDEX SUPPORT
   ============================================================

   Definition of supporting index:

   The CHILD table must have an enabled index whose first
   N KEY columns exactly match the FK columns in FK order.

   Example:

       FK = (MaintenanceId, InstrumentId)

   Supporting index:

       (MaintenanceId, InstrumentId)

   Also acceptable:

       (MaintenanceId, InstrumentId, OtherColumn)

   Not sufficient:

       (InstrumentId, MaintenanceId)

   because the FK column sequence is different.
   ============================================================ */

IF OBJECT_ID('tempdb..#FKSupportAnalysis') IS NOT NULL
    DROP TABLE #FKSupportAnalysis;

CREATE TABLE #FKSupportAnalysis
(
    ForeignKeyObjectId INT NOT NULL,
    ForeignKeyName SYSNAME NOT NULL,
    ChildSchema SYSNAME NOT NULL,
    ChildTable SYSNAME NOT NULL,
    ParentSchema SYSNAME NOT NULL,
    ParentTable SYSNAME NOT NULL,
    FKColumnCount INT NOT NULL,
    FKColumnSignature NVARCHAR(MAX) NOT NULL,
    SupportingIndexName SYSNAME NULL,
    SupportingIndexType NVARCHAR(60) NULL,
    SupportingIndexIsUnique BIT NULL,
    SupportingIndexIsClustered BIT NULL,
    SupportingIndexIsDisabled BIT NULL
);


/* ------------------------------------------------------------
   Cursor through actual FK definitions
   ------------------------------------------------------------ */

DECLARE
    @FKObjectId INT,
    @FKName SYSNAME,
    @ChildSchema SYSNAME,
    @ChildTable SYSNAME,
    @ParentSchema SYSNAME,
    @ParentTable SYSNAME,
    @FKColumnCount INT,
    @FKColumnSignature NVARCHAR(MAX);

DECLARE FKCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT
    ForeignKeyObjectId,
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    FKColumnCount,
    FKColumnSignature
FROM #FKSignatures
ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName;

OPEN FKCursor;

FETCH NEXT FROM FKCursor INTO
    @FKObjectId,
    @FKName,
    @ChildSchema,
    @ChildTable,
    @ParentSchema,
    @ParentTable,
    @FKColumnCount,
    @FKColumnSignature;

WHILE @@FETCH_STATUS = 0
BEGIN

    DECLARE
        @ChildObjectId INT,
        @SupportingIndexName SYSNAME = NULL,
        @SupportingIndexType NVARCHAR(60) = NULL,
        @SupportingIndexIsUnique BIT = NULL,
        @SupportingIndexIsClustered BIT = NULL,
        @SupportingIndexIsDisabled BIT = NULL;

    SELECT
        @ChildObjectId = OBJECT_ID(
            QUOTENAME(@ChildSchema) + N'.' + QUOTENAME(@ChildTable)
        );


    /* --------------------------------------------------------
       Find first enabled index whose leading key columns
       exactly match the FK column sequence.
       -------------------------------------------------------- */

    SELECT TOP (1)
    @SupportingIndexName = i.name,
    @SupportingIndexType = i.type_desc,
    @SupportingIndexIsUnique = i.is_unique,
    @SupportingIndexIsClustered =
        CASE
            WHEN i.index_id = 1 THEN 1
            ELSE 0
        END,
    @SupportingIndexIsDisabled = i.is_disabled
    FROM sys.indexes AS i
    WHERE
        i.object_id = @ChildObjectId
        AND i.index_id > 0
        AND i.is_disabled = 0
        AND i.has_filter = 0
        AND
        (
            SELECT