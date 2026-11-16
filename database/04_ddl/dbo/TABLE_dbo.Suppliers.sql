CREATE TABLE dbo.Suppliers
(
    SupplierId              INT IDENTITY(1,1) NOT NULL,

    SupplierCode            VARCHAR(50) NOT NULL,
    SupplierName            NVARCHAR(200) NOT NULL,

    SupplierTypeCode        VARCHAR(50) NULL,

    CountryCode             VARCHAR(10) NULL,

    ContactPerson           NVARCHAR(100) NULL,
    Email                   NVARCHAR(100) NULL,
    Phone                   NVARCHAR(50) NULL,

    Website                 NVARCHAR(200) NULL,

    IsApproved              BIT NOT NULL
        CONSTRAINT DF_Suppliers_IsApproved
        DEFAULT (0),

    IsActive                BIT NOT NULL
        CONSTRAINT DF_Suppliers_IsActive
        DEFAULT (1),

    CreatedDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_Suppliers_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime         DATETIME2(0) NULL,

    CONSTRAINT PK_Suppliers
        PRIMARY KEY (SupplierId),

    CONSTRAINT UQ_Suppliers_Code
        UNIQUE (SupplierCode)
);
GO