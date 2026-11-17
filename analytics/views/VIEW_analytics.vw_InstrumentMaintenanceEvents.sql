-- Maintenance Event View
CREATE VIEW analytics.vw_InstrumentMaintenanceEvents
AS
SELECT
    m.MaintenanceId,
    m.InstrumentId,

    i.TagNumber,
    i.InstrumentTypeId,
    i.UnitId,
    i.SubSystemId,

    m.MaintenanceDate,
    m.MaintenanceTypeCode,
    m.MaintenanceCategoryCode,
    m.MaintenanceStatusCode,

    m.WorkOrderNumber,
    m.PriorityCode,
    m.FailureRelated,

    m.CompletionDate,
    m.DowntimeHours,

    m.LaborCost,
    m.MaterialCost,
    m.OtherCost,
    m.CurrencyId

FROM event.MaintenanceRecords AS m
INNER JOIN dbo.Instruments AS i
    ON i.InstrumentId = m.InstrumentId;
GO