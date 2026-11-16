CREATE TABLE dbo.InstrumentTypes
(
    InstrumentTypeId INT IDENTITY(1,1) NOT NULL,

    InstrumentTypeCode VARCHAR(50) NOT NULL,
    InstrumentTypeName NVARCHAR(200) NOT NULL,

    InstrumentCategoryCode VARCHAR(50) NULL,

    Description NVARCHAR(500) NULL,

    MeasurementClassCode VARCHAR(50) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_InstrumentTypes_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentTypes_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_InstrumentTypes
        PRIMARY KEY (InstrumentTypeId),

    CONSTRAINT UQ_InstrumentTypes_Code
        UNIQUE (InstrumentTypeCode),

    CONSTRAINT UQ_InstrumentTypes_Name
        UNIQUE (InstrumentTypeName)
);
GO