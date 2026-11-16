CREATE TABLE dbo.ReferenceEquipment
(
    ReferenceEquipmentId INT IDENTITY(1,1) NOT NULL,

    EquipmentCode        VARCHAR(50) NOT NULL,
    EquipmentName        NVARCHAR(200) NOT NULL,
    EquipmentTypeCode    VARCHAR(50) NULL,

    SerialNumber         VARCHAR(100) NULL,

    ManufacturerId       INT NULL,
    Model                NVARCHAR(100) NULL,

    CalibrationIntervalDays INT NULL,
    LastCalibrationDate     DATE NULL,
    NextCalibrationDate     DATE NULL,

    Accuracy             DECIMAL(18,8) NULL,
    AccuracyUnitOfMeasureId INT NULL,

    IsActive             BIT NOT NULL
        CONSTRAINT DF_ReferenceEquipment_IsActive DEFAULT (1),

    Notes                NVARCHAR(MAX) NULL,

    CreatedDateTime      DATETIME2(0) NOT NULL
        CONSTRAINT DF_ReferenceEquipment_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_ReferenceEquipment
        PRIMARY KEY (ReferenceEquipmentId),

    CONSTRAINT UQ_ReferenceEquipment_Code
        UNIQUE (EquipmentCode),

    CONSTRAINT FK_ReferenceEquipment_Manufacturer
        FOREIGN KEY (ManufacturerId)
        REFERENCES dbo.Manufacturers(ManufacturerId),

    CONSTRAINT FK_ReferenceEquipment_AccuracyUOM
        FOREIGN KEY (AccuracyUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT CK_ReferenceEquipment_CalibrationInterval
        CHECK
        (
            CalibrationIntervalDays IS NULL
            OR CalibrationIntervalDays > 0
        ),

    CONSTRAINT CK_ReferenceEquipment_CalibrationDates
        CHECK
        (
            NextCalibrationDate IS NULL
            OR LastCalibrationDate IS NULL
            OR NextCalibrationDate >= LastCalibrationDate
        )
);
GO