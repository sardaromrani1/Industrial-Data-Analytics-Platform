-- Instrument Lifecycle View
CREATE VIEW analytics.vw_InstrumentLifecycleEvents
AS
SELECT
    l.InstrumentLifecycleId,
    l.InstrumentId,

    i.TagNumber,
    i.InstrumentTypeId,
    i.UnitId,
    i.SubSystemId,

    l.LifecycleStatusCode,
    l.EffectiveFrom,
    l.EffectiveTo,

    l.ReasonCode,
    l.WorkOrderNumber

FROM event.InstrumentLifecycle AS l
INNER JOIN dbo.Instruments AS i
    ON i.InstrumentId = l.InstrumentId;
GO