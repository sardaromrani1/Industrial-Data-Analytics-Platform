CREATE TABLE doc.CalibrationDocuments
(
    CalibrationDocumentId    BIGINT IDENTITY(1,1) NOT NULL,

    CalibrationId            INT NOT NULL,

    DocumentId               BIGINT NOT NULL,

    DocumentRoleCode         VARCHAR(50) NULL,

    IsPrimaryDocument        BIT NOT NULL
        CONSTRAINT DF_CalibrationDocuments_IsPrimaryDocument
        DEFAULT (0),

    IsActive                 BIT NOT NULL
        CONSTRAINT DF_CalibrationDocuments_IsActive
        DEFAULT (1),

    EffectiveFrom            DATE NULL,

    EffectiveTo              DATE NULL,

    Notes                    NVARCHAR(500) NULL,

    CreatedDateTime          DATETIME2(0) NOT NULL
        CONSTRAINT DF_CalibrationDocuments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy                INT NULL,

    UpdatedDateTime          DATETIME2(0) NULL,

    UpdatedBy                INT NULL,

    CONSTRAINT PK_CalibrationDocuments
        PRIMARY KEY (CalibrationDocumentId),

    CONSTRAINT FK_CalibrationDocuments_Calibration
        FOREIGN KEY (CalibrationId)
        REFERENCES event.CalibrationRecords(CalibrationId),

    CONSTRAINT FK_CalibrationDocuments_Document
        FOREIGN KEY (DocumentId)
        REFERENCES doc.Documents(DocumentId),

    CONSTRAINT FK_CalibrationDocuments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_CalibrationDocuments_UpdatedBy
        FOREIGN KEY (UpdatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT UQ_CalibrationDocuments_Calibration_Document
        UNIQUE (CalibrationId, DocumentId),

    CONSTRAINT CK_CalibrationDocuments_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO