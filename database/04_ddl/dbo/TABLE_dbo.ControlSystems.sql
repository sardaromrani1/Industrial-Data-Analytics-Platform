CREATE TABLE dbo.ControlSystems
(
    ControlSystemId INT IDENTITY(1,1) NOT NULL,

    ControlSystemCode VARCHAR(50) NOT NULL,
    ControlSystemName NVARCHAR(200) NOT NULL,

    ControlSystemTypeCode VARCHAR(50) NULL,

    VendorManufacturerId INT NULL,

    Model NVARCHAR(100) NULL,
    Version NVARCHAR(100) NULL,

    Description NVARCHAR(500) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_ControlSystems_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_ControlSystems_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_ControlSystems
        PRIMARY KEY (ControlSystemId),

    CONSTRAINT UQ_ControlSystems_Code
        UNIQUE (ControlSystemCode),

    CONSTRAINT UQ_ControlSystems_Name
        UNIQUE (ControlSystemName),

    CONSTRAINT FK_ControlSystems_Manufacturer
        FOREIGN KEY (VendorManufacturerId)
        REFERENCES dbo.Manufacturers(ManufacturerId)
);
GO