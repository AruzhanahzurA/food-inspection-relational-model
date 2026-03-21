SET search_path TO project;

CREATE OR REPLACE VIEW v_inspection_lifecycle AS
SELECT
    e.name                          AS establishment_name,
    ad.city,
    iv1.inspection_id               AS routine_inspection_id,
    iv1.inspection_date             AS routine_date,
    iv1.overall_score               AS routine_score,
    iv1.compliance_status           AS routine_compliance,
    iv1.enforcement_action_type     AS enforcement_action,
    COUNT(DISTINCT f1.finding_id)   AS routine_findings,
    iv2.inspection_id               AS followup_inspection_id,
    iv2.inspection_date             AS followup_date,
    iv2.overall_score               AS followup_score,
    iv2.compliance_status           AS followup_compliance,
    COUNT(DISTINCT f2.finding_id)   AS followup_findings,
    iv2.inspection_date - iv1.inspection_date AS days_between_inspections
FROM inspection_visit iv1
JOIN establishment e
    ON iv1.establishment_id = e.establishment_id
JOIN address ad
    ON e.address_id = ad.address_id
JOIN inspection_visit iv2
    ON iv2.original_inspection_id = iv1.inspection_id
LEFT JOIN finding f1
    ON iv1.inspection_id = f1.inspection_id
LEFT JOIN finding f2
    ON iv2.inspection_id = f2.inspection_id
WHERE iv1.inspection_type = 'routine'
GROUP BY
    e.name, ad.city,
    iv1.inspection_id, iv1.inspection_date, iv1.overall_score,
    iv1.compliance_status, iv1.enforcement_action_type,
    iv2.inspection_id, iv2.inspection_date, iv2.overall_score,
    iv2.compliance_status
ORDER BY e.name, iv1.inspection_date;

CREATE OR REPLACE VIEW v_institution_activity AS
SELECT
    inst.institution_id,
    inst.name                           AS institution_name,
    inst.institution_type,
    inst.jurisdiction_area,
    COUNT(DISTINCT iv.inspection_id)    AS total_inspections,
    COUNT(DISTINCT i.inspector_id)      AS total_inspectors,
    SUM(CASE WHEN iv.compliance_status = 'compliant'
        THEN 1 ELSE 0 END)              AS compliant_count,
    SUM(CASE WHEN iv.compliance_status = 'minor_non_compliance'
        THEN 1 ELSE 0 END)              AS minor_non_compliance_count,
    SUM(CASE WHEN iv.compliance_status = 'major_non_compliance'
        THEN 1 ELSE 0 END)              AS major_non_compliance_count,
    COUNT(DISTINCT fi.fine_id)          AS total_fines_issued,
    COALESCE(SUM(fi.amount), 0)         AS total_fines_amount
FROM inspection_institution inst
LEFT JOIN inspection_visit iv
    ON inst.institution_id = iv.institution_id
LEFT JOIN inspector_inspection ii
    ON iv.inspection_id = ii.inspection_id
LEFT JOIN inspector i
    ON ii.inspector_id = i.inspector_id
LEFT JOIN finding f
    ON iv.inspection_id = f.inspection_id
LEFT JOIN fine fi
    ON f.finding_id = fi.finding_id
GROUP BY
    inst.institution_id, inst.name,
    inst.institution_type, inst.jurisdiction_area
ORDER BY total_inspections DESC;

CREATE OR REPLACE VIEW v_open_findings AS
SELECT
    e.name                  AS establishment_name,
    ad.city,
    iv.inspection_id,
    iv.inspection_date,
    iv.inspection_type,
    f.finding_id,
    f.severity_assessed,
    v.code                  AS violation_code,
    v.description           AS violation_description,
    v.risk_category,
    f.notes,
    f.status                AS finding_status,
    fi.fine_id,
    fi.amount               AS fine_amount,
    fi.payment_status
FROM finding f
JOIN inspection_visit iv
    ON f.inspection_id = iv.inspection_id
JOIN establishment e
    ON iv.establishment_id = e.establishment_id
JOIN address ad
    ON e.address_id = ad.address_id
JOIN violation v
    ON f.violation_id = v.violation_id
LEFT JOIN fine fi
    ON f.finding_id = fi.finding_id
WHERE f.status = 'open'
ORDER BY
    CASE f.severity_assessed
        WHEN 'critical' THEN 1
        WHEN 'major'    THEN 2
        WHEN 'minor'    THEN 3
    END,
    iv.inspection_date DESC;

CREATE OR REPLACE VIEW v_unpaid_fines AS
SELECT
    e.name                  AS establishment_name,
    ad.city,
    o.owner_name,
    fi.fine_id,
    fi.amount,
    fi.issue_date,
    fi.due_date,
    fi.payment_status,
    v.code                  AS violation_code,
    f.severity_assessed,
    CASE WHEN a.appeal_id IS NOT NULL
        THEN 'Yes' ELSE 'No'
    END                     AS has_appeal,
    a.outcome               AS appeal_outcome
FROM fine fi
JOIN finding f
    ON fi.finding_id = f.finding_id
JOIN violation v
    ON f.violation_id = v.violation_id
JOIN inspection_visit iv
    ON f.inspection_id = iv.inspection_id
JOIN establishment e
    ON iv.establishment_id = e.establishment_id
JOIN address ad
    ON e.address_id = ad.address_id
JOIN ownership o
    ON e.ownership_id = o.ownership_id
LEFT JOIN appeal a
    ON fi.fine_id = a.fine_id
WHERE fi.payment_status IN ('pending', 'overdue')
ORDER BY
    CASE fi.payment_status
        WHEN 'overdue' THEN 1
        WHEN 'pending' THEN 2
    END,
    fi.amount DESC;

CREATE OR REPLACE VIEW v_violation_frequency AS
SELECT
    v.violation_id,
    v.code,
    v.description,
    v.severity_level,
    v.risk_category,
    COUNT(f.finding_id)             AS total_occurrences,
    COUNT(DISTINCT fi.fine_id)      AS times_fined,
    COALESCE(SUM(fi.amount), 0)     AS total_fines_generated,
    ROUND(
        COUNT(DISTINCT fi.fine_id) * 1.0
        / NULLIF(COUNT(f.finding_id), 0), 2
    )                               AS fine_rate
FROM violation v
LEFT JOIN finding f
    ON v.violation_id = f.violation_id
LEFT JOIN fine fi
    ON f.finding_id = fi.finding_id
GROUP BY
    v.violation_id, v.code, v.description,
    v.severity_level, v.risk_category
ORDER BY total_occurrences DESC;

CREATE OR REPLACE VIEW v_establishment_risk_profile AS
SELECT
    e.establishment_id,
    e.name                              AS establishment_name,
    e.type                              AS establishment_type,
    ad.city,
    o.owner_name,
    e.status,
    COUNT(DISTINCT iv.inspection_id)    AS total_inspections,
    ROUND(AVG(iv.overall_score), 1)     AS avg_score,
    MIN(iv.overall_score)               AS lowest_score,
    MAX(iv.overall_score)               AS highest_score,
    COUNT(DISTINCT f.finding_id)        AS total_findings,
    COUNT(DISTINCT fi.fine_id)          AS total_fines,
    COALESCE(SUM(fi.amount), 0)         AS total_fines_amount,
    COUNT(DISTINCT a.appeal_id)         AS total_appeals,
    ROUND(
        COUNT(DISTINCT f.finding_id) * 1.0
        / NULLIF(COUNT(DISTINCT iv.inspection_id), 0), 2
    )                                   AS findings_per_inspection,
    SUM(CASE WHEN iv.compliance_status = 'major_non_compliance'
        THEN 1 ELSE 0 END)              AS major_non_compliance_count
FROM establishment e
JOIN address ad
    ON e.address_id = ad.address_id
JOIN ownership o
    ON e.ownership_id = o.ownership_id
LEFT JOIN inspection_visit iv
    ON e.establishment_id = iv.establishment_id
LEFT JOIN finding f
    ON iv.inspection_id = f.inspection_id
LEFT JOIN fine fi
    ON f.finding_id = fi.finding_id
LEFT JOIN appeal a
    ON fi.fine_id = a.fine_id
GROUP BY
    e.establishment_id, e.name, e.type,
    ad.city, o.owner_name, e.status
ORDER BY total_fines_amount DESC, findings_per_inspection DESC;

CREATE OR REPLACE VIEW v_compliance_trend AS
SELECT
    e.name                  AS establishment_name,
    ad.city,
    iv.inspection_id,
    iv.inspection_date,
    iv.inspection_type,
    iv.overall_score,
    iv.compliance_status,
    findings_per_inspection.finding_count   AS findings_in_inspection,
    ROUND(AVG(iv.overall_score) OVER (
        PARTITION BY e.establishment_id
        ORDER BY iv.inspection_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                                   AS rolling_avg_score,
    iv.overall_score - LAG(iv.overall_score) OVER (
        PARTITION BY e.establishment_id
        ORDER BY iv.inspection_date
    )                                       AS score_change_from_previous
FROM inspection_visit iv
JOIN establishment e
    ON iv.establishment_id = e.establishment_id
JOIN address ad
    ON e.address_id = ad.address_id
JOIN (
    SELECT inspection_id, COUNT(finding_id) AS finding_count
    FROM finding
    GROUP BY inspection_id
    ) findings_per_inspection
    ON iv.inspection_id = findings_per_inspection.inspection_id
ORDER BY e.name, iv.inspection_date;

-- 1. inspection (for Improvement after a fine query)
WITH i1 AS (
  INSERT INTO project.inspection_visit (
    inspection_id, establishment_id, institution_id, inspection_date,
    inspection_type, overall_score, enforcement_action_type,
    compliance_status, supplier_verification_status, original_inspection_id
  )
  VALUES (900, 100, 100, DATE '2025-10-01', 'routine', 40,
          'improvement_order', 'major_non_compliance', 'issues_found', NULL)
  RETURNING inspection_id
),
i2 AS (
  INSERT INTO project.inspection_visit (
    inspection_id, establishment_id, institution_id, inspection_date,
    inspection_type, overall_score, enforcement_action_type,
    compliance_status, supplier_verification_status, original_inspection_id
  )
  VALUES (901, 100, 100, DATE '2025-10-15', 'follow_up', 85,
          'none', 'minor_non_compliance', 'verified', 900)
  RETURNING inspection_id
)
INSERT INTO project.inspector_inspection (inspector_id, inspection_id)
SELECT 100, inspection_id FROM i1
UNION ALL
SELECT 100, inspection_id FROM i2;

-- findings
INSERT INTO project.finding VALUES
(900, 900, 100, 'major', 'Issue 1', 'open'),
(901, 900, 101, 'major', 'Issue 2', 'open'),
(902, 900, 102, 'major', 'Issue 3', 'open'),

(903, 901, 100, 'minor', 'Improved', 'open');


-- fines
INSERT INTO project.fine VALUES
(900, 900, 2000, DATE '2025-10-02', DATE '2025-11-02', 'paid');