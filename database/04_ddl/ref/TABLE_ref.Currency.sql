CREATE TABLE ref.Currency
(
    CurrencyId       INT IDENTITY(1,1) NOT NULL,
    CurrencyCode     VARCHAR(3) NOT NULL,
    CurrencyName     NVARCHAR(100) NOT NULL,
    Symbol           NVARCHAR(10) NULL,
    IsActive         BIT NOT NULL
        CONSTRAINT DF_Currency_IsActive DEFAULT (1),

    CreatedDateTime  DATETIME2(0) NOT NULL
        CONSTRAINT DF_Currency_CreatedDateTime DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Currency
        PRIMARY KEY (CurrencyId),

    CONSTRAINT UQ_Currency_CurrencyCode
        UNIQUE (CurrencyCode)
);
GO