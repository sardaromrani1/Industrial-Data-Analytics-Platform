CREATE TABLE doc.MaintenanceDocuments
(
    MaintenanceDocumentId   BIGINT IDENTITY(1,1) NOT NULL,

    MaintenanceId           INT NOT NULL,

    DocumentId              BIGINT NOT NULL,

    DocumentRoleCode        VARCHAR(50) NULL,

    IsPrimaryDocument       BIT NOT NULL
        CONSTRAINT DF_MaintenanceDocuments_IsPrimaryDocument
        DEFAULT (0),

    IsActive                BIT NOT NULL
        CONSTRAINT DF_MaintenanceDocuments_IsActive
        DEFAULT (1),

    EffectiveFrom           DATE NULL,

    EffectiveTo             DATE NULL,

    Notes                   NVARCHAR(500) NULL,

    CreatedDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_MaintenanceDocuments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy               INT NULL,

    UpdatedDateTime         DATETIME2(0) NULL,

    UpdatedBy               INT NULL,

    CONSTRAINT PK_MaintenanceDocuments
        PRIMARY KEY (MaintenanceDocumentId),

    CONSTRAINT FK_MaintenanceDocuments_Maintenance
        FOREIGN KEY (MaintenanceId)
        REFERENCES event.MaintenanceRecords(MaintenanceId),

    CONSTRAINT FK_MaintenanceDocuments_Document
        FOREIGN KEY (DocumentId)
        REFERENCES doc.Documents(DocumentId),

    CONSTRAINT FK_MaintenanceDocuments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_MaintenanceDocuments_UpdatedBy
        FOREIGN KEY (UpdatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT UQ_MaintenanceDocuments_Maintenance_Document
        UNIQUE (MaintenanceId, DocumentId),

    CONSTRAINT CK_MaintenanceDocuments_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO