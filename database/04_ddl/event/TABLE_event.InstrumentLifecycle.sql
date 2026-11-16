CREATE TABLE event.InstrumentLifecycle
(
    InstrumentLifecycleId INT IDENTITY(1,1) NOT NULL,

    InstrumentId INT NOT NULL,

    LifecycleStatusCode VARCHAR(30) NOT NULL,

    EffectiveFrom DATETIME2(0) NOT NULL,
    EffectiveTo DATETIME2(0) NULL,

    ReasonCode VARCHAR(50) NULL,

    WorkOrderNumber VARCHAR(100) NULL,

    Remarks NVARCHAR(MAX) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentLifecycle_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_InstrumentLifecycle
        PRIMARY KEY (InstrumentLifecycleId),

    CONSTRAINT FK_InstrumentLifecycle_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentLifecycle_Status
        FOREIGN KEY (LifecycleStatusCode)
        REFERENCES ref.LifecycleStatus(LifecycleStatusCode),

    CONSTRAINT FK_InstrumentLifecycle_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_InstrumentLifecycle_DateRange
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO