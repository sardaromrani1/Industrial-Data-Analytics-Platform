# Industrial Data Analytics Platform

## Overview

Industrial Data Analytics Platform is a long-term industrial data platform designed to provide a reliable foundation for maintenance, reliability, asset, and operational analytics.

The current implementation domain is **Instrumentation**. The architecture is intentionally designed so that additional industrial domains such as Mechanical, Electrical, Process, and Inspection can be added without redesigning the entire platform.

## Current Scope

Phase 1 focuses on Instrumentation data management, database integrity, maintenance/reliability events, inventory relationships, and analytical readiness.

## Architecture Principles

- One Source of Truth per business concept
- Master Data separated from Event / Transaction Data
- Operational data separated from Analytical data
- Relationships represented as relational structures, not free text
- Historical truth preserved
- Business rules enforced at database level where appropriate
- Analytics derived from authoritative operational data
- Extensible domain architecture without a giant generic entity model

## Database Architecture

SQL Server is the current database platform.

Primary schemas:

- `dbo` — core/master entities
- `ref` — reference and controlled vocabulary data
- `rel` — many-to-many and relationship entities
- `event` — operational events and historical records
- `inv` — inventory and stock transactions
- `doc` — document metadata and document relationships
- `analytics` — analytical views and derived reporting layer

## Implementation Phases

- Phase 4.1.2 — Current Database Baseline Audit
- Phase 7 — Target Architecture
- Phase 8 — Revised Database Schema
- Phase 9 — Final SQL Server DDL
- Phase 10 — Constraints, Integrity and Index Strategy
- Phase 11 — Migration / Upgrade Plan
- Phase 12 — Data Migration and Reconciliation
- Phase 13 — Security and Operational Hardening
- Phase 14 — Analytics Layer
- Phase 15 — Django / Application Layer
- Phase 16 — BI / Reporting
- Phase 17 — AI / Agent Layer
- Phase 18 — Production Deployment

## Current Status

### Database Baseline

**Phase 10 — COMPLETED / BASELINE ESTABLISHED**

The database architecture, schema, foreign-key integrity, temporal integrity, business-rule constraints, filtered unique indexes, FK/index audit, approved performance indexes, and final integrity validation have been completed for the current baseline.

Approved performance indexes currently include:

- `rel.SparePartInstruments (InstrumentId, SparePartId)`
- `rel.SparePartInstrumentTypes (InstrumentTypeId, SparePartId)`

Additional composite indexes remain deliberately deferred until real workload evidence is available.

### Next Phase

The next controlled step is **Phase 11 — Migration / Upgrade Planning**. Migration execution is intentionally deferred until the migration strategy, mapping, reconciliation rules, rollback approach, and validation criteria are formally defined.

## Repository Structure

```text
Industrial-Data-Analytics-Platform/
├── README.md
├── PROJECT_STATUS.md
├── .gitignore
├── database/
│   ├── 01_baseline_audit/
│   ├── 02_target_architecture/
│   ├── 03_schema/
│   ├── 04_ddl/
│   ├── 05_constraints/
│   ├── 06_indexes/
│   ├── 07_integrity_validation/
│   └── 08_migration/
├── documentation/
│   ├── architecture/
│   ├── database_design/
│   ├── phase_reports/
│   └── decisions/
├── evidence/
│   ├── phase_4_1_2/
│   ├── phase_10_4/
│   ├── phase_10_5/
│   ├── phase_10_6/
│   ├── phase_10_7/
│   └── phase_10_8/
├── application/
└── analytics/
```

## Technology Stack

- Microsoft SQL Server
- Python
- Django
- SQL / T-SQL
- Future BI and AI/Agent components

## Repository Policy

SQL scripts are treated as version-controlled implementation artifacts.

CSV verification outputs are treated as evidence and should normally be preserved rather than overwritten when they represent a distinct validation run.

No production migration should be performed solely because a migration script exists. Migration requires an approved mapping, reconciliation, validation, and rollback strategy.
