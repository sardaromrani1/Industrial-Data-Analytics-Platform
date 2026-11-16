CREATE TABLE event.MaintenanceLabor
(
    MaintenanceLaborId INT IDENTITY(1,1) NOT NULL,

    MaintenanceId INT NOT NULL,

    PersonnelId INT NOT NULL,

    LaborRoleCode VARCHAR(50) NULL,

    LaborHours DECIMAL(12,2) NOT NULL,

    HourlyCost DECIMAL(18,2) NULL,

    LaborCost AS
    (
        CASE
            WHEN HourlyCost IS NOT NULL
            THEN LaborHours * HourlyCost
            ELSE NULL
        END
    ) PERSISTED,

    CurrencyId INT NULL,

    Remarks NVARCHAR(1000) NULL,

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_MaintenanceLabor_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_MaintenanceLabor
        PRIMARY KEY (MaintenanceLaborId),

    CONSTRAINT FK_MaintenanceLabor_Maintenance
        FOREIGN KEY (MaintenanceId)
        REFERENCES event.MaintenanceRecords(MaintenanceId),

    CONSTRAINT FK_MaintenanceLabor_Personnel
        FOREIGN KEY (PersonnelId)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT FK_MaintenanceLabor_Currency
        FOREIGN KEY (CurrencyId)
        REFERENCES ref.Currency(CurrencyId),

    CONSTRAINT CK_MaintenanceLabor_Hours
        CHECK (LaborHours > 0),

    CONSTRAINT CK_MaintenanceLabor_HourlyCost
        CHECK
        (
            HourlyCost IS NULL
            OR HourlyCost >= 0
        )
);
GO