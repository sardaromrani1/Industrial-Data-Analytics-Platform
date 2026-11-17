-- Instrument Failure Events
CREATE VIEW analytics.vw_InstrumentFailureEvents
AS
SELECT
    f.FailureId,
    f.InstrumentId,
    i.TagNumber,
    i.InstrumentTypeId,
    i.UnitId,
    i.SubSystemId,

    f.FailureDate,
    f.FailureTypeCode,
    f.FailureModeCode,
    f.FailureCauseCode,
    f.FailureSeverityCode,
    f.DetectionMethodCode,

    f.FailureStartDateTime,
    f.FailureEndDateTime,
    f.DowntimeHours,
    f.RepairCost,
    f.CurrencyId,

    f.IsRepeatFailure,
    f.WorkOrderNumber

FROM event.FailureRecords AS f
INNER JOIN dbo.Instruments AS i
    ON i.InstrumentId = f.InstrumentId;
GO