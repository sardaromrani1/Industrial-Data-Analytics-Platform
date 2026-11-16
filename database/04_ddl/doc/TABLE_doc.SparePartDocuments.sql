CREATE TABLE doc.SparePartDocuments
(
    SparePartDocumentId     BIGINT IDENTITY(1,1) NOT NULL,

    SparePartId             INT NOT NULL,
    DocumentId              BIGINT NOT NULL,

    DocumentRoleCode        VARCHAR(50) NULL,

    IsPrimaryDocument       BIT NOT NULL DEFAULT (0),
    IsActive                BIT NOT NULL DEFAULT (1),

    EffectiveFrom           DATE NULL,
    EffectiveTo             DATE NULL,

    Notes                   NVARCHAR(500) NULL,

    CreatedDateTime         DATETIME2(0) NOT NULL
                            DEFAULT (SYSUTCDATETIME()),

    CreatedBy               INT NULL,

    UpdatedDateTime         DATETIME2(0) NULL,
    UpdatedBy               INT NULL,

    CONSTRAINT PK_SparePartDocuments
        PRIMARY KEY (SparePartDocumentId),

    CONSTRAINT FK_SparePartDocuments_SparePart
        FOREIGN KEY (SparePartId)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartDocuments_Document
        FOREIGN KEY (DocumentId)
        REFERENCES doc.Documents(DocumentId),

    CONSTRAINT FK_SparePartDocuments_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_SparePartDocuments_UpdatedBy
        FOREIGN KEY (UpdatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT UQ_SparePartDocuments_SparePart_Document
        UNIQUE (SparePartId, DocumentId),

    CONSTRAINT CK_SparePartDocuments_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO