CREATE TABLE dbo.ProcessUnits
(
    UnitId INT IDENTITY(1,1) NOT NULL,

    SiteId INT NOT NULL,

    UnitCode VARCHAR(50) NOT NULL,
    UnitName NVARCHAR(200) NOT NULL,

    Description NVARCHAR(500) NULL,

    ProcessDescription NVARCHAR(MAX) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_ProcessUnits_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_ProcessUnits_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_ProcessUnits
        PRIMARY KEY (UnitId),

    CONSTRAINT UQ_ProcessUnits_Site_UnitCode
        UNIQUE (SiteId, UnitCode),

    CONSTRAINT FK_ProcessUnits_Site
        FOREIGN KEY (SiteId)
        REFERENCES dbo.Sites(SiteId)
);
GO