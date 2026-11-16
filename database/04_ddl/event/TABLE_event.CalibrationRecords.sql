CREATE TABLE event.CalibrationRecords
(
    CalibrationId INT IDENTITY(1,1) NOT NULL,

    InstrumentId INT NOT NULL,

    CalibrationDate DATETIME2(0) NOT NULL,
    CalibrationTypeCode VARCHAR(50) NULL,

    CalibrationStatusCode VARCHAR(50) NULL,

    WorkOrderNumber VARCHAR(100) NULL,

    PerformedByPersonnelId INT NULL,
    ApprovedByPersonnelId INT NULL,

    ReferenceEquipmentId INT NULL,

    AsFoundConditionCode VARCHAR(50) NULL,
    AsLeftConditionCode VARCHAR(50) NULL,

    ResultCode VARCHAR(50) NULL,

    Remarks NVARCHAR(MAX) NULL,

    NextCalibrationDate DATE NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_CalibrationRecords_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime DATETIME2(0) NULL,

    CONSTRAINT PK_CalibrationRecords
        PRIMARY KEY (CalibrationId),

    CONSTRAINT FK_CalibrationRecords_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_CalibrationRecords_PerformedBy
        FOREIGN KEY (PerformedByPersonnelId)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_CalibrationRecords_ApprovedBy
        FOREIGN KEY (ApprovedByPersonnelId)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_CalibrationRecords_ReferenceEquipment
        FOREIGN KEY (ReferenceEquipmentId)
        REFERENCES dbo.ReferenceEquipment(ReferenceEquipmentId),

    CONSTRAINT CK_CalibrationRecords_NextCalibrationDate
        CHECK
        (
            NextCalibrationDate IS NULL
            OR NextCalibrationDate >= CAST(CalibrationDate AS DATE)
        )
);
GO