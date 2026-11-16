CREATE TABLE doc.FailureDocuments
(
    FailureDocumentId       BIGINT IDENTITY(1,1) NOT NULL,

    FailureId               INT NOT NULL,

    DocumentId              BIGINT NOT NULL,

    DocumentRoleCode        VARCHAR(50) NULL,

    IsPrimaryDocument       BIT NOT NULL
        CONSTRAINT DF_FailureDocuments_IsPrimaryDocument
        DEFAULT (0),

    IsActive                BIT NOT NULL
        CONSTRAINT DF_FailureDocuments_IsActive
        DEFAULT (1),

    EffectiveFrom           DATE NULL,

    EffectiveTo             DATE NULL,

    Notes                   NVARCHAR(500) NULL,

    CreatedDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_FailureDocuments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy               INT NULL,

    UpdatedDateTime         DATETIME2(0) NULL,

    UpdatedBy               INT NULL,

    CONSTRAINT PK_FailureDocuments
        PRIMARY KEY (FailureDocumentId),

    CONSTRAINT FK_FailureDocuments_Failure
        FOREIGN KEY (FailureId)
        REFERENCES event.FailureRecords(FailureId),

    CONSTRAINT FK_FailureDocuments_Document
        FOREIGN KEY (DocumentId)
        REFERENCES doc.Documents(DocumentId),

    CONSTRAINT FK_FailureDocuments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_FailureDocuments_UpdatedBy
        FOREIGN KEY (UpdatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT UQ_FailureDocuments_Failure_Document
        UNIQUE (FailureId, DocumentId),

    CONSTRAINT CK_FailureDocuments_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO