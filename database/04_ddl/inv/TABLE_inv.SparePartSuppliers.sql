CREATE TABLE inv.SparePartSuppliers
(
    SparePartSupplierId      INT IDENTITY(1,1) NOT NULL,

    SparePartId             INT NOT NULL,

    SupplierId              INT NOT NULL,

    SupplierPartNumber      NVARCHAR(100) NULL,

    IsPrimarySupplier       BIT NOT NULL
        CONSTRAINT DF_SparePartSuppliers_IsPrimary
        DEFAULT (0),

    IsApprovedSupplier      BIT NOT NULL
        CONSTRAINT DF_SparePartSuppliers_IsApproved
        DEFAULT (1),

    LeadTimeDays            INT NULL,

    MinimumOrderQuantity    DECIMAL(18,4) NULL,

    OrderMultiple           DECIMAL(18,4) NULL,

    UnitCost                DECIMAL(18,2) NULL,

    CurrencyId              INT NULL,

    ValidFrom               DATE NULL,

    ValidTo                 DATE NULL,

    LastPurchaseDate        DATE NULL,

    LastPurchasePrice       DECIMAL(18,2) NULL,

    PriceReviewDate         DATE NULL,

    SupplierRating          DECIMAL(5,2) NULL,

    Notes                   NVARCHAR(1000) NULL,

    IsActive                BIT NOT NULL
        CONSTRAINT DF_SparePartSuppliers_IsActive
        DEFAULT (1),

    CreatedDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartSuppliers_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime         DATETIME2(0) NULL,

    CONSTRAINT PK_SparePartSuppliers
        PRIMARY KEY (SparePartSupplierId),

    CONSTRAINT FK_SparePartSuppliers_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartSuppliers_Currency
        FOREIGN KEY (CurrencyId)
        REFERENCES ref.Currency(CurrencyId),

    CONSTRAINT UQ_SparePartSuppliers
        UNIQUE (SparePartId, SupplierId),

    CONSTRAINT CK_SparePartSuppliers_LeadTime
        CHECK
        (
            LeadTimeDays IS NULL
            OR LeadTimeDays >= 0
        ),

    CONSTRAINT CK_SparePartSuppliers_MinOrder
        CHECK
        (
            MinimumOrderQuantity IS NULL
            OR MinimumOrderQuantity > 0
        ),

    CONSTRAINT CK_SparePartSuppliers_OrderMultiple
        CHECK
        (
            OrderMultiple IS NULL
            OR OrderMultiple > 0
        ),

    CONSTRAINT CK_SparePartSuppliers_UnitCost
        CHECK
        (
            UnitCost IS NULL
            OR UnitCost >= 0
        ),

    CONSTRAINT CK_SparePartSuppliers_LastPrice
        CHECK
        (
            LastPurchasePrice IS NULL
            OR LastPurchasePrice >= 0
        ),

    CONSTRAINT CK_SparePartSuppliers_Rating
        CHECK
        (
            SupplierRating IS NULL
            OR (SupplierRating >= 0 AND SupplierRating <= 5)
        ),

    CONSTRAINT CK_SparePartSuppliers_ValidDate
        CHECK
        (
            ValidTo IS NULL
            OR ValidFrom IS NULL
            OR ValidTo >= ValidFrom
        )
);
GO