BEGIN;

-- ============================================================
-- 1. VALID SETUP DATA
-- ============================================================

INSERT INTO project.address (city, county, street, postcode)
VALUES ('Dublin', 'Dublin', 'Main Street 1', 'D01ABC1');

INSERT INTO project.contact_information (phone, email, website)
VALUES ('123456789', 'owner@test.ie', 'https://test.ie');

INSERT INTO project.contact_information (phone, email, website)
VALUES ('987654321', 'institution@test.ie', 'https://institution.ie');

INSERT INTO project.ownership (type, owner_name, owner_external_identifier)
VALUES ('company', 'Test Foods Ltd', 'CRO12345');

INSERT INTO project.establishment
(name, address_id, type, status, registration_date, ownership_id, contact_information_id)
values ('Test Restaurant',currval('project.address_address_id_seq'),'restaurant','active','2024-01-01',currval('project.ownership_ownership_id_seq'),
		currval('project.contact_information_contact_information_id_seq'));

INSERT INTO project.inspection_institution (name, institution_type, jurisdiction_area, address_id, contact_information_id)
values ('HSE Dublin','HSE_EHS','Dublin',currval('project.address_address_id_seq'),currval('project.contact_information_contact_information_id_seq'));

INSERT INTO project.inspector (institution_id, name, qualification_level, employment_start_date, employment_status)
values (currval('project.inspection_institution_institution_id_seq'),'John Inspector','standard','2022-01-01','active');

INSERT INTO project.registration (establishment_id, registration_type, competent_authority, registration_number, issue_date, status)
values (currval('project.establishment_establishment_id_seq'),'registration','HSE_EHS','REG001','2024-01-01','active');

-- ============================================================
-- 2. CHECK CONSTRAINT TESTS
-- ============================================================

-- Invalid inspector qualification
SAVEPOINT sp_invalid_inspector_qualification;
INSERT INTO project.inspector
(institution_id, name, qualification_level, employment_start_date, employment_status)
VALUES
(
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  'Bad Inspector',
  'expert-god-mode',
  '2023-01-01',
  'active'
);
ROLLBACK TO SAVEPOINT sp_invalid_inspector_qualification;

-- Invalid establishment status
SAVEPOINT sp_invalid_establishment_status;
INSERT INTO project.establishment
(name, address_id, type, status, registration_date, ownership_id, contact_information_id)
VALUES
(
  'Bad Restaurant',
  (SELECT address_id FROM project.address WHERE city = 'Dublin' AND street = 'Main Street 1'),
  'restaurant',
  'flying',
  '2024-01-01',
  (SELECT ownership_id FROM project.ownership WHERE owner_name = 'Test Foods Ltd'),
  currval('project.contact_information_contact_information_id_seq')
);
ROLLBACK TO SAVEPOINT sp_invalid_establishment_status;

-- ============================================================
-- 3. FOREIGN KEY TESTS
-- ============================================================

-- Inspection with non-existing establishment
SAVEPOINT sp_bad_inspection_fk;
INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status)
VALUES
(
  999,
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  '2024-06-01',
  'routine',
  'none',
  'compliant'
);
ROLLBACK TO SAVEPOINT sp_bad_inspection_fk;

-- Finding with non-existing violation
SAVEPOINT sp_bad_finding_fk;
INSERT INTO project.finding
(inspection_id, violation_id, severity_assessed, notes, status)
VALUES
(
  999,
  999,
  'high',
  'Test note',
  'open'
);
ROLLBACK TO SAVEPOINT sp_bad_finding_fk;

-- ============================================================
-- 4. UNIQUE CONSTRAINT TESTS
-- ============================================================

-- First valid violation
INSERT INTO project.violation (code, description, severity_level, risk_category, legal_reference)
VALUES ('V001', 'Improper storage', 'medium', 'storage', 'Reg-1');

-- Duplicate violation code
SAVEPOINT sp_duplicate_violation_code;
INSERT INTO project.violation (code, description, severity_level, risk_category, legal_reference)
VALUES ('V001', 'Duplicate code', 'medium', 'storage', 'Reg-2');
ROLLBACK TO SAVEPOINT sp_duplicate_violation_code;

-- Extra contact info
INSERT INTO project.contact_information (phone, email, website)
VALUES ('111111111', 'second@test.ie', 'https://second.ie');

-- Duplicate contact info for two establishments (violates 1:1 assumption)
SAVEPOINT sp_duplicate_establishment_contact;
INSERT INTO project.establishment
(name, address_id, type, status, registration_date, ownership_id, contact_information_id)
VALUES
(
  'Second Restaurant',
  (SELECT address_id FROM project.address WHERE city = 'Dublin' AND street = 'Main Street 1'),
  'cafe',
  'active',
  '2024-02-01',
  (SELECT ownership_id FROM project.ownership WHERE owner_name = 'Test Foods Ltd'),
  (SELECT contact_information_id FROM project.establishment WHERE name = 'Test Restaurant')
);
ROLLBACK TO SAVEPOINT sp_duplicate_establishment_contact;

-- ============================================================
-- 5. REGISTRATION-SPECIFIC TESTS
-- ============================================================

-- Approval without registration number
SAVEPOINT sp_approval_without_regnum;
INSERT INTO project.registration
(establishment_id, registration_type, competent_authority, registration_number, issue_date, status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  'approval',
  'DAFM',
  NULL,
  '2024-02-01',
  'active'
);
ROLLBACK TO SAVEPOINT sp_approval_without_regnum;

-- Two active registrations for same establishment and authority
SAVEPOINT sp_duplicate_active_registration_same_authority;
INSERT INTO project.registration
(establishment_id, registration_type, competent_authority, registration_number, issue_date, status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  'registration',
  'HSE_EHS',
  'REG002',
  '2024-03-01',
  'active'
);
ROLLBACK TO SAVEPOINT sp_duplicate_active_registration_same_authority;

-- Same establishment, different authority (should succeed)
INSERT INTO project.registration
(establishment_id, registration_type, competent_authority, registration_number, issue_date, status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  'approval',
  'DAFM',
  'APP001',
  '2024-03-01',
  'active'
);

-- ============================================================
-- 6. DATE CONSISTENCY TESTS
-- ============================================================

-- end_date before issue_date
SAVEPOINT sp_bad_registration_dates;
INSERT INTO project.registration
(establishment_id, registration_type, competent_authority, registration_number, issue_date, end_date, status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  'registration',
  'SFPA',
  'REG003',
  '2024-05-01',
  '2024-04-01',
  'ceased'
);
ROLLBACK TO SAVEPOINT sp_bad_registration_dates;

-- Create one valid inspection and inspector link
INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  '2024-06-01',
  'routine',
  'none',
  'compliant'
);

INSERT INTO project.inspector_inspection (inspector_id, inspection_id)
VALUES
(
  (SELECT inspector_id FROM project.inspector WHERE name = 'John Inspector'),
  currval('project.inspection_visit_inspection_id_seq')
);

-- Valid violation for later tests
INSERT INTO project.violation (code, description, severity_level, risk_category, legal_reference)
VALUES ('V100', 'Unsafe food handling', 'high', 'hygiene', 'Reg-H1');

-- Valid finding for later tests
INSERT INTO project.finding
(inspection_id, violation_id, severity_assessed, notes, status)
VALUES
(
  currval('project.inspection_visit_inspection_id_seq'),
  currval('project.violation_violation_id_seq'),
  'high',
  'Observed unsafe food handling',
  'open'
);

-- Fine due_date before issue_date
SAVEPOINT sp_bad_fine_dates;
INSERT INTO project.fine
(finding_id, amount, issue_date, due_date, payment_status)
VALUES
(
  currval('project.finding_finding_id_seq'),
  1000,
  '2024-06-10',
  '2024-06-01',
  'pending'
);
ROLLBACK TO SAVEPOINT sp_bad_fine_dates;

-- Create valid fine for appeal test
INSERT INTO project.fine
(finding_id, amount, issue_date, due_date, payment_status)
VALUES
(
  currval('project.finding_finding_id_seq'),
  1000,
  '2024-06-10',
  '2024-06-20',
  'pending'
);

-- Appeal decision before appeal date
SAVEPOINT sp_bad_appeal_dates;
INSERT INTO project.appeal
(fine_id, appeal_date, decision_date, outcome)
VALUES
(
  currval('project.fine_fine_id_seq'),
  '2024-07-01',
  '2024-06-25',
  'rejected'
);
ROLLBACK TO SAVEPOINT sp_bad_appeal_dates;

-- ============================================================
-- 7. FOLLOW-UP TRIGGER TESTS
-- ============================================================

-- Follow-up with NULL original inspection
SAVEPOINT sp_followup_without_original;
INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  '2024-07-01',
  'follow_up',
  'none',
  'compliant'
);
ROLLBACK TO SAVEPOINT sp_followup_without_original;

-- Create valid original inspection for the next follow-up tests
INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  '2024-06-15',
  'routine',
  'none',
  'compliant'
);

INSERT INTO project.inspector_inspection (inspector_id, inspection_id)
VALUES
(
  (SELECT inspector_id FROM project.inspector WHERE name = 'John Inspector'),
  currval('project.inspection_visit_inspection_id_seq')
);

-- Follow-up earlier than original inspection
SAVEPOINT sp_followup_earlier_than_original;
INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status, original_inspection_id)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant'),
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  '2024-05-01',
  'follow_up',
  'none',
  'compliant',
  currval('project.inspection_visit_inspection_id_seq')
);
ROLLBACK TO SAVEPOINT sp_followup_earlier_than_original;

-- Create second contact and second establishment for cross-establishment test
INSERT INTO project.contact_information (phone, email, website)
VALUES ('222222222', 'third@test.ie', 'https://third.ie');

INSERT INTO project.establishment
(name, address_id, type, status, registration_date, ownership_id, contact_information_id)
VALUES
(
  'Third Restaurant',
  (SELECT address_id FROM project.address WHERE city = 'Dublin' AND street = 'Main Street 1'),
  'restaurant',
  'active',
  '2024-02-01',
  (SELECT ownership_id FROM project.ownership WHERE owner_name = 'Test Foods Ltd'),
  currval('project.contact_information_contact_information_id_seq')
);

-- Follow-up referencing inspection from different establishment
SAVEPOINT sp_followup_wrong_establishment;
INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status, original_inspection_id)
VALUES
(
  (SELECT establishment_id FROM project.establishment WHERE name = 'Third Restaurant'),
  (SELECT institution_id FROM project.inspection_institution WHERE name = 'HSE Dublin'),
  '2024-07-10',
  'follow_up',
  'none',
  'compliant',
  (
    SELECT MAX(inspection_id)
    FROM project.inspection_visit
    WHERE establishment_id = (SELECT establishment_id FROM project.establishment WHERE name = 'Test Restaurant')
  )
);
ROLLBACK TO SAVEPOINT sp_followup_wrong_establishment;

-- ============================================================
-- 8. "AT LEAST ONE INSPECTOR" TRIGGER TEST
-- ============================================================

-- This must fail at COMMIT, so it needs its own transaction block.
-- We cannot safely test a COMMIT-failure inside the current transaction and continue.
ROLLBACK;


-- Test A — should fail at COMMIT
-- This tests: inspection_visit must have at least one inspector

BEGIN;

INSERT INTO project.address (city, county, street, postcode)
VALUES ('Dublin', 'Dublin', 'Main Street 99', 'D99TEST');

INSERT INTO project.contact_information (phone, email, website)
VALUES ('999999999', 'owner2@test.ie', 'https://owner2.ie');

INSERT INTO project.contact_information (phone, email, website)
VALUES ('888888888', 'institution2@test.ie', 'https://inst2.ie');

INSERT INTO project.ownership (type, owner_name, owner_external_identifier)
VALUES ('company', 'Second Test Foods Ltd', 'CRO99999');

INSERT INTO project.establishment
(name, address_id, type, status, registration_date, ownership_id, contact_information_id)
VALUES
(
  'Inspectorless Restaurant',
  currval('project.address_address_id_seq'),
  'restaurant',
  'active',
  '2024-01-01',
  currval('project.ownership_ownership_id_seq'),
  (
    SELECT contact_information_id
    FROM project.contact_information
    WHERE email = 'owner2@test.ie'
  )
);

INSERT INTO project.inspection_institution
(name, institution_type, jurisdiction_area, address_id, contact_information_id)
VALUES
(
  'HSE Test',
  'HSE_EHS',
  'Dublin',
  currval('project.address_address_id_seq'),
  (
    SELECT contact_information_id
    FROM project.contact_information
    WHERE email = 'institution2@test.ie'
  )
);

INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status)
VALUES
(
  currval('project.establishment_establishment_id_seq'),
  currval('project.inspection_institution_institution_id_seq'),
  '2024-08-01',
  'routine',
  'none',
  'compliant'
);

COMMIT;


-- Test B — should succeed, then rollback
-- This tests the valid version. 

BEGIN;

INSERT INTO project.address (city, county, street, postcode)
VALUES ('Dublin', 'Dublin', 'Main Street 100', 'D100TEST');

INSERT INTO project.contact_information (phone, email, website)
VALUES ('777777777', 'owner3@test.ie', 'https://owner3.ie');

INSERT INTO project.contact_information (phone, email, website)
VALUES ('666666666', 'institution3@test.ie', 'https://inst3.ie');

INSERT INTO project.ownership (type, owner_name, owner_external_identifier)
VALUES ('company', 'Third Test Foods Ltd', 'CRO88888');

INSERT INTO project.establishment
(name, address_id, type, status, registration_date, ownership_id, contact_information_id)
VALUES
(
  'Properly Staffed Restaurant',
  currval('project.address_address_id_seq'),
  'restaurant',
  'active',
  '2024-01-01',
  currval('project.ownership_ownership_id_seq'),
  (
    SELECT contact_information_id
    FROM project.contact_information
    WHERE email = 'owner3@test.ie'
  )
);

INSERT INTO project.inspection_institution
(name, institution_type, jurisdiction_area, address_id, contact_information_id)
VALUES
(
  'HSE Test 2',
  'HSE_EHS',
  'Dublin',
  currval('project.address_address_id_seq'),
  (
    SELECT contact_information_id
    FROM project.contact_information
    WHERE email = 'institution3@test.ie'
  )
);

INSERT INTO project.inspector
(institution_id, name, qualification_level, employment_start_date, employment_status)
VALUES
(
  currval('project.inspection_institution_institution_id_seq'),
  'Valid Inspector',
  'standard',
  '2022-01-01',
  'active'
);

INSERT INTO project.inspection_visit
(establishment_id, institution_id, inspection_date, inspection_type, enforcement_action_type, compliance_status)
VALUES
(
  currval('project.establishment_establishment_id_seq'),
  currval('project.inspection_institution_institution_id_seq'),
  '2024-08-02',
  'routine',
  'none',
  'compliant'
);

INSERT INTO project.inspector_inspection (inspector_id, inspection_id)
VALUES
(
  currval('project.inspector_inspector_id_seq'),
  currval('project.inspection_visit_inspection_id_seq')
);

ROLLBACK;