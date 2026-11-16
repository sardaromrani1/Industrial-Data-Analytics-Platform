CREATE TABLE dbo.Personnel
(
    PersonnelId       INT IDENTITY(1,1) NOT NULL,
    PersonnelCode     VARCHAR(50) NOT NULL,

    FirstName         NVARCHAR(100) NOT NULL,
    LastName          NVARCHAR(100) NOT NULL,

    EmployeeNumber    VARCHAR(50) NULL,
    EmployerName      NVARCHAR(200) NULL,
    DepartmentName    NVARCHAR(200) NULL,
    JobTitle          NVARCHAR(200) NULL,

    Email             VARCHAR(320) NULL,
    Phone             VARCHAR(50) NULL,

    IsActive          BIT NOT NULL
        CONSTRAINT DF_Personnel_IsActive DEFAULT (1),

    CreatedDateTime   DATETIME2(0) NOT NULL
        CONSTRAINT DF_Personnel_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    UpdatedDateTime   DATETIME2(0) NULL,

    CONSTRAINT PK_Personnel
        PRIMARY KEY (PersonnelId),

    CONSTRAINT UQ_Personnel_PersonnelCode
        UNIQUE (PersonnelCode)
);
GO
