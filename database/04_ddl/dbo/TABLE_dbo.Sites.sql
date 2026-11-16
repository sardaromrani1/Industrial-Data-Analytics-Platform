CREATE TABLE dbo.Sites
(
    SiteId INT IDENTITY(1,1) NOT NULL,

    SiteCode VARCHAR(50) NOT NULL,
    SiteName NVARCHAR(200) NOT NULL,

    Description NVARCHAR(500) NULL,

    CountryCode CHAR(2) NULL,
    LocationDescription NVARCHAR(500) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_Sites_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_Sites_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_Sites
        PRIMARY KEY (SiteId),

    CONSTRAINT UQ_Sites_SiteCode
        UNIQUE (SiteCode),

    CONSTRAINT UQ_Sites_SiteName
        UNIQUE (SiteName)
);
GO