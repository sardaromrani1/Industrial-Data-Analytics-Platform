CREATE TABLE event.CalibrationTestPoints
(
    CalibrationTestPointId INT IDENTITY(1,1) NOT NULL,

    CalibrationId INT NOT NULL,

    TestSequence INT NOT NULL,

    AppliedValue DECIMAL(20,8) NULL,
    AppliedUnitOfMeasureId INT NULL,

    AsFoundValue DECIMAL(20,8) NULL,
    AsFoundUnitOfMeasureId INT NULL,

    AsLeftValue DECIMAL(20,8) NULL,
    AsLeftUnitOfMeasureId INT NULL,

    ErrorValue DECIMAL(20,8) NULL,
    ErrorPercentage DECIMAL(12,6) NULL,

    AcceptanceLimit DECIMAL(20,8) NULL,
    AcceptanceUnitOfMeasureId INT NULL,

    ResultCode VARCHAR(50) NULL,

    Remarks NVARCHAR(1000) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_CalibrationTestPoints_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_CalibrationTestPoints
        PRIMARY KEY (CalibrationTestPointId),

    CONSTRAINT UQ_CalibrationTestPoints_Sequence
        UNIQUE (CalibrationId, TestSequence),

    CONSTRAINT FK_CalibrationTestPoints_Calibration
        FOREIGN KEY (CalibrationId)
        REFERENCES event.CalibrationRecords(CalibrationId),

    CONSTRAINT FK_CalibrationTestPoints_AppliedUOM
        FOREIGN KEY (AppliedUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT FK_CalibrationTestPoints_AsFoundUOM
        FOREIGN KEY (AsFoundUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT FK_CalibrationTestPoints_AsLeftUOM
        FOREIGN KEY (AsLeftUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT FK_CalibrationTestPoints_AcceptanceUOM
        FOREIGN KEY (AcceptanceUnitOfMeasureId)
        REFERENCES ref.UnitOfMeasure(UnitOfMeasureId),

    CONSTRAINT CK_CalibrationTestPoints_TestSequence
        CHECK (TestSequence > 0)
);
GO