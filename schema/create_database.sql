
CREATE SCHEMA IF NOT EXISTS project;

-- ----------------------------
-- 1) Shared tables
-- ----------------------------

CREATE TABLE project.contact_information (
  contact_information_id SERIAL PRIMARY KEY,
  phone   VARCHAR(50),
  email   VARCHAR(254),
  website VARCHAR(2048)
);

CREATE TABLE project.address (
  address_id  SERIAL PRIMARY KEY,
  city        VARCHAR(120),
  region      VARCHAR(120),
  county      VARCHAR(120),
  street      VARCHAR(255),
  postcode    VARCHAR(20),
  country     VARCHAR(120) NOT NULL DEFAULT 'Ireland'
);

CREATE TABLE project.ownership (
  ownership_id SERIAL PRIMARY KEY,
  type         VARCHAR(40) NOT NULL CHECK (type IN ('entrepreneur', 'company', 'other')),
  owner_name   VARCHAR(255) NOT NULL,
  owner_identifier VARCHAR(100)
);

-- ----------------------------
-- 2) Core domain tables
-- ----------------------------

CREATE TABLE project.establishment (
  establishment_id SERIAL PRIMARY KEY,
  name             VARCHAR(255) NOT NULL,
  address_id       INT NOT NULL REFERENCES project.address(address_id),
  type             VARCHAR(60) NOT NULL,
  status           VARCHAR(30) NOT NULL CHECK (status IN ('active', 'temporarily_closed', 'permanently_closed')),
  registration_date DATE,
  ownership_id     INT NOT NULL REFERENCES project.ownership(ownership_id),
  contact_information_id INT NOT NULL REFERENCES project.contact_information(contact_information_id),
  CONSTRAINT uq_establishment_contact UNIQUE (contact_information_id)
);

CREATE TABLE project.inspection_institution (
  institution_id SERIAL PRIMARY KEY,
  name           VARCHAR(255) NOT NULL,
  institution_type VARCHAR(80) NOT NULL
    CHECK (institution_type IN ('HSE_EHS', 'local_authority_unit', 'other_competent_authority')),
  jurisdiction_area VARCHAR(255),
  address_id INT REFERENCES project.address(address_id),
  contact_information_id INT NOT NULL REFERENCES project.contact_information(contact_information_id),
  CONSTRAINT uq_institution_contact UNIQUE (contact_information_id)
);

CREATE TABLE project.inspector (
  inspector_id SERIAL PRIMARY KEY,
  institution_id INT NOT NULL REFERENCES project.inspection_institution(institution_id),
  name          VARCHAR(255) NOT NULL,
  qualification_level VARCHAR(80),
  employment_start_date DATE,
  employment_status VARCHAR(30) NOT NULL CHECK (employment_status IN ('active', 'inactive', 'on_leave'))
);

CREATE TABLE project.registration (
  registration_id SERIAL PRIMARY KEY,
  establishment_id INT NOT NULL REFERENCES project.establishment(establishment_id),
  registration_type VARCHAR(20) NOT NULL CHECK (registration_type IN ('registration', 'approval')),
  competent_authority VARCHAR(20) NOT NULL CHECK (competent_authority IN ('HSE_EHS', 'DAFM', 'SFPA')),
  registration_number VARCHAR(120) NOT NULL,
  issue_date DATE NOT NULL,
  end_date   DATE,
  status     VARCHAR(20) NOT NULL CHECK (status IN ('valid', 'suspended', 'revoked', 'expired')),
  CONSTRAINT ck_registration_dates CHECK (end_date IS NULL OR end_date >= issue_date),
  CONSTRAINT uq_registration_number_per_authority UNIQUE (competent_authority, registration_number)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_registration_one_active_per_establishment
ON project.registration (establishment_id)
WHERE status = 'valid' AND end_date IS NULL;

-- ----------------------------
-- 3) Inspections, violations, findings, enforcement
-- ----------------------------

CREATE TABLE project.inspection_visit (
  inspection_id SERIAL PRIMARY KEY,
  establishment_id INT NOT NULL REFERENCES project.establishment(establishment_id),
  institution_id   INT NOT NULL REFERENCES project.inspection_institution(institution_id),

  inspection_date DATE NOT NULL,
  inspection_type VARCHAR(30) NOT NULL CHECK (inspection_type IN ('routine', 'complaint_based', 'follow_up')),
  overall_score   NUMERIC(6,2),

  enforcement_action_type VARCHAR(30) NOT NULL
    CHECK (enforcement_action_type IN ('none', 'closure_order', 'prohibition_order', 'improvement_order')),

  outcome_status VARCHAR(30) NOT NULL
    CHECK (outcome_status IN ('compliant', 'non_compliant', 'conditional_pass')),

  supplier_verification_status VARCHAR(20) NOT NULL DEFAULT 'not_checked'
    CHECK (supplier_verification_status IN ('not_checked','verified','issues_found','needs_follow_up')),

  original_inspection_id INT NULL REFERENCES project.inspection_visit(inspection_id),

  CONSTRAINT ck_followup_link_presence
    CHECK (
      (inspection_type = 'follow_up' AND original_inspection_id IS NOT NULL)
      OR
      (inspection_type <> 'follow_up' AND original_inspection_id IS NULL)
    )
);

CREATE TABLE project.inspector_inspection (
  inspector_id  INT NOT NULL REFERENCES project.inspector(inspector_id) ON DELETE CASCADE,
  inspection_id INT NOT NULL REFERENCES project.inspection_visit(inspection_id) ON DELETE CASCADE,
  PRIMARY KEY (inspector_id, inspection_id)
);

CREATE TABLE project.violation (
  violation_id SERIAL PRIMARY KEY,
  code         VARCHAR(50) NOT NULL,
  description  TEXT NOT NULL,
  severity_level VARCHAR(40) NOT NULL,
  risk_category  VARCHAR(80),
  legal_reference VARCHAR(255),
  CONSTRAINT uq_violation_code UNIQUE (code)
);

CREATE TABLE project.finding (
  finding_id SERIAL PRIMARY KEY,
  inspection_id INT NOT NULL REFERENCES project.inspection_visit(inspection_id),
  violation_id  INT NOT NULL REFERENCES project.violation(violation_id),
  severity_assessed VARCHAR(80),
  notes TEXT,
  status VARCHAR(30) NOT NULL CHECK (status IN ('open', 'resolved', 'pending_review'))
);

CREATE TABLE project.fine (
  fine_id SERIAL PRIMARY KEY,
  finding_id INT NOT NULL UNIQUE REFERENCES project.finding(finding_id),
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  issue_date DATE NOT NULL,
  due_date   DATE,
  payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('paid', 'pending', 'overdue')),
  CONSTRAINT ck_fine_dates CHECK (due_date IS NULL OR due_date >= issue_date)
);

CREATE TABLE project.appeal (
  appeal_id SERIAL PRIMARY KEY,
  fine_id INT NOT NULL REFERENCES project.fine(fine_id),
  appeal_date   DATE NOT NULL,
  decision_date DATE,
  outcome VARCHAR(30) NOT NULL CHECK (outcome IN ('approved', 'rejected', 'partially_approved')),
  CONSTRAINT ck_appeal_dates CHECK (decision_date IS NULL OR decision_date >= appeal_date)
);

-- ------------------------------------------------------------
-- 4) Follow-up cross-row rules (trigger)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION project.enforce_followup_consistency()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  orig_establishment_id INT;
  orig_date DATE;
BEGIN
  IF NEW.original_inspection_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT establishment_id, inspection_date
    INTO orig_establishment_id, orig_date
  FROM project.inspection_visit
  WHERE inspection_id = NEW.original_inspection_id;

  IF orig_establishment_id IS NULL THEN
    RAISE EXCEPTION 'Original inspection % not found', NEW.original_inspection_id;
  END IF;

  IF NEW.establishment_id <> orig_establishment_id THEN
    RAISE EXCEPTION
      'Follow-up inspection must reference an original inspection of the same establishment (new.establishment_id=%, original.establishment_id=%)',
      NEW.establishment_id, orig_establishment_id;
  END IF;

  IF NEW.inspection_date <= orig_date THEN
    RAISE EXCEPTION
      'Follow-up inspection date (%) must be later than original inspection date (%)',
      NEW.inspection_date, orig_date;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_followup_consistency ON project.inspection_visit;

CREATE TRIGGER trg_followup_consistency
BEFORE INSERT OR UPDATE OF original_inspection_id, establishment_id, inspection_date
ON project.inspection_visit
FOR EACH ROW
EXECUTE FUNCTION project.enforce_followup_consistency();

-- ------------------------------------------------------------
-- 5) Enforce: each Inspection Visit has at least one Inspector
--    (DEFERRABLE constraint triggers; checked at COMMIT)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION project.enforce_inspection_has_inspector(p_inspection_id INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM project.inspection_visit
    WHERE inspection_id = p_inspection_id
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM project.inspector_inspection
      WHERE inspection_id = p_inspection_id
      LIMIT 1
    ) THEN
      RAISE EXCEPTION
        'Inspection visit % must have at least one inspector (project.inspector_inspection).',
        p_inspection_id;
    END IF;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION project._trg_check_inspection_has_inspector_from_inspection()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM project.enforce_inspection_has_inspector(NEW.inspection_id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION project._trg_check_inspection_has_inspector_from_link()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM project.enforce_inspection_has_inspector(OLD.inspection_id);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.inspection_id <> OLD.inspection_id THEN
      PERFORM project.enforce_inspection_has_inspector(OLD.inspection_id);
      PERFORM project.enforce_inspection_has_inspector(NEW.inspection_id);
    ELSE
      PERFORM project.enforce_inspection_has_inspector(NEW.inspection_id);
    END IF;
    RETURN NEW;
  ELSE
    PERFORM project.enforce_inspection_has_inspector(NEW.inspection_id);
    RETURN NEW;
  END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_inspection_has_inspector_on_inspection ON project.inspection_visit;

CREATE CONSTRAINT TRIGGER trg_inspection_has_inspector_on_inspection
AFTER INSERT ON project.inspection_visit
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION project._trg_check_inspection_has_inspector_from_inspection();

DROP TRIGGER IF EXISTS trg_inspection_has_inspector_on_link ON project.inspector_inspection;

CREATE CONSTRAINT TRIGGER trg_inspection_has_inspector_on_link
AFTER INSERT OR UPDATE OR DELETE ON project.inspector_inspection
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION project._trg_check_inspection_has_inspector_from_link();
