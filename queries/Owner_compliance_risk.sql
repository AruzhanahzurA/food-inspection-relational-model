SELECT
    o.owner_name,
    o.type AS ownership_type,
    COUNT(DISTINCT e.establishment_id) AS number_of_establishments,
    COUNT(DISTINCT iv.inspection_id) AS total_inspections,
    COUNT(f.finding_id) AS total_findings,
    COUNT(DISTINCT fi.fine_id) AS total_fines,
    ROUND(COUNT(f.finding_id) * 1.0 / NULLIF(COUNT(DISTINCT iv.inspection_id), 0), 2) AS findings_per_inspection
FROM ownership o
JOIN establishment e
    ON o.ownership_id = e.ownership_id
LEFT JOIN inspection_visit iv
    ON e.establishment_id = iv.establishment_id
LEFT JOIN finding f
    ON iv.inspection_id = f.inspection_id
LEFT JOIN fine fi
    ON f.finding_id = fi.finding_id
GROUP BY
    o.owner_name,
    o.type
HAVING COUNT(DISTINCT e.establishment_id) > 1
ORDER BY total_fines DESC, findings_per_inspection DESC;

