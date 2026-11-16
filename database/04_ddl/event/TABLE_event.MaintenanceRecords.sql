CREATE TABLE event.MaintenanceRecords
(
    MaintenanceId INT IDENTITY(1,1) NOT NULL,

    InstrumentId INT NOT NULL,

    MaintenanceDate DATETIME2(0) NOT NULL,

    MaintenanceTypeCode VARCHAR(50) NULL,
    MaintenanceCategoryCode VARCHAR(50) NULL,

    MaintenanceStatusCode VARCHAR(50) NULL,

    WorkOrderNumber VARCHAR(100) NULL,

    PriorityCode VARCHAR(30) NULL,

    FailureRelated BIT NOT NULL
        CONSTRAINT DF_MaintenanceRecords_FailureRelated DEFAULT (0),

    Description NVARCHAR(MAX) NULL,

    WorkPerformed NVARCHAR(MAX) NULL,

    Findings NVARCHAR(MAX) NULL,

    CompletionDate DATETIME2(0) NULL,

    DowntimeHours DECIMAL(12,2) NULL,

    LaborCost DECIMAL(18,2) NULL,
    MaterialCost DECIMAL(18,2) NULL,
    OtherCost DECIMAL(18,2) NULL,

    CurrencyId INT NULL,

    Remarks NVARCHAR(MAX) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_MaintenanceRecords_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_MaintenanceRecords
        PRIMARY KEY (MaintenanceId),

    CONSTRAINT FK_MaintenanceRecords_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_MaintenanceRecords_Currency
        FOREIGN KEY (CurrencyId)
        REFERENCES ref.Currency(CurrencyId),

    CONSTRAINT CK_MaintenanceRecords_CompletionDate
        CHECK
        (
            CompletionDate IS NULL
            OR CompletionDate >= MaintenanceDate
        ),

    CONSTRAINT CK_MaintenanceRecords_Downtime
        CHECK
        (
            DowntimeHours IS NULL
            OR DowntimeHours >= 0
        ),

    CONSTRAINT CK_MaintenanceRecords_LaborCost
        CHECK
        (
            LaborCost IS NULL
            OR LaborCost >= 0
        ),

    CONSTRAINT CK_MaintenanceRecords_MaterialCost
        CHECK
        (
            MaterialCost IS NULL
            OR MaterialCost >= 0
        ),

    CONSTRAINT CK_MaintenanceRecords_OtherCost
        CHECK
        (
            OtherCost IS NULL
            OR OtherCost >= 0
        )
);
GO