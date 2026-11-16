CREATE TABLE rel.SparePartInstrumentTypes
(
    SparePartId INT NOT NULL,
    InstrumentTypeId INT NOT NULL,

    CompatibilityTypeCode VARCHAR(50) NULL,

    IsPreferred BIT NOT NULL
        CONSTRAINT DF_SparePartInstrumentTypes_IsPreferred DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_SparePartInstrumentTypes_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartInstrumentTypes_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_SparePartInstrumentTypes
        PRIMARY KEY (SparePartId, InstrumentTypeId),

    CONSTRAINT FK_SparePartInstrumentTypes_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartInstrumentTypes_InstrumentType
        FOREIGN KEY (InstrumentTypeId)
        REFERENCES dbo.InstrumentTypes(InstrumentTypeId),

    CONSTRAINT FK_SparePartInstrumentTypes_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId)
);
GO