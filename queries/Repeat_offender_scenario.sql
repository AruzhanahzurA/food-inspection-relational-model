SELECT
    e.establishment_id,
    e.name AS establishment_name,
    iv1.inspection_id AS first_inspection_id,
    iv1.inspection_date AS first_inspection_date,
    fi.fine_id,
    fi.amount AS first_fine_amount,
    iv2.inspection_id AS followup_inspection_id,
    iv2.inspection_date AS followup_inspection_date,
    COUNT(f2.finding_id) AS followup_findings_count
FROM project.establishment e
JOIN project.inspection_visit iv1
    ON e.establishment_id = iv1.establishment_id
JOIN project.finding f1
    ON iv1.inspection_id = f1.inspection_id
JOIN project.fine fi
    ON f1.finding_id = fi.finding_id
JOIN project.inspection_visit iv2
    ON iv2.original_inspection_id = iv1.inspection_id
LEFT JOIN project.finding f2
    ON iv2.inspection_id = f2.inspection_id
GROUP BY
    e.establishment_id,
    e.name,
    iv1.inspection_id,
    iv1.inspection_date,
    fi.fine_id,
    fi.amount,
    iv2.inspection_id,
    iv2.inspection_date
HAVING COUNT(f2.finding_id) > 0
ORDER BY fi.amount DESC, iv2.inspection_date;
