CREATE TABLE rel.InstrumentControlSystems
(
    InstrumentId INT NOT NULL,
    ControlSystemId INT NOT NULL,

    ControlRoleCode VARCHAR(50) NULL,

    NodeAddress VARCHAR(100) NULL,
    IOLocation VARCHAR(100) NULL,

    IsPrimary BIT NOT NULL
        CONSTRAINT DF_InstrumentControlSystems_IsPrimary DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_InstrumentControlSystems_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentControlSystems_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_InstrumentControlSystems
        PRIMARY KEY (InstrumentId, ControlSystemId),

    CONSTRAINT FK_InstrumentControlSystems_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentControlSystems_ControlSystem
        FOREIGN KEY (ControlSystemId)
        REFERENCES dbo.ControlSystems(ControlSystemId),

    CONSTRAINT FK_InstrumentControlSystems_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId)
);
GO
