CREATE TABLE inv.InventoryTransactions
(
    InventoryTransactionId      BIGINT IDENTITY(1,1) NOT NULL,

    SparePartId                 INT NOT NULL,

    InventoryLocationId         INT NOT NULL,

    TransactionTypeCode         VARCHAR(50) NOT NULL,

    TransactionDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_InventoryTransactions_TransactionDateTime
        DEFAULT (SYSUTCDATETIME()),

    Quantity                    DECIMAL(18,4) NOT NULL,

    UnitOfMeasureId             INT NULL,

    UnitCost                    DECIMAL(18,2) NULL,

    CurrencyId                  INT NULL,

    ReferenceDocumentNumber     VARCHAR(100) NULL,

    WorkOrderNumber             VARCHAR(100) NULL,

    MaintenanceId               INT NULL,

    FailureId                   INT NULL,

    FromInventoryLocationId     INT NULL,

    ToInventoryLocationId       INT NULL,

    PersonnelId                 INT NULL,

    SupplierId                  INT NULL,

    BatchNumber                 VARCHAR(100) NULL,

    SerialNumber                VARCHAR(100) NULL,

    ExpiryDate                  DATE NULL,

    Remarks                     NVARCHAR(1000) NULL,

    CreatedDateTime             DATETIME2(0) NOT NULL
        CONSTRAINT DF_InventoryTransactions_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy                   INT NULL,

    CONSTRAINT PK_InventoryTransactions
        PRIMARY KEY (InventoryTransactionId),

    CONSTRAINT FK_InventoryTransactions_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_InventoryTransactions_Location
        FOREIGN KEY (InventoryLocationId)
        REFERENCES inv.InventoryLocations(InventoryLocationId),

    CONSTRAINT FK_InventoryTransactions_UOM
        FOREIGN KEY (UnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT FK_InventoryTransactions_Currency
        FOREIGN KEY (CurrencyId)
        REFERENCES ref.Currency(CurrencyId),

    CONSTRAINT FK_InventoryTransactions_Personnel
        FOREIGN KEY (PersonnelId)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_InventoryTransactions_Supplier
        FOREIGN KEY (SupplierId)
        REFERENCES dbo.Suppliers(SupplierId),

    CONSTRAINT FK_InventoryTransactions_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_InventoryTransactions_Quantity
        CHECK
        (
            Quantity > 0
        ),

    CONSTRAINT CK_InventoryTransactions_UnitCost
        CHECK
        (
            UnitCost IS NULL
            OR UnitCost >= 0
        )
);
GO