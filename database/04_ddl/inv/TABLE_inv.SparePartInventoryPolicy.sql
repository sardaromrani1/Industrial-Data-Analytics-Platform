CREATE TABLE inv.SparePartInventoryPolicy
(
    SparePartInventoryPolicyId INT IDENTITY(1,1) NOT NULL,

    SparePartId              INT NOT NULL,
    InventoryLocationId      INT NOT NULL,

    MinStockLevel            DECIMAL(18,4) NULL,
    MaxStockLevel            DECIMAL(18,4) NULL,
    ReorderPoint             DECIMAL(18,4) NULL,
    ReorderQuantity           DECIMAL(18,4) NULL,

    SafetyStockQuantity       DECIMAL(18,4) NULL,

    LeadTimeDays              INT NULL,

    EconomicOrderQuantity     DECIMAL(18,4) NULL,

    IsCriticalStock           BIT NOT NULL
        CONSTRAINT DF_SparePartInventoryPolicy_IsCriticalStock
        DEFAULT (0),

    IsActive                  BIT NOT NULL
        CONSTRAINT DF_SparePartInventoryPolicy_IsActive
        DEFAULT (1),

    EffectiveFrom             DATE NULL,
    EffectiveTo               DATE NULL,

    Notes                     NVARCHAR(500) NULL,

    CreatedDateTime           DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartInventoryPolicy_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime           DATETIME2(0) NULL,

    CONSTRAINT PK_SparePartInventoryPolicy
        PRIMARY KEY (SparePartInventoryPolicyId),

    CONSTRAINT FK_SparePartInventoryPolicy_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartInventoryPolicy_Location
        FOREIGN KEY (InventoryLocationId)
        REFERENCES inv.InventoryLocations(InventoryLocationId),

    CONSTRAINT UQ_SparePartInventoryPolicy_SparePart_Location
        UNIQUE (SparePartId, InventoryLocationId),

    CONSTRAINT CK_SparePartInventoryPolicy_MinStock
        CHECK
        (
            MinStockLevel IS NULL
            OR MinStockLevel >= 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_MaxStock
        CHECK
        (
            MaxStockLevel IS NULL
            OR MaxStockLevel >= 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_ReorderPoint
        CHECK
        (
            ReorderPoint IS NULL
            OR ReorderPoint >= 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_ReorderQuantity
        CHECK
        (
            ReorderQuantity IS NULL
            OR ReorderQuantity > 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_SafetyStock
        CHECK
        (
            SafetyStockQuantity IS NULL
            OR SafetyStockQuantity >= 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_EOQ
        CHECK
        (
            EconomicOrderQuantity IS NULL
            OR EconomicOrderQuantity > 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_LeadTime
        CHECK
        (
            LeadTimeDays IS NULL
            OR LeadTimeDays >= 0
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_MinMax
        CHECK
        (
            MinStockLevel IS NULL
            OR MaxStockLevel IS NULL
            OR MaxStockLevel >= MinStockLevel
        ),

    CONSTRAINT CK_SparePartInventoryPolicy_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO