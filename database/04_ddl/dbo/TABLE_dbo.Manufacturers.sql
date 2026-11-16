CREATE TABLE dbo.Manufacturers
(
    ManufacturerId INT IDENTITY(1,1) NOT NULL,

    ManufacturerCode VARCHAR(50) NOT NULL,
    ManufacturerName NVARCHAR(200) NOT NULL,

    CountryCode CHAR(2) NULL,
    Website VARCHAR(500) NULL,

    ContactInformation NVARCHAR(500) NULL,
    LocalRepresentative NVARCHAR(200) NULL,

    HasServiceCenter BIT NOT NULL
        CONSTRAINT DF_Manufacturers_HasServiceCenter DEFAULT (0),

    IsApproved BIT NOT NULL
        CONSTRAINT DF_Manufacturers_IsApproved DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_Manufacturers_IsActive DEFAULT (1),

    Notes NVARCHAR(MAX) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_Manufacturers_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_Manufacturers
        PRIMARY KEY (ManufacturerId),

    CONSTRAINT UQ_Manufacturers_Code
        UNIQUE (ManufacturerCode),

    CONSTRAINT UQ_Manufacturers_Name
        UNIQUE (ManufacturerName)
);
GO