CREATE TABLE dbo.SubSystems
(
    SubSystemId INT IDENTITY(1,1) NOT NULL,

    UnitId INT NOT NULL,

    SubSystemCode VARCHAR(50) NOT NULL,
    SubSystemName NVARCHAR(200) NOT NULL,

    Description NVARCHAR(500) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_SubSystems_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_SubSystems_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_SubSystems
        PRIMARY KEY (SubSystemId),

    CONSTRAINT UQ_SubSystems_Unit_Code
        UNIQUE (UnitId, SubSystemCode),

    CONSTRAINT FK_SubSystems_ProcessUnit
        FOREIGN KEY (UnitId)
        REFERENCES dbo.ProcessUnits(UnitId)
);
GO