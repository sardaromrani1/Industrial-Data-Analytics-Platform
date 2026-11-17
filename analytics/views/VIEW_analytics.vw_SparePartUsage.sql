-- Spare Part Usage View
CREATE VIEW analytics.vw_SparePartUsage
AS
SELECT
    u.SparePartUsageId,
    u.InventoryTransactionId,

    u.SparePartId,
    sp.PartNumber,
    sp.PartName,

    u.InstrumentId,
    i.TagNumber,

    u.MaintenanceId,
    u.FailureId,

    u.QuantityUsed,
    u.UnitOfMeasureId,

    u.UnitCost,
    u.CurrencyId,

    u.UsageDateTime,
    u.PersonnelId,
    u.UsageReasonCode

FROM event.SparePartUsage AS u

INNER JOIN dbo.SpareParts AS sp
    ON sp.SparePartId = u.SparePartId

LEFT JOIN dbo.Instruments AS i
    ON i.InstrumentId = u.InstrumentId;
GO