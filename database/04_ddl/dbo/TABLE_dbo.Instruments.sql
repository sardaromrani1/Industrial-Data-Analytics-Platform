CREATE TABLE dbo.Instruments
(
    InstrumentId INT IDENTITY(1,1) NOT NULL,

    ------------------------------------------------------------
    -- Identity
    ------------------------------------------------------------

    TagNumber VARCHAR(100) NOT NULL,
    AlternateTag VARCHAR(100) NULL,

    SerialNumber VARCHAR(100) NULL,
    AssetNumber VARCHAR(100) NULL,

    ------------------------------------------------------------
    -- Physical Location
    ------------------------------------------------------------

    UnitId INT NOT NULL,
    SubSystemId INT NULL,

    ------------------------------------------------------------
    -- Classification
    ------------------------------------------------------------

    InstrumentTypeId INT NOT NULL,
    ManufacturerId INT NULL,

    Model NVARCHAR(150) NULL,

    ------------------------------------------------------------
    -- Description
    ------------------------------------------------------------

    Description NVARCHAR(500) NULL,
    FunctionalDescription NVARCHAR(MAX) NULL,

    ------------------------------------------------------------
    -- Process Information
    ------------------------------------------------------------

    ProcessVariable NVARCHAR(100) NULL,
    ServiceDescription NVARCHAR(500) NULL,
    FluidType NVARCHAR(100) NULL,
    FluidComposition NVARCHAR(500) NULL,

    ------------------------------------------------------------
    -- Measurement Range
    ------------------------------------------------------------

    MeasurementRangeMin DECIMAL(20,8) NULL,
    MeasurementRangeMax DECIMAL(20,8) NULL,
    MeasurementUnitId INT NULL,

    ------------------------------------------------------------
    -- Output Range
    ------------------------------------------------------------

    OutputRangeMin DECIMAL(20,8) NULL,
    OutputRangeMax DECIMAL(20,8) NULL,
    OutputUnitId INT NULL,

    ------------------------------------------------------------
    -- Safety / Protection
    ------------------------------------------------------------

    SILLevel VARCHAR(20) NULL,
    ATEXClassification VARCHAR(100) NULL,
    IPRating VARCHAR(20) NULL,

    ------------------------------------------------------------
    -- Communication / Control
    ------------------------------------------------------------

    CommunicationProtocolCode VARCHAR(50) NULL,
    DcsSystemReference VARCHAR(100) NULL,
    ModbusAddress VARCHAR(100) NULL,

    ------------------------------------------------------------
    -- Operational Information
    ------------------------------------------------------------

    InstallationDate DATE NULL,
    CommissioningDate DATE NULL,

    ------------------------------------------------------------
    -- Status
    ------------------------------------------------------------

    IsActive BIT NOT NULL
        CONSTRAINT DF_Instruments_IsActive DEFAULT (1),

    ------------------------------------------------------------
    -- Notes
    ------------------------------------------------------------

    Notes NVARCHAR(MAX) NULL,

    ------------------------------------------------------------
    -- Audit
    ------------------------------------------------------------

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_Instruments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    ------------------------------------------------------------
    -- Primary Key
    ------------------------------------------------------------

    CONSTRAINT PK_Instruments
        PRIMARY KEY (InstrumentId),

    ------------------------------------------------------------
    -- Unique Constraints
    ------------------------------------------------------------

    CONSTRAINT UQ_Instruments_TagNumber
        UNIQUE (TagNumber),

    ------------------------------------------------------------
    -- Foreign Keys
    ------------------------------------------------------------

    CONSTRAINT FK_Instruments_ProcessUnit
        FOREIGN KEY (UnitId)
        REFERENCES dbo.ProcessUnits(UnitId),

    CONSTRAINT FK_Instruments_SubSystem
        FOREIGN KEY (SubSystemId)
        REFERENCES dbo.SubSystems(SubSystemId),

    CONSTRAINT FK_Instruments_InstrumentType
        FOREIGN KEY (InstrumentTypeId)
        REFERENCES dbo.InstrumentTypes(InstrumentTypeId),

    CONSTRAINT FK_Instruments_Manufacturer
        FOREIGN KEY (ManufacturerId)
        REFERENCES dbo.Manufacturers(ManufacturerId),

    CONSTRAINT FK_Instruments_MeasurementUOM
        FOREIGN KEY (MeasurementUnitId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT FK_Instruments_OutputUOM
        FOREIGN KEY (OutputUnitId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    ------------------------------------------------------------
    -- Data Integrity
    ------------------------------------------------------------

    CONSTRAINT CK_Instruments_MeasurementRange
        CHECK
        (
            MeasurementRangeMin IS NULL
            OR MeasurementRangeMax IS NULL
            OR MeasurementRangeMax >= MeasurementRangeMin
        ),

    CONSTRAINT CK_Instruments_OutputRange
        CHECK
        (
            OutputRangeMin IS NULL
            OR OutputRangeMax IS NULL
            OR OutputRangeMax >= OutputRangeMin
        ),

    CONSTRAINT CK_Instruments_InstallationCommissioning
        CHECK
        (
            CommissioningDate IS NULL
            OR InstallationDate IS NULL
            OR CommissioningDate >= InstallationDate
        )
);
GO