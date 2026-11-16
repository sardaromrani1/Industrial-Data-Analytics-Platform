CREATE TABLE rel.SparePartInterchangeability
(
    SparePartId1 INT NOT NULL,
    SparePartId2 INT NOT NULL,

    InterchangeabilityTypeCode VARCHAR(50) NOT NULL,

    IsPreferred BIT NOT NULL
        CONSTRAINT DF_SparePartInterchangeability_IsPreferred DEFAULT (0),

    IsActive BIT NOT NULL
        CONSTRAINT DF_SparePartInterchangeability_IsActive DEFAULT (1),

    CreatedDateTime DATETIME2(0) NOT NULL
        CONSTRAINT DF_SparePartInterchangeability_CreatedDateTime
        DEFAULT (SYSUTCDATETIME()),

    CreatedBy INT NULL,

    CONSTRAINT PK_SparePartInterchangeability
        PRIMARY KEY (SparePartId1, SparePartId2),

    CONSTRAINT FK_SparePartInterchangeability_Part1
        FOREIGN KEY (SparePartId1)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartInterchangeability_Part2
        FOREIGN KEY (SparePartId2)
        REFERENCES dbo.SpareParts(SparePartId),

    CONSTRAINT FK_SparePartInterchangeability_CreatedBy
        FOREIGN KEY (CreatedBy)
        REFERENCES dbo.Personnel(PersonnelId),

    CONSTRAINT CK_SparePartInterchangeability_NotSelf
        CHECK (SparePartId1 <> SparePartId2)
);
GO