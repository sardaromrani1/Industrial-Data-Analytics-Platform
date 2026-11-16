CREATE TABLE event.SparePartUsage
(
    SparePartUsageId          BIGINT IDENTITY(1,1) NOT NULL,

    InventoryTransactionId    BIGINT NOT NULL,

    SparePartId               INT NOT NULL,

    InstrumentId              INT NULL,

    MaintenanceId             INT NULL,

    FailureId                 INT NULL,

    QuantityUsed              DECIMAL(18,4) NOT NULL,

    UnitOfMeasureId           INT NULL,

    UnitCost                  DECIMAL(18,2) NULL,

    CurrencyId                INT NULL,

    UsageDateTime              DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartUsage_UsageDateTime
        DEFAULT (SYSUTCDATETIME()),

    PersonnelId               INT NULL,

    UsageReasonCode            VARCHAR(50) NULL,

    Remarks                   NVARCHAR(1000) NULL,

    CreatedDateTime           DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartUsage_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime           DATETIME2(0) NULL,

    CreatedBy                 INT NULL,

    CONSTRAINT PK_SparePartUsage
        PRIMARY KEY (SparePartUsageId),

    CONSTRAINT FK_SparePartUsage_InventoryTransaction
        FOREIGN KEY (InventoryTransactionId)
        REFERENCES inv.InventoryTransactions(InventoryTransactionId),

    CONSTRAINT FK_SparePartUsage_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartUsage_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_SparePartUsage_UOM
        FOREIGN KEY (UnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT FK_SparePartUsage_Currency
        FOREIGN KEY (CurrencyId)
        REFERENCES ref.Currency(CurrencyId),

    CONSTRAINT FK_SparePartUsage_Personnel
        FOREIGN KEY (PersonnelId)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_SparePartUsage_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_SparePartUsage_Quantity
        CHECK
        (
            QuantityUsed > 0
        ),

    CONSTRAINT CK_SparePartUsage_UnitCost
        CHECK
        (
            UnitCost IS NULL
            OR UnitCost >= 0
        )
);
GO