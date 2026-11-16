CREATE TABLE dbo.SpareParts
(
    SparePartId INT IDENTITY(1,1) NOT NULL,

    ------------------------------------------------------------
    -- Identity
    ------------------------------------------------------------

    PartNumber VARCHAR(100) NOT NULL,
    PartName NVARCHAR(200) NOT NULL,

    ManufacturerPartNumber VARCHAR(100) NULL,

    ManufacturerId INT NULL,

    ------------------------------------------------------------
    -- Classification
    ------------------------------------------------------------

    PartCategoryCode VARCHAR(50) NULL,
    PartTypeCode VARCHAR(50) NULL,

    Description NVARCHAR(500) NULL,

    ------------------------------------------------------------
    -- Specification
    ------------------------------------------------------------

    Specification NVARCHAR(MAX) NULL,

    Material NVARCHAR(200) NULL,

    ------------------------------------------------------------
    -- Unit / Packaging
    ------------------------------------------------------------

    StockUnitOfMeasureId INT NULL,

    ------------------------------------------------------------
    -- Lifecycle
    ------------------------------------------------------------

    IsCritical BIT NOT NULL
        CONSTRAINT DF_SpareParts_IsCritical DEFAULT (0),

    IsRepairable BIT NOT NULL
        CONSTRAINT DF_SpareParts_IsRepairable DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_SpareParts_IsActive DEFAULT (1),

    ------------------------------------------------------------
    -- Notes
    ------------------------------------------------------------

    Notes NVARCHAR(MAX) NULL,

    ------------------------------------------------------------
    -- Audit
    ------------------------------------------------------------

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_SpareParts_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    ------------------------------------------------------------
    -- Primary Key
    ------------------------------------------------------------

    CONSTRAINT PK_SpareParts
        PRIMARY KEY (SparePartId),

    ------------------------------------------------------------
    -- Unique Constraints
    ------------------------------------------------------------

    CONSTRAINT UQ_SpareParts_PartNumber
        UNIQUE (PartNumber),

    ------------------------------------------------------------
    -- Foreign Keys
    ------------------------------------------------------------

    CONSTRAINT FK_SpareParts_Manufacturer
        FOREIGN KEY (ManufacturerId)
        REFERENCES dbo.Manufacturers(ManufacturerId),

    CONSTRAINT FK_SpareParts_StockUOM
        FOREIGN KEY (StockUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId)
);
GO