CREATE TABLE inv.InventoryLocations
(
    InventoryLocationId INT IDENTITY(1,1) NOT NULL,

    LocationCode VARCHAR(50) NOT NULL,
    LocationName NVARCHAR(200) NOT NULL,

    LocationTypeCode VARCHAR(50) NULL,

    ParentLocationId INT NULL,

    SiteId INT NULL,

    Description NVARCHAR(500) NULL,

    AddressDescription NVARCHAR(500) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_InventoryLocations_IsActive
        DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_InventoryLocations_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_InventoryLocations
        PRIMARY KEY (InventoryLocationId),

    CONSTRAINT UQ_InventoryLocations_Code
        UNIQUE (LocationCode),

    CONSTRAINT FK_InventoryLocations_Parent
        FOREIGN KEY (ParentLocationId)
        REFERENCES inv.InventoryLocations(InventoryLocationId),

    CONSTRAINT FK_InventoryLocations_Site
        FOREIGN KEY (SiteId)
        REFERENCES dbo.Sites(SiteId),

    CONSTRAINT CK_InventoryLocations_NotSelfParent
        CHECK
        (
            ParentLocationId IS NULL
            OR ParentLocationId <> InventoryLocationId
        )
);
GO