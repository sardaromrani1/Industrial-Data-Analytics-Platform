CREATE TABLE doc.DocumentFiles
(
    DocumentFileId          BIGINT IDENTITY(1,1) NOT NULL,

    DocumentId              BIGINT NOT NULL,

    FileName                NVARCHAR(255) NOT NULL,

    FileExtension           VARCHAR(20) NULL,

    MimeType                VARCHAR(100) NULL,

    FileSizeBytes           BIGINT NULL,

    StorageTypeCode         VARCHAR(50) NOT NULL,

    StorageLocation         NVARCHAR(1000) NOT NULL,

    FileHash                VARCHAR(128) NULL,

    FileVersion             VARCHAR(50) NULL,

    IsPrimaryFile           BIT NOT NULL
        CONSTRAINT DF_DocumentFiles_IsPrimaryFile
        DEFAULT (0),

    IsCurrentVersion        BIT NOT NULL
        CONSTRAINT DF_DocumentFiles_IsCurrentVersion
        DEFAULT (1),

    UploadedDateTime        DATETIME2(0) NOT NULL
        CONSTRAINT DF_DocumentFiles_UploadedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UploadedBy              INT NULL,

    Notes                   NVARCHAR(500) NULL,

    CONSTRAINT PK_DocumentFiles
        PRIMARY KEY (DocumentFileId),

    CONSTRAINT FK_DocumentFiles_Document
        FOREIGN KEY (DocumentId)
        REFERENCES doc.Documents(DocumentId),

    CONSTRAINT FK_DocumentFiles_UploadedBy
        FOREIGN KEY (UploadedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_DocumentFiles_FileSize
        CHECK
        (
            FileSizeBytes IS NULL
            OR FileSizeBytes >= 0
        )
);
GO
