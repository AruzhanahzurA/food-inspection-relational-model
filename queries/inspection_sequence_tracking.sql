-- Inspection lifecycle for one establishment: captures inspection sequences over time.
-- Show the original inspection and the follow-up inspection
-- referencing it through original_inspection_id.
SELECT
   e.name AS establishment,
   iv.inspection_id,
   iv.inspection_date,
   iv.inspection_type,
   iv.original_inspection_id
FROM project.establishment e
JOIN project.inspection_visit iv
   ON iv.establishment_id = e.establishment_id
ORDER BY iv.inspection_date;

