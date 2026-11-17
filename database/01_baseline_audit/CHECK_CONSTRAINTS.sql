USE ComprehensiveInstrumentationDB_New;
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    cc.name AS ConstraintName,
    cc.definition AS ConstraintDefinition,
    cc.is_disabled,
    cc.is_not_trusted,
    cc.is_not_for_replication
FROM sys.check_constraints cc
INNER JOIN sys.tables t
    ON t.object_id = cc.parent_object_id
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE
    s.name = 'event'
    AND t.name IN
    (
        'InstrumentLifecycle',
        'InstrumentOperationalStatusHistory',
        'InstrumentBypassHistory'
    )
ORDER BY
    t.name,
    cc.name;
GO