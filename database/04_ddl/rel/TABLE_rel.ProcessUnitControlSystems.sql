CREATE TABLE rel.ProcessUnitControlSystems
(
    ProcessUnitId INT NOT NULL,
    ControlSystemId INT NOT NULL,

    RelationshipTypeCode VARCHAR(50) NULL,

    IsPrimary BIT NOT NULL
        CONSTRAINT DF_ProcessUnitControlSystems_IsPrimary DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_ProcessUnitControlSystems_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_ProcessUnitControlSystems_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_ProcessUnitControlSystems
        PRIMARY KEY (ProcessUnitId, ControlSystemId),

    CONSTRAINT FK_ProcessUnitControlSystems_ProcessUnit
        FOREIGN KEY (ProcessUnitId)
        REFERENCES dbo.ProcessUnits(UnitId),

    CONSTRAINT FK_ProcessUnitControlSystems_ControlSystem
        FOREIGN KEY (ControlSystemId)
        REFERENCES dbo.ControlSystems(ControlSystemId),

    CONSTRAINT FK_ProcessUnitControlSystems_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId)
);
GO