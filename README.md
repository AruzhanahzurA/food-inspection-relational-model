# A Relational Database Model for Food Safety and Restaurant Inspection Data

**Course:** DNDS5020 – Data Management and Databases  
**Instructor:** Jascha Grübel  
**Group E**  
- Azhar Serik  
- Aruzhan Oshakbayeva  
- Balázs Remenyi  
- Daryna Tkachenko  

---

##  Project Overview

This project develops a **normalized relational database model** that captures the full regulatory lifecycle of food safety inspections.

Food inspection systems generate complex, time-dependent, and relationally rich data. However, publicly available inspection data is typically simplified (e.g., pass/fail or grading systems), which obscures the underlying enforcement process.

Our goal is to design a database schema that:

- Models the complete inspection lifecycle  
- Preserves referential and temporal integrity  
- Reflects real regulatory structures  
- Supports analytical querying  

The model is grounded in the **Irish food safety regulatory framework**, but designed to be adaptable to other jurisdictions.

---

##  Research Question

> Can a relational database model grounded in the Irish food safety system accurately and coherently represent the regulatory inspection lifecycle?

---

##  Data Management Problem

Food inspection data presents several challenges:

- Fragmentation across institutions and jurisdictions  
- Complex many-to-many relationships  
- Temporal dependencies (follow-ups, license validity, appeals)  
- Regulatory heterogeneity  
- Need for traceability and enforcement modeling  

This project addresses these issues through a fully normalized, event-centric relational schema.

---

##  Database Design

The model is centered around the **Inspection Visit** entity.

Each inspection event links:

- Establishments  
- Inspectors  
- Institutions  
- Violations  
- Findings  
- Fines  
- Appeals  
- Follow-up inspections  

### Core Entities

- Establishment  
- Ownership  
- Address  
- Registration  
- Inspection Institution  
- Inspector  
- Inspection Visit  
- Violation (Catalog)  
- Finding  
- Fine  
- Appeal  
- Inspector_Inspection (junction table)

---

##  Key Relationships

- Establishment → Inspection Visit (1:N)  
- Inspector ↔ Inspection Visit (M:N)  
- Inspection Visit → Findings (1:N)  
- Finding → Fine (1:0-1)  
- Fine → Appeal (1:N)  
- Inspection Visit → Follow-up Inspection (self-referencing 1:N)

---

##  Temporal & Integrity Constraints

The schema enforces:

- Referential integrity via foreign keys  
- Follow-up inspections must reference original inspections  
- Follow-up inspection date must be later than original  
- Follow-ups must refer to the same establishment  
- License periods should not overlap inconsistently  
- Fines must reference findings  
- Appeals must reference fines  

---

##  Testing Strategy

Validation is conducted through:

- Scenario-based lifecycle simulations  
- Repeated violation cases  
- Enforcement consistency checks  
- Edge-case testing ("attempt to break the database")  

---

##  Prototype & Queries

The prototype includes:

- Schema implementation (SQL)
- Synthetic data population
- Basic and advanced analytical queries
- Lifecycle validation queries
- Integrity testing

Example analytical questions supported:

- Which violation types most frequently lead to fines?
- How often do establishments receive follow-up inspections?
- Which institutions impose the most enforcement actions?
- What is the average time between inspection and appeal decision?

---

##  Repository Structure (Example)
.
├── LICENSE
├── README.md
├── data
│   └── synthetic_data.sql
├── diagrams
│   └── ER_model.png
├── docs
│   └── Project_proposal.pdf
├── queries
│   ├── inspection_enforcement_chain.sql
│   └── inspection_sequence_tracking.sql
└── schema
    └── create_database.sql

## ▶️ How to Run the Project

To set up and run the database locally:

### 1️⃣ Create the Database
Run the `create_database.sql` file first.  
This script creates the database and prepares the environment.

Example (PostgreSQL):

```bash
psql -U your_username -f create_database.sql
```

##  Regulatory & Academic Grounding

The schema is grounded in:

- EU Regulation 852/2004  
- EU Regulation 2017/625  
- Commission Implementing Regulation 2019/627  
- Food Safety Authority of Ireland (FSAI) reports  
- Academic literature on food safety inspections and enforcement  

(See full references in project documentation.)

---

##  Future Work

- Expand synthetic dataset  
- Develop stored procedures and advanced constraints  
- Implement triggers for temporal validation  
- Add cross-jurisdiction comparison support  
- Performance testing with larger datasets  

---

##  Lessons Learned

**Strengths**
- Clear lifecycle logic  
- Strong normalization  
- Regulatory grounding  
- Structured integrity enforcement  

**Challenges**
- Initial over-engineering  
- Late version control initialization  
- Early model lacked concrete jurisdiction grounding  

---

##  Deliverables

- ER Diagram  
- SQL schema scripts  
- Synthetic dataset  
- Query scripts  
- Project proposal  
- Final presentation  

---

##  License

Academic project – DNDS5020 (2026).
