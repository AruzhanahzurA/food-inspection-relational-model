SELECT
    e.establishment_id,
    e.name AS establishment_name,
    iv1.inspection_id AS fined_inspection_id,
    iv1.inspection_date AS fined_inspection_date,
    SUM(fi.amount) AS total_fine_amount,
    MAX(fi.amount) AS max_fine_amount,
    COUNT(DISTINCT f1.finding_id) AS findings_before,
    iv2.inspection_id AS followup_inspection_id,
    iv2.inspection_date AS followup_inspection_date,
    COUNT(DISTINCT f2.finding_id) AS findings_after,
    COUNT(DISTINCT f1.finding_id) - COUNT(DISTINCT f2.finding_id) AS improvement
FROM project.establishment e
JOIN project.inspection_visit iv1
    ON e.establishment_id = iv1.establishment_id
JOIN project.finding f1
    ON iv1.inspection_id = f1.inspection_id
JOIN project.fine fi
    ON f1.finding_id = fi.finding_id
   AND fi.amount >= 1000
JOIN project.inspection_visit iv2
    ON iv2.original_inspection_id = iv1.inspection_id
LEFT JOIN project.finding f2
    ON iv2.inspection_id = f2.inspection_id
GROUP BY
    e.establishment_id,
    e.name,
    iv1.inspection_id,
    iv1.inspection_date,
    iv2.inspection_id,
    iv2.inspection_date
HAVING COUNT(DISTINCT f2.finding_id) < COUNT(DISTINCT f1.finding_id)
ORDER BY improvement DESC, total_fine_amount DESC;

