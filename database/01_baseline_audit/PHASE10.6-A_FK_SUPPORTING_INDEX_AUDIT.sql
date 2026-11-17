USE ComprehensiveInstrumentationDB_New;
GO

SET NOCOUNT ON;
GO

/* ============================================================
   PHASE 10.6-A
   FK Supporting Index Audit
   ------------------------------------------------------------
   Purpose:
       Identify Foreign Keys and determine whether their
       child-side columns are supported by an appropriate
       existing index.

   IMPORTANT:
       This script is READ-ONLY.
       It does NOT create, alter, or drop any database object.

   Database:
       ComprehensiveInstrumentationDB_New
   ============================================================ */


/* ============================================================
   PART 0 — Environment / Database Check
   ============================================================ */

SELECT
    DB_NAME() AS CurrentDatabase,
    SUSER_SNAME() AS CurrentLogin,
    GETDATE() AS AuditDateTime;


/* ============================================================
   PART 1 — Extract Foreign Key Column Structure
   ------------------------------------------------------------
   One row per FK column.
   Composite FKs therefore produce multiple rows.
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

    ChildColumn SYSNAME NOT NULL,
    ParentColumn SYSNAME NOT NULL
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
    ChildColumn,
    ParentColumn
)
SELECT
    fk.object_id AS ForeignKeyObjectId,
    fk.name AS ForeignKeyName,

    cs.name AS ChildSchema,
    ct.name AS ChildTable,

    ps.name AS ParentSchema,
    pt.name AS ParentTable,

    fkc.constraint_column_id AS ColumnOrdinal,

    cc.name AS ChildColumn,
    pc.name AS ParentColumn

FROM sys.foreign_keys AS fk

INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id

INNER JOIN sys.tables AS ct
    ON fk.parent_object_id = ct.object_id

INNER JOIN sys.schemas AS cs
    ON ct.schema_id = cs.schema_id

INNER JOIN sys.tables AS pt
    ON fk.referenced_object_id = pt.object_id

INNER JOIN sys.schemas AS ps
    ON pt.schema_id = ps.schema_id

INNER JOIN sys.columns AS cc
    ON fkc.parent_object_id = cc.object_id
   AND fkc.parent_column_id = cc.column_id

INNER JOIN sys.columns AS pc
    ON fkc.referenced_object_id = pc.object_id
   AND fkc.referenced_column_id = pc.column_id;


/* ============================================================
   PART 1-A — Foreign Key Inventory
   ============================================================ */

SELECT
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    COUNT(*) AS FKColumnCount
FROM #FKColumns
GROUP BY
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable
ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName;


/* ============================================================
   PART 1-B — Foreign Key Columns
   ============================================================ */

SELECT
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    ColumnOrdinal,
    ChildColumn,
    ParentColumn
FROM #FKColumns
ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName,
    ColumnOrdinal;


/* ============================================================
   PART 2 — Existing Index Structure
   ------------------------------------------------------------
   Returns key columns only.

   Included columns are intentionally excluded from the
   supporting-index determination because SQL Server uses
   index key columns for FK seek support.
   ============================================================ */

IF OBJECT_ID('tempdb..#IndexColumns') IS NOT NULL
    DROP TABLE #IndexColumns;


CREATE TABLE #IndexColumns
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,

    IndexId INT NOT NULL,
    IndexName SYSNAME NULL,

    IndexTypeDesc NVARCHAR(60) NOT NULL,

    IsUnique BIT NOT NULL,
    IsPrimaryKey BIT NOT NULL,
    IsUniqueConstraint BIT NOT NULL,
    IsDisabled BIT NOT NULL,

    KeyOrdinal INT NOT NULL,
    ColumnName SYSNAME NOT NULL
);


INSERT INTO #IndexColumns
(
    SchemaName,
    TableName,
    IndexId,
    IndexName,
    IndexTypeDesc,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,
    KeyOrdinal,
    ColumnName
)
SELECT
    s.name AS SchemaName,
    t.name AS TableName,

    i.index_id AS IndexId,
    i.name AS IndexName,

    i.type_desc AS IndexTypeDesc,

    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique_constraint AS IsUniqueConstraint,
    i.is_disabled AS IsDisabled,

    ic.key_ordinal AS KeyOrdinal,
    c.name AS ColumnName

FROM sys.indexes AS i

INNER JOIN sys.tables AS t
    ON i.object_id = t.object_id

INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id

INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
   AND i.index_id = ic.index_id

INNER JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id

WHERE
    i.index_id > 0
    AND ic.key_ordinal > 0;


/* ============================================================
   PART 2-A — Existing Index Inventory
   ============================================================ */

SELECT
    SchemaName,
    TableName,
    IndexId,
    IndexName,
    IndexTypeDesc,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,

    COUNT(*) AS KeyColumnCount
FROM #IndexColumns
GROUP BY
    SchemaName,
    TableName,
    IndexId,
    IndexName,
    IndexTypeDesc,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled
ORDER BY
    SchemaName,
    TableName,
    IndexId;


/* ============================================================
   PART 2-B — Existing Index Key Columns
   ============================================================ */

SELECT
    SchemaName,
    TableName,
    IndexId,
    IndexName,
    IndexTypeDesc,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,

    KeyOrdinal,
    ColumnName
FROM #IndexColumns
ORDER BY
    SchemaName,
    TableName,
    IndexId,
    KeyOrdinal;


/* ============================================================
   PART 3 — FK / Index Comparison
   ------------------------------------------------------------
   This section identifies whether an existing index begins
   with the complete FK column sequence.

   Example:

       FK:
           (MaintenanceId, InstrumentId)

       Index:
           (MaintenanceId, InstrumentId, ...)
           
   Result:
       Supported

   But:

       FK:
           (MaintenanceId, InstrumentId)

       Index:
           (InstrumentId, MaintenanceId)

   Result:
       Not supported as a left-prefix match.

   This distinction is important for composite FKs.
   ============================================================ */

IF OBJECT_ID('tempdb..#FKDefinitions') IS NOT NULL
    DROP TABLE #FKDefinitions;


CREATE TABLE #FKDefinitions
(
    ForeignKeyObjectId INT NOT NULL,
    ForeignKeyName SYSNAME NOT NULL,

    ChildSchema SYSNAME NOT NULL,
    ChildTable SYSNAME NOT NULL,

    ParentSchema SYSNAME NOT NULL,
    ParentTable SYSNAME NOT NULL,

    FKColumnCount INT NOT NULL,

    FKColumnList NVARCHAR(MAX) NOT NULL
);


INSERT INTO #FKDefinitions
(
    ForeignKeyObjectId,
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable,
    FKColumnCount,
    FKColumnList
)
SELECT
    ForeignKeyObjectId,
    ForeignKeyName,

    ChildSchema,
    ChildTable,

    ParentSchema,
    ParentTable,

    COUNT(*) AS FKColumnCount,

    STRING_AGG(
        CAST(QUOTENAME(ChildColumn) AS NVARCHAR(MAX)),
        N', '
    ) WITHIN GROUP
    (
        ORDER BY ColumnOrdinal
    ) AS FKColumnList

FROM #FKColumns

GROUP BY
    ForeignKeyObjectId,
    ForeignKeyName,
    ChildSchema,
    ChildTable,
    ParentSchema,
    ParentTable;


/* ============================================================
   PART 3-A — Compare FK Against Existing Indexes
   ============================================================ */

IF OBJECT_ID('tempdb..#IndexDefinitions') IS NOT NULL
    DROP TABLE #IndexDefinitions;


CREATE TABLE #IndexDefinitions
(
    SchemaName SYSNAME NOT NULL,
    TableName SYSNAME NOT NULL,

    IndexId INT NOT NULL,
    IndexName SYSNAME NULL,

    IndexTypeDesc NVARCHAR(60) NOT NULL,

    IsUnique BIT NOT NULL,
    IsPrimaryKey BIT NOT NULL,
    IsUniqueConstraint BIT NOT NULL,
    IsDisabled BIT NOT NULL,

    KeyColumnCount INT NOT NULL,

    KeyColumnList NVARCHAR(MAX) NOT NULL
);


INSERT INTO #IndexDefinitions
(
    SchemaName,
    TableName,
    IndexId,
    IndexName,
    IndexTypeDesc,
    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,
    KeyColumnCount,
    KeyColumnList
)
SELECT
    SchemaName,
    TableName,

    IndexId,
    IndexName,

    IndexTypeDesc,

    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled,

    COUNT(*) AS KeyColumnCount,

    STRING_AGG(
        CAST(QUOTENAME(ColumnName) AS NVARCHAR(MAX)),
        N', '
    ) WITHIN GROUP
    (
        ORDER BY KeyOrdinal
    ) AS KeyColumnList

FROM #IndexColumns

GROUP BY
    SchemaName,
    TableName,

    IndexId,
    IndexName,

    IndexTypeDesc,

    IsUnique,
    IsPrimaryKey,
    IsUniqueConstraint,
    IsDisabled;


/* ============================================================
   PART 3-B — Detailed FK / Index Audit
   ------------------------------------------------------------
   The comparison is based on exact left-prefix matching.

   Example:

       FK columns:
           [InstrumentId]

       Index:
           [InstrumentId], [FailureDateTime]

       => SUPPORTED

   Example:

       FK columns:
           [MaintenanceId], [InstrumentId]

       Index:
           [MaintenanceId], [InstrumentId], [SomethingElse]

       => SUPPORTED

   Example:

       FK columns:
           [MaintenanceId], [InstrumentId]

       Index:
           [InstrumentId], [MaintenanceId]

       => NOT SUPPORTED
   ============================================================ */

SELECT
    fk.ForeignKeyName,

    fk.ChildSchema,
    fk.ChildTable,

    fk.ParentSchema,
    fk.ParentTable,

    fk.FKColumnCount,
    fk.FKColumnList,

    ix.IndexName,
    ix.IndexId,
    ix.IndexTypeDesc,

    ix.IsUnique,
    ix.IsPrimaryKey,
    ix.IsUniqueConstraint,
    ix.IsDisabled,

    ix.KeyColumnCount,
    ix.KeyColumnList,

    CASE
        WHEN ix.IndexId IS NULL
            THEN 'NO_INDEX_ON_FK_COLUMNS'

        WHEN ix.IsDisabled = 1
            THEN 'INDEX_DISABLED'

        WHEN ix.KeyColumnCount < fk.FKColumnCount
            THEN 'INDEX_TOO_SHORT'

        ELSE
            CASE
                WHEN
                    NOT EXISTS
                    (
                        SELECT 1
                        FROM #FKColumns AS f
                        WHERE
                            f.ForeignKeyObjectId = fk.ForeignKeyObjectId
                            AND
                            (
                                SELECT COUNT(*)
                                FROM #FKColumns AS f2
                                WHERE
                                    f2.ForeignKeyObjectId = f.ForeignKeyObjectId
                                    AND
                                    f2.ColumnOrdinal <= f.ColumnOrdinal
                            )
                            <= fk.FKColumnCount
                            AND
                            NOT EXISTS
                            (
                                SELECT 1
                                FROM #IndexColumns AS i2
                                WHERE
                                    i2.SchemaName = fk.ChildSchema
                                    AND i2.TableName = fk.ChildTable
                                    AND i2.IndexId = ix.IndexId
                                    AND i2.KeyOrdinal = f.ColumnOrdinal
                                    AND i2.ColumnName = f.ChildColumn
                            )
                    )
                THEN 'SUPPORTED'
                ELSE 'NOT_SUPPORTED'
            END
    END AS AuditStatus

FROM #FKDefinitions AS fk

LEFT JOIN #IndexDefinitions AS ix
    ON ix.SchemaName = fk.ChildSchema
   AND ix.TableName = fk.ChildTable

ORDER BY
    fk.ChildSchema,
    fk.ChildTable,
    fk.ForeignKeyName,
    ix.IndexId;


/* ============================================================
   PART 4 — Simplified FK Supporting Index Status
   ------------------------------------------------------------
   One row per FK.

   This is the main result to use for Phase 10.6-B planning.
   ============================================================ */

SELECT
    fk.ForeignKeyName,

    fk.ChildSchema,
    fk.ChildTable,

    fk.ParentSchema,
    fk.ParentTable,

    fk.FKColumnCount,
    fk.FKColumnList,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #IndexDefinitions AS ix
            WHERE
                ix.SchemaName = fk.ChildSchema
                AND ix.TableName = fk.ChildTable
                AND ix.IsDisabled = 0
                AND ix.KeyColumnCount >= fk.FKColumnCount

                AND NOT EXISTS
                (
                    SELECT 1
                    FROM #FKColumns AS f
                    WHERE
                        f.ForeignKeyObjectId = fk.ForeignKeyObjectId

                        AND NOT EXISTS
                        (
                            SELECT 1
                            FROM #IndexColumns AS ic
                            WHERE
                                ic.SchemaName = fk.ChildSchema
                                AND ic.TableName = fk.ChildTable
                                AND ic.IndexId = ix.IndexId
                                AND ic.KeyOrdinal = f.ColumnOrdinal
                                AND ic.ColumnName = f.ChildColumn
                        )
                )
        )
        THEN 'SUPPORTED'

        ELSE 'NEEDS_REVIEW'
    END AS SupportingIndexStatus

FROM #FKDefinitions AS fk

ORDER BY
    fk.ChildSchema,
    fk.ChildTable,
    fk.ForeignKeyName;


/* ============================================================
   PART 5 — Candidate FK Indexes
   ------------------------------------------------------------
   This section DOES NOT create anything.

   It identifies FKs that may need a supporting index.
   Final index design must be reviewed against workload
   and Phase 10.7 before creation.
   ============================================================ */

SELECT
    fk.ForeignKeyName,

    fk.ChildSchema,
    fk.ChildTable,

    fk.ParentSchema,
    fk.ParentTable,

    fk.FKColumnList,

    'CANDIDATE_FOR_REVIEW' AS Recommendation

FROM #FKDefinitions AS fk

WHERE NOT EXISTS
(
    SELECT 1
    FROM #IndexDefinitions AS ix
    WHERE
        ix.SchemaName = fk.ChildSchema
        AND ix.TableName = fk.ChildTable
        AND ix.IsDisabled = 0
        AND ix.KeyColumnCount >= fk.FKColumnCount

        AND NOT EXISTS
        (
            SELECT 1
            FROM #FKColumns AS f
            WHERE
                f.ForeignKeyObjectId = fk.ForeignKeyObjectId

                AND NOT EXISTS
                (
                    SELECT 1
                    FROM #IndexColumns AS ic
                    WHERE
                        ic.SchemaName = fk.ChildSchema
                        AND ic.TableName = fk.ChildTable
                        AND ic.IndexId = ix.IndexId
                        AND ic.KeyOrdinal = f.ColumnOrdinal
                        AND ic.ColumnName = f.ChildColumn
                )
        )
)

ORDER BY
    fk.ChildSchema,
    fk.ChildTable,
    fk.ForeignKeyName;


/* ============================================================
   PART 6 — Foreign Key / Index Summary
   ------------------------------------------------------------
   FIXED VERSION

   This version avoids using EXISTS/subqueries directly
   inside SUM(CASE ...).

   READ-ONLY
   ============================================================ */

IF OBJECT_ID('tempdb..#FKAuditStatus') IS NOT NULL
    DROP TABLE #FKAuditStatus;


CREATE TABLE #FKAuditStatus
(
    ForeignKeyObjectId INT NOT NULL,
    ForeignKeyName SYSNAME NOT NULL,

    ChildSchema SYSNAME NOT NULL,
    ChildTable SYSNAME NOT NULL,

    ParentSchema SYSNAME NOT NULL,
    ParentTable SYSNAME NOT NULL,

    FKColumnCount INT NOT NULL,
    FKColumnList NVARCHAR(MAX) NOT NULL,

    SupportingIndexStatus VARCHAR(50) NOT NULL
);


/* ============================================================
   Determine status for each FK first
   ============================================================ */

INSERT INTO #FKAuditStatus
(
    ForeignKeyObjectId,
    ForeignKeyName,

    ChildSchema,
    ChildTable,

    ParentSchema,
    ParentTable,

    FKColumnCount,
    FKColumnList,

    SupportingIndexStatus
)
SELECT
    fk.ForeignKeyObjectId,
    fk.ForeignKeyName,

    fk.ChildSchema,
    fk.ChildTable,

    fk.ParentSchema,
    fk.ParentTable,

    fk.FKColumnCount,
    fk.FKColumnList,

    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM #IndexDefinitions AS ix

            WHERE
                ix.SchemaName = fk.ChildSchema
                AND ix.TableName = fk.ChildTable
                AND ix.IsDisabled = 0
                AND ix.KeyColumnCount >= fk.FKColumnCount

                /* ------------------------------------------------
                   Every FK column must match the same ordinal
                   position in the index.
                   ------------------------------------------------ */

                AND NOT EXISTS
                (
                    SELECT 1
                    FROM #FKColumns AS f

                    WHERE
                        f.ForeignKeyObjectId =
                            fk.ForeignKeyObjectId

                        AND NOT EXISTS
                        (
                            SELECT 1
                            FROM #IndexColumns AS ic

                            WHERE
                                ic.SchemaName =
                                    fk.ChildSchema

                                AND ic.TableName =
                                    fk.ChildTable

                                AND ic.IndexId =
                                    ix.IndexId

                                AND ic.KeyOrdinal =
                                    f.ColumnOrdinal

                                AND ic.ColumnName =
                                    f.ChildColumn
                        )
                )
        )
        THEN 'SUPPORTED'

        ELSE 'NEEDS_REVIEW'
    END AS SupportingIndexStatus

FROM #FKDefinitions AS fk;


/* ============================================================
   PART 6-A — Detailed Status
   ============================================================ */

SELECT
    ForeignKeyName,

    ChildSchema,
    ChildTable,

    ParentSchema,
    ParentTable,

    FKColumnCount,
    FKColumnList,

    SupportingIndexStatus

FROM #FKAuditStatus

ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName;


/* ============================================================
   PART 6-B — Summary
   ------------------------------------------------------------
   IMPORTANT:
   The aggregation is now performed over a normal table,
   not over a CASE containing subqueries.
   ============================================================ */

SELECT
    COUNT(*) AS TotalForeignKeys,

    SUM
    (
        CASE
            WHEN SupportingIndexStatus = 'SUPPORTED'
            THEN 1
            ELSE 0
        END
    ) AS SupportedForeignKeys,

    SUM
    (
        CASE
            WHEN SupportingIndexStatus = 'NEEDS_REVIEW'
            THEN 1
            ELSE 0
        END
    ) AS ForeignKeysNeedingReview

FROM #FKAuditStatus;


/* ============================================================
   PART 6-C — Only FKs Requiring Review
   ============================================================ */

SELECT
    ForeignKeyName,

    ChildSchema,
    ChildTable,

    ParentSchema,
    ParentTable,

    FKColumnCount,
    FKColumnList,

    SupportingIndexStatus

FROM #FKAuditStatus

WHERE SupportingIndexStatus = 'NEEDS_REVIEW'

ORDER BY
    ChildSchema,
    ChildTable,
    ForeignKeyName;
/* ============================================================
   END OF PHASE 10.6-A
   ============================================================ */

SELECT
    'PHASE 10.6-A' AS Phase,
    'FK Supporting Index Audit' AS AuditName,
    'READ-ONLY' AS ExecutionMode,
    'COMPLETED - NO DATABASE CHANGES' AS Status,
    GETDATE() AS CompletedAt;
GO