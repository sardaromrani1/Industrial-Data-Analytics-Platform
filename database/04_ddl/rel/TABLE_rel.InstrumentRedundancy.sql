CREATE TABLE rel.InstrumentRedundancy
(
    InstrumentId1 INT NOT NULL,
    InstrumentId2 INT NOT NULL,

    RedundancyTypeCode VARCHAR(50) NULL,

    RedundancyGroupCode VARCHAR(50) NULL,

    IsActive BIT NOT NULL
        CONSTRAINT DF_InstrumentRedundancy_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentRedundancy_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_InstrumentRedundancy
        PRIMARY KEY (InstrumentId1, InstrumentId2),

    CONSTRAINT FK_InstrumentRedundancy_Instrument1
        FOREIGN KEY (InstrumentId1)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentRedundancy_Instrument2
        FOREIGN KEY (InstrumentId2)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentRedundancy_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_InstrumentRedundancy_NotSelf
        CHECK (InstrumentId1 <> InstrumentId2)
);
GO
