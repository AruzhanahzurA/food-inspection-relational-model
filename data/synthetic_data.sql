INSERT INTO project.address (address_id, city, region, county, street, postcode, country) VALUES
(1, 'Dublin', 'Leinster', 'Dublin', 'Grafton Street 12', 'D02 X285', 'Ireland'),
(2, 'Cork', 'Munster', 'Cork', 'Patrick Street 45', 'T12 YX76', 'Ireland'),
(3, 'Galway', 'Connacht', 'Galway', 'Shop Street 8', 'H91 F2K3', 'Ireland'),
(4, 'Limerick', 'Munster', 'Limerick', 'OConnell Street 21', 'V94 3Y2', 'Ireland'),
(5, 'Waterford', 'Munster', 'Waterford', 'John Street 3', 'X91 2N8', 'Ireland');

INSERT INTO project.contact_information (contact_information_id, phone, email, website) VALUES
(1, '+35312345678', 'info@chapterone.ie', 'www.chapterone.ie'),
(2, '+353214567890', 'info@electric.ie', 'www.electric.ie'),
(3, '+353915678901', 'contact@ardbia.ie', 'www.ardbia.ie'),
(4, '+353612345678', 'info@cornstore.ie', 'www.cornstore.ie'),
(5, '+353518765432', 'info@everetts.ie', 'www.everetts.ie'),
(6, '+353187654321', 'ehs.dublin@hse.ie', 'www.hse.ie'),
(7, '+353123400000', 'info@fsai.ie', 'www.fsai.ie');

INSERT INTO project.ownership (ownership_id, type, owner_name, owner_identifier) VALUES
(1, 'company', 'Chapter One Restaurant Ltd', 'IE1234567A'),
(2, 'company', 'Electric Cork Ltd', 'IE2234567B'),
(3, 'entrepreneur', 'Ard Bia at Nimmos', 'IE3234567C'),
(4, 'company', 'Cornstore Limerick Ltd', 'IE4234567D'),
(5, 'company', 'Everetts Waterford Ltd', 'IE5234567E');

INSERT INTO project.establishment 
(establishment_id, name, address_id, type, status, registration_date, ownership_id, contact_information_id)
VALUES
(1, 'Chapter One', 1, 'restaurant', 'active', '2010-05-10', 1, 1),
(2, 'Electric Cork', 2, 'restaurant', 'active', '2012-03-15', 2, 2),
(3, 'Ard Bia at Nimmos', 3, 'restaurant', 'active', '2008-07-20', 3, 3),
(4, 'Cornstore Limerick', 4, 'restaurant', 'active', '2015-09-01', 4, 4),
(5, 'Everetts', 5, 'restaurant', 'active', '2018-11-11', 5, 5);


-- Populate inspection_institution
INSERT INTO project.inspection_institution
(institution_id, name, institution_type, jurisdiction_area, address_id, contact_information_id)
VALUES
(1,'HSE Environmental Health Service - Dublin','HSE_EHS','Dublin',1,6),
(2,'HSE Environmental Health Service - Cork', 'HSE_EHS', 'Cork',2, 7),
(3,'Food Safety Authority of Ireland','other_competent_authority','Ireland',1,100);

INSERT INTO project.inspector
(inspector_id, institution_id, name, qualification_level, employment_start_date, employment_status)
VALUES
(1, 1, 'Patrick Murphy', 'Senior Inspector', '2015-01-10', 'active'),
(2, 2, 'Siobhan Kelly', 'Inspector', '2018-06-01', 'active'),
(3, 3, 'Michael OBrien', 'Lead Auditor', '2012-09-15', 'active');

INSERT INTO project.registration
(registration_id, establishment_id, registration_type, competent_authority,
 registration_number, issue_date, end_date, status)
VALUES
(1, 1, 'registration', 'HSE_EHS', 'REG-DUB-001', '2020-01-01', NULL, 'valid'),
(2, 2, 'registration', 'HSE_EHS', 'REG-COR-002', '2020-02-01', NULL, 'valid'),
(3, 3, 'registration', 'HSE_EHS', 'REG-GAL-003', '2020-03-01', NULL, 'valid'),
(4, 4, 'registration', 'HSE_EHS', 'REG-LIM-004', '2020-04-01', NULL, 'valid'),
(5, 5, 'registration', 'HSE_EHS', 'REG-WAT-005', '2020-05-01', NULL, 'valid');

INSERT INTO project.violation
(violation_id, code, description, severity_level, risk_category, legal_reference)
VALUES
(1, 'TEMP01', 'Improper food temperature control', 'high', 'temperature', 'EU 852/2004'),
(2, 'HYGI02', 'Inadequate hand washing facilities', 'medium', 'hygiene', 'EU 852/2004'),
(3, 'STOR03', 'Improper food storage', 'medium', 'storage', 'EU 852/2004');


-- Inspections
INSERT INTO inspection_visit (
 inspection_id, establishment_id, institution_id,
 inspection_date, inspection_type,
 overall_score, enforcement_action_type, outcome_status,
 supplier_verification_status, original_inspection_id
)
VALUES
 (102, 1, 1, DATE '2026-02-02', 'routine',
  68, 'improvement_order', 'non_compliant',
  'not_checked', NULL),
 (103, 1, 1, DATE '2026-02-16', 'follow_up',
  88, 'none', 'compliant',
  'not_checked', 102);

-- Inspector ↔️ inspections link
INSERT INTO inspector_inspection (inspector_id, inspection_id)
VALUES
 (1, 102),
 (2, 103);

INSERT INTO project.finding
(finding_id, inspection_id, violation_id, severity_assessed, notes, status)
VALUES
(1, 102, 1, 'high', 'Fridge temperature above safe threshold', 'resolved'),
(2, 103, 2, 'medium', 'No soap available in staff wash area', 'open');

INSERT INTO project.fine
(fine_id, finding_id, amount, issue_date, due_date, payment_status)
VALUES
(1, 1, 2000.00, '2026-02-03', '2026-02-20', 'paid'),
(2, 2, 5000.00, '2024-02-17', '2026-02-28', 'pending');

INSERT INTO project.appeal
(appeal_id, fine_id, appeal_date, decision_date, outcome)
VALUES
(1, 2, '2026-02-17', '2026-02-17', 'rejected');

