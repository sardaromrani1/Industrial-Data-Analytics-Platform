CREATE TABLE doc.Documents
(
    DocumentId              BIGINT IDENTITY(1,1) NOT NULL,

    DocumentNumber          VARCHAR(100) NOT NULL,

    DocumentTitle           NVARCHAR(300) NOT NULL,

    DocumentTypeCode        VARCHAR(50) NOT NULL,

    DocumentCategoryCode    VARCHAR(50) NULL,

    RevisionNumber          VARCHAR(50) NULL,

    DocumentStatusCode      VARCHAR(50) NULL,

    IssueDate               DATE NULL,

    EffectiveFrom           DATE NULL,

    EffectiveTo             DATE NULL,

    IssuingOrganization     NVARCHAR(200) NULL,

    AuthorName              NVARCHAR(200) NULL,

    Description             NVARCHAR(1000) NULL,

    ConfidentialityCode     VARCHAR(50) NULL,

    IsControlledDocument    BIT NOT NULL
        CONSTRAINT DF_Documents_IsControlledDocument
        DEFAULT (0),

    IsActive                BIT NOT NULL
        CONSTRAINT DF_Documents_IsActive
        DEFAULT (1),

    CreatedDateTime         DATETIME2(0) NOT NULL
        CONSTRAINT DF_Documents_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy               INT NULL,

    UpdatedDateTime         DATETIME2(0) NULL,

    UpdatedBy               INT NULL,

    CONSTRAINT PK_Documents
        PRIMARY KEY (DocumentId),

    CONSTRAINT UQ_Documents_DocumentNumber
        UNIQUE (DocumentNumber),

    CONSTRAINT FK_Documents_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_Documents_UpdatedBy
        FOREIGN KEY (UpdatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_Documents_EffectiveDates
        CHECK
        (
            EffectiveTo IS NULL
            OR EffectiveFrom IS NULL
            OR EffectiveTo >= EffectiveFrom
        )
);
GO