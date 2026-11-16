CREATE TABLE ref.UnitOfMeasure
(
    UnitOfMeasureId     INT IDENTITY(1,1) NOT NULL,
    UomCode             VARCHAR(30) NOT NULL,
    UomName             NVARCHAR(100) NOT NULL,
    DimensionCode       VARCHAR(50) NULL,

    BaseUnitOfMeasureId INT NULL,

    ConversionFactor    DECIMAL(20,10) NULL,
    ConversionOffset    DECIMAL(20,10) NULL,

    IsBaseUnit          BIT NOT NULL
        CONSTRAINT DF_UnitOfMeasure_IsBaseUnit DEFAULT (0),

    IsActive             BIT NOT NULL
        CONSTRAINT DF_UnitOfMeasure_IsActive DEFAULT (1),

    CreatedDateTime      DATETIME2(0) NOT NULL
        CONSTRAINT DF_UnitOfMeasure_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_UnitOfMeasure
        PRIMARY KEY (UnitOfMeasureId),

    CONSTRAINT UQ_UnitOfMeasure_UomCode
        UNIQUE (UomCode),

    CONSTRAINT FK_UnitOfMeasure_BaseUnit
        FOREIGN KEY (BaseUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT CK_UnitOfMeasure_ConversionFactor
        CHECK
        (
            ConversionFactor IS NULL
            OR ConversionFactor > 0
        )
);
GO
