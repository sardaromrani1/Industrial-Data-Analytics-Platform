CREATE TABLE ref.LifecycleStatus
(
    LifecycleStatusCode VARCHAR(30) NOT NULL,
    LifecycleStatusName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,

    IsTerminal BIT NOT NULL
        CONSTRAINT DF_LifecycleStatus_IsTerminal DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_LifecycleStatus_IsActive DEFAULT (1),

    CONSTRAINT PK_LifecycleStatus
        PRIMARY KEY (LifecycleStatusCode),

    CONSTRAINT UQ_LifecycleStatus_Name
        UNIQUE (LifecycleStatusName)
);
GO