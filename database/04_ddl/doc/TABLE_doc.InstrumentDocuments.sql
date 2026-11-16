CREATE TABLE doc.InstrumentDocuments
(
    InstrumentDocumentId    BIGINT IDENTITY(1,1) NOT NULL,

    InstrumentId            INT NOT NULL,

    DocumentId              BIGINT NOT NULL,

    DocumentRoleCode        VARCHAR(50) NULL,

    IsPrimaryDocument       BIT NOT NULL
        CONSTRAINT DF_InstrumentDocuments_IsPrimaryDocument
        DEFAULT (0),

    IsActive                BIT NOT NULL
        CONSTRAINT DF_InstrumentDocuments_IsActive
        DEFAULT (1),

    EffectiveFrom           DATE NULL,

    EffectiveTo             DATE NULL,

    Notes                   NVARCHAR(500) NULL,

    CreatedDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentDocuments_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy               INT NULL,

    UpdatedDateTime         DATETIME2(0) NULL,

    UpdatedBy               INT NULL,

    CONSTRAINT PK_InstrumentDocuments
        PRIMARY KEY (InstrumentDocumentId),

    CONSTRAINT FK_InstrumentDocuments_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentDocuments_Document
        FOREIGN KEY (DocumentId)
        REFERENCES doc.Documents(DocumentId),

    CONSTRAINT FK_InstrumentDocuments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_InstrumentDocuments_UpdatedBy
        FOREIGN KEY (UpdatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT UQ_InstrumentDocuments_Instrument_Document
        UNIQUE (InstrumentId, DocumentId),

    CONSTRAINT CK_InstrumentDocuments_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO