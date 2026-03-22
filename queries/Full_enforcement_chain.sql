SELECT
    iv.inspection_id,
    iv.inspection_date,
    e.name AS establishment_name,
    v.code AS violation_code,
    v.description AS violation_description,
    f.finding_id,
    f.status AS finding_status,
    f.severity_assessed,
    fi.fine_id,
    fi.amount AS fine_amount,
    fi.issue_date AS fine_issue_date,
    fi.payment_status,
    a.appeal_id,
    a.appeal_date,
    a.decision_date,
    a.outcome AS appeal_outcome
FROM project.inspection_visit iv
JOIN project.establishment e
    ON iv.establishment_id = e.establishment_id
LEFT JOIN project.finding f
    ON iv.inspection_id = f.inspection_id
LEFT JOIN project.violation v
    ON f.violation_id = v.violation_id
LEFT JOIN project.fine fi
    ON f.finding_id = fi.finding_id
LEFT JOIN project.appeal a
    ON fi.fine_id = a.fine_id
ORDER BY iv.inspection_date, iv.inspection_id, f.finding_id;
