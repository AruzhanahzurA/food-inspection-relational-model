SELECT
    i.inspector_id,
    i.name AS inspector_name,
    COUNT(DISTINCT iv.inspection_id) AS total_inspections,
    COUNT(DISTINCT fi.fine_id) AS fines_issued,
    ROUND(COUNT(DISTINCT fi.fine_id) * 1.0 / COUNT(DISTINCT iv.inspection_id), 2) AS fines_per_inspection
FROM project.inspector i
JOIN project.inspector_inspection ii
    ON i.inspector_id = ii.inspector_id
JOIN project.inspection_visit iv
    ON ii.inspection_id = iv.inspection_id
LEFT JOIN project.finding f
    ON iv.inspection_id = f.inspection_id
LEFT JOIN project.fine fi
    ON f.finding_id = fi.finding_id
GROUP BY i.inspector_id, i.name
ORDER BY fines_per_inspection DESC;
