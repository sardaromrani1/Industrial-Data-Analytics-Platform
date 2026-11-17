-- . Calibration Event View
CREATE VIEW analytics.vw_InstrumentCalibrationEvents
AS
SELECT
    c.CalibrationId,
    c.InstrumentId,

    i.TagNumber,
    i.InstrumentTypeId,
    i.UnitId,
    i.SubSystemId,

    c.CalibrationDate,
    c.CalibrationTypeCode,
    c.CalibrationStatusCode,

    c.WorkOrderNumber,
    c.PerformedByPersonnelId,
    c.ReferenceEquipmentId,

    c.AsFoundConditionCode,
    c.AsLeftConditionCode,
    c.ResultCode,

    c.NextCalibrationDate

FROM event.CalibrationRecords AS c
INNER JOIN dbo.Instruments AS i
    ON i.InstrumentId = c.InstrumentId;
GO
