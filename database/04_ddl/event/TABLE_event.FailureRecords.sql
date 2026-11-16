CREATE TABLE event.FailureRecords
(
    FailureId INT IDENTITY(1,1) NOT NULL,

    InstrumentId INT NOT NULL,

    FailureDate DATETIME2(0) NOT NULL,

    FailureTypeCode VARCHAR(50) NULL,
    FailureModeCode VARCHAR(50) NULL,
    FailureCauseCode VARCHAR(50) NULL,

    FailureSeverityCode VARCHAR(50) NULL,

    DetectionMethodCode VARCHAR(50) NULL,

    WorkOrderNumber VARCHAR(100) NULL,

    PreviousFailureId INT NULL,

    FailureDescription NVARCHAR(MAX) NULL,

    CorrectiveAction NVARCHAR(MAX) NULL,

    FailureStartDateTime DATETIME2(0) NULL,
    FailureEndDateTime DATETIME2(0) NULL,

    DowntimeHours DECIMAL(12,2) NULL,

    RepairCost DECIMAL(18,2) NULL,
    CurrencyId INT NULL,

    IsRepeatFailure BIT NULL,

    Remarks NVARCHAR(MAX) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_FailureRecords_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_FailureRecords
        PRIMARY KEY (FailureId),

    CONSTRAINT FK_FailureRecords_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_FailureRecords_PreviousFailure
        FOREIGN KEY (PreviousFailureId)
        REFERENCES event.FailureRecords(FailureId),

    CONSTRAINT FK_FailureRecords_Currency
        FOREIGN KEY (CurrencyId)
        REFERENCES ref.Currency(CurrencyId),

    CONSTRAINT CK_FailureRecords_Downtime
        CHECK
        (
            DowntimeHours IS NULL
            OR DowntimeHours >= 0
        ),

    CONSTRAINT CK_FailureRecords_RepairCost
        CHECK
        (
            RepairCost IS NULL
            OR RepairCost >= 0
        ),

    CONSTRAINT CK_FailureRecords_DateRange
        CHECK
        (
            FailureEndDateTime IS NULL
            OR FailureStartDateTime IS NULL
            OR FailureEndDateTime >= FailureStartDateTime
        )
);
GO