CREATE TABLE event.InstrumentBypassHistory
(
    InstrumentBypassHistoryId INT IDENTITY(1,1) NOT NULL,

    InstrumentId              INT NOT NULL,

    BypassStartDateTime       DATETIME2(0) NOT NULL,
    BypassEndDateTime         DATETIME2(0) NULL,

    BypassReasonCode          VARCHAR(50) NULL,

    AuthorizedByPersonnelId   INT NULL,

    WorkOrderNumber           VARCHAR(100) NULL,

    Remarks                   NVARCHAR(MAX) NULL,

    CreatedDateTime            DATETIME2(0) NOT NULL
        CONSTRAINT DF_InstrumentBypassHistory_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy                  INT NULL,

    CONSTRAINT PK_InstrumentBypassHistory
        PRIMARY KEY (InstrumentBypassHistoryId),

    CONSTRAINT FK_InstrumentBypassHistory_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES dbo.Instruments(InstrumentId),

    CONSTRAINT FK_InstrumentBypassHistory_AuthorizedBy
        FOREIGN KEY (AuthorizedByPersonnelId)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_InstrumentBypassHistory_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_InstrumentBypassHistory_DateRange
        CHECK
        (
            BypassEndDateTime IS NULL
            OR BypassEndDateTime >= BypassStartDateTime
        )
);
GO