SELECT
    ad.city,
    COUNT(DISTINCT iv.inspection_id) AS total_inspections,
    COUNT(f.finding_id) AS total_violations,
    ROUND(COUNT(f.finding_id) * 1.0 / COUNT(DISTINCT iv.inspection_id), 2) AS violations_per_inspection
FROM address ad
JOIN establishment e
    ON ad.address_id = e.address_id
JOIN inspection_visit iv
    ON e.establishment_id = iv.establishment_id
LEFT JOIN finding f
    ON iv.inspection_id = f.inspection_id
GROUP BY ad.city
ORDER BY violations_per_inspection DESC, total_violations DESC;
