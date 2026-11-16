/* =========================================================
   Phase 9 - Database Schema Bootstrap
   Industrial Data Analytics Platform
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'ref'
)
    EXEC('CREATE SCHEMA ref');
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'rel'
)
    EXEC('CREATE SCHEMA rel');
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'event'
)
    EXEC('CREATE SCHEMA event');
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'inv'
)
    EXEC('CREATE SCHEMA inv');
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'doc'
)
    EXEC('CREATE SCHEMA doc');
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
    EXEC('CREATE SCHEMA analytics');
GO