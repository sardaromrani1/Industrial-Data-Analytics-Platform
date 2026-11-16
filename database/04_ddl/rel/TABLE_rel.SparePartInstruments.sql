CREATE TABLE rel.SparePartInstruments
(
    SparePartId INT NOT NULL,
    InstrumentId INT NOT NULL,

    CompatibilityTypeCode VARCHAR(50) NULL,

    IsPreferred BIT NOT NULL
        CONSTRAINT DF_SparePartInstruments_IsPreferred DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_SparePartInstruments_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartInstruments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_SparePartInstruments
        PRIMARY KEY (SparePartId, InstrumentId),

    CONSTRAINT FK_SparePartInstruments_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartInstruments_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_SparePartInstruments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId)
);
GO