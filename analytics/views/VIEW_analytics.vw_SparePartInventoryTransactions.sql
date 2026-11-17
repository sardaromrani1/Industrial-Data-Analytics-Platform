-- Inventory Transaction View
CREATE VIEW analytics.vw_SparePartInventoryTransactions
AS
SELECT
    t.InventoryTransactionId,

    t.SparePartId,
    sp.PartNumber,
    sp.PartName,

    t.InventoryLocationId,
    t.TransactionTypeCode,
    t.TransactionDateTime,

    t.Quantity,
    t.UnitOfMeasureId,

    t.UnitCost,
    t.CurrencyId,

    t.ReferenceDocumentNumber,
    t.WorkOrderNumber,

    t.MaintenanceId,
    t.FailureId,

    t.PersonnelId,
    t.SupplierId,

    t.BatchNumber,
    t.SerialNumber,
    t.ExpiryDate

FROM inv.InventoryTransactions AS t
INNER JOIN dbo.SpareParts AS sp
    ON sp.SparePartId = t.SparePartId;
GO