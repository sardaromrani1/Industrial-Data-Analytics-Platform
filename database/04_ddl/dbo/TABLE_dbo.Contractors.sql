CREATE TABLE dbo.Contractors
(
    ContractorId        INT IDENTITY(1,1) NOT NULL,

    ContractorCode      VARCHAR(50) NOT NULL,
    ContractorName      NVARCHAR(200) NOT NULL,

    ContactInformation  NVARCHAR(500) NULL,

    QualificationStatusCode VARCHAR(50) NULL,

    IsApproved          BIT NOT NULL
        CONSTRAINT DF_Contractors_IsApproved DEFAULT (0),

    IsActive            BIT NOT NULL
        CONSTRAINT DF_Contractors_IsActive DEFAULT (1),

    Notes               NVARCHAR(MAX) NULL,

    CreatedDateTime     DATETIME2(0) NOT NULL
        CONSTRAINT DF_Contractors_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime     DATETIME2(0) NULL,

    CONSTRAINT PK_Contractors
        PRIMARY KEY (ContractorId),

    CONSTRAINT UQ_Contractors_Code
        UNIQUE (ContractorCode),

    CONSTRAINT UQ_Contractors_Name
        UNIQUE (ContractorName)
);
GO