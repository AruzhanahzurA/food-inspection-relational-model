SELECT
    e.name AS establishment_name,
    iv.inspection_id,
    iv.inspection_date,
    fi.fine_id,
    fi.amount,
    fi.payment_status,
    a.appeal_id,
    a.appeal_date,
    a.decision_date,
    a.outcome
FROM project.appeal a
JOIN project.fine fi
    ON a.fine_id = fi.fine_id
JOIN project.finding f
    ON fi.finding_id = f.finding_id
JOIN project.inspection_visit iv
    ON f.inspection_id = iv.inspection_id
JOIN project.establishment e
    ON iv.establishment_id = e.establishment_id
ORDER BY a.decision_date;
