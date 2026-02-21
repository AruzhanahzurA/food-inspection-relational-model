-- Show that violations lead to findings, which may lead to fines.
SELECT 
    iv.inspection_date,
    v.code AS violation_code,
    f.status AS finding_status,
    fi.amount AS fine_amount,
    fi.payment_status
FROM project.inspection_visit iv
JOIN project.finding f
    ON f.inspection_id = iv.inspection_id
JOIN project.violation v
    ON v.violation_id = f.violation_id
LEFT JOIN project.fine fi
    ON fi.finding_id = f.finding_id
ORDER BY iv.inspection_date;