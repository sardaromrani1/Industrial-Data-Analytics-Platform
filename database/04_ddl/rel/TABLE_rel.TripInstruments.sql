CREATE TABLE rel.TripInstruments
(
    TripId INT NOT NULL,
    InstrumentId INT NOT NULL,

    TripRoleCode VARCHAR(50) NOT NULL,

    SequenceNumber INT NULL,

    IsPrimary BIT NOT NULL
        CONSTRAINT DF_TripInstruments_IsPrimary DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_TripInstruments_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_TripInstruments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_TripInstruments
        PRIMARY KEY (TripId, InstrumentId, TripRoleCode),

    CONSTRAINT FK_TripInstruments_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_TripInstruments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_TripInstruments_Sequence
        CHECK
        (
            SequenceNumber IS NULL
            OR SequenceNumber > 0
        )
);
GO