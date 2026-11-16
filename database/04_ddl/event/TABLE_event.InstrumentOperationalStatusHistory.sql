CREATE TABLE event.InstrumentOperationalStatusHistory
(
    InstrumentOperationalStatusHistoryId
        INT IDENTITY(1,1) NOT NULL,

    InstrumentId INT NOT NULL,

    StatusCode VARCHAR(30) NOT NULL,

    EffectiveFrom DATETIME2(0) NOT NULL,
    EffectiveTo DATETIME2(0) NULL,

    ReasonCode VARCHAR(50) NULL,

    FailureId INT NULL,
    MaintenanceId INT NULL,

    Remarks NVARCHAR(MAX) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentOperationalStatusHistory_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_InstrumentOperationalStatusHistory
        PRIMARY KEY
        (InstrumentOperationalStatusHistoryId),

    CONSTRAINT FK_InstrumentOperationalStatusHistory_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentOperationalStatusHistory_Status
        FOREIGN KEY (StatusCode)
        REFERENCES ref.InstrumentStatus(StatusCode),

    CONSTRAINT FK_InstrumentOperationalStatusHistory_Failure
        FOREIGN KEY (FailureId)
        REFERENCES event.FailureRecords(FailureId),

    CONSTRAINT FK_InstrumentOperationalStatusHistory_Maintenance
        FOREIGN KEY (MaintenanceId)
        REFERENCES event.MaintenanceRecords(MaintenanceId),

    CONSTRAINT FK_InstrumentOperationalStatusHistory_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_InstrumentOperationalStatusHistory_DateRange
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO