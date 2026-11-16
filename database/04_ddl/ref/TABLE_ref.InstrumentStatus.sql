CREATE TABLE ref.InstrumentStatus
(
    StatusCode        VARCHAR(30) NOT NULL,
    StatusName        NVARCHAR(100) NOT NULL,
    Description       NVARCHAR(500) NULL,

    StatusCategoryCode VARCHAR(50) NULL,

    IsOperational     BIT NOT NULL
        CONSTRAINT DF_InstrumentStatus_IsOperational DEFAULT (0),

    IsActive          BIT NOT NULL
        CONSTRAINT DF_InstrumentStatus_IsActive DEFAULT (1),

    CONSTRAINT PK_InstrumentStatus
        PRIMARY KEY (StatusCode),

    CONSTRAINT UQ_InstrumentStatus_Name
        UNIQUE (StatusName)
);
GO