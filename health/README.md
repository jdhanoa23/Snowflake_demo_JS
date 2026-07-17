# Healthcare Analytics Data Pipeline — dbt + Snowflake (Medallion Architecture)

An end-to-end analytics engineering project that ingests synthetic healthcare data, transforms it through a **Medallion Architecture** (Bronze → Silver → Gold) using **dbt** on **Snowflake**, and exposes a **star schema** for a **Power BI** dashboard.

Built on the [Synthea](https://synthetichealth.github.io/synthea/) synthetic patient dataset.

---

## Architecture

```
AWS S3 (raw CSVs)
      │  COPY INTO
      ▼
STAGING  ── raw landing tables (all VARCHAR)
      │
      ▼
BRONZE   ── typed & cleaned views (trim, ISO-timestamp parsing, renaming)
      │
      ▼
SILVER   ── 3NF conformed tables (dedup, derived fields, keys, tests)
      │        + snapshot_patients (SCD-2)
      ▼
GOLD     ── Star schema (fact + dimensions) + One Big Table (OBT)
      │
      ▼
Power BI ── dashboard
```

Each layer lives in its own Snowflake schema: `STAGING`, `BRONZE`, `SILVER`, `GOLD`.

---

## Tech Stack

| Component | Purpose |
|---|---|
| **Snowflake** | Cloud data warehouse |
| **dbt** | Transformations, tests, snapshots, documentation |
| **AWS S3** | Raw data landing zone |
| **Power BI** | BI dashboard (consumes the Gold layer) |
| **Synthea** | Synthetic healthcare source data |

---

## Data Layers

### Bronze — cleaned source views
Nine `bronze_*` views over the raw staging tables. Responsibilities: trim strings, parse ISO timestamps, normalise headers, and cast types safely with `TRY_TO_*` functions. Materialised as **views** (no storage cost, always current).

### Silver — 3NF conformed models
Nine `silver_*` models with light, purposeful transformations:

- **Dimensions:** `patients` (derives `age`, `age_band`), `providers`, `organizations`, `payors`
- **Events:** `encounters` (derives `patient_responsibility`, `duration_minutes`), `conditions`, `medications`, `procedures`, `claims`
- **Materialisation:** tables, with `encounters` and `medications` built **incremental** (MERGE on business key)
- **Keys & tests:** `unique` + `not_null` on primary keys and a `relationships` test for referential integrity
- **SCD-2:** `snapshot_patients` tracks patient demographic / insurance history over time (`dbt_valid_from`, `dbt_valid_to`, `dbt_is_current`)

### Gold — star schema + OBT
Dimensional layer designed to serve the dashboard:

- **Fact:** `fact` (`fct_encounters`) — grain: one row per encounter; foreign keys to all dimensions + additive measures (costs, coverage, patient responsibility, duration)
- **Dimensions:** `dim_patients`, `dim_providers`, `dim_organizations`, `dim_payors`, `dim_date`
- **OBT:** `obt` — a wide, fully denormalised one-row-per-encounter table for low-latency flat queries
- **Ephemeral models:** `eph_dim_*` prepare each dimension inline from Silver (no warehouse clutter)
- **Metadata-driven builds:** `obt` and `fact` are generated from a Jinja `configs` list — joins are declared as configuration, not hand-written SQL

Dimensions are built from the **Silver** layer (not the OBT) so every entity is represented regardless of activity.

---

## Star Schema

```
        dim_patients   dim_providers
               \            /
   dim_date ──── fact (fct_encounters) ──── dim_payors
               /            \
      dim_organizations   (measures)
```

---

## Project Structure

```
dbt_project/
├── models/
│   ├── source/                 # sources.yml -> raw staging tables
│   ├── bronze/                 # 9 bronze_*.sql (views)
│   ├── silver/                 # 9 silver_*.sql + tests
│   │   └── _silver__models.yml
│   └── gold/
│       ├── obt.sql             # metadata-driven wide table
│       ├── fact.sql            # metadata-driven fact
│       ├── dim_*.sql           # dimensions
│       ├── ephemeral/          # eph_dim_*.sql
│       └── _gold__models.yml
├── snapshots/
│   └── snapshot_patients.yml   # SCD-2
├── macros/
│   └── generate_schema_name.sql
└── dbt_project.yml
```

---

## Key Design Decisions

- **All-VARCHAR staging, cast in Bronze** — a single malformed value can't fail the load; type-casting is a deliberate transformation step.
- **Constraints declared + tests enforced** — Snowflake doesn't enforce PK/FK, so keys are declared for BI/optimiser use and enforced through dbt tests.
- **Dimensions from Silver, not the OBT** — avoids dropping entities that have no fact rows.
- **One SCD-2 snapshot (patients)** — applied only where attribute history is analytically meaningful; events and static dimensions don't get SCD-2.
- **OBT *and* star schema** — the star serves proper dimensional modelling and time intelligence; the OBT serves fast flat queries.

---

## How to Run

```bash
# install dbt-snowflake and configure profiles.yml, then:
cd dbt_project

dbt build --select silver     # bronze + silver + tests
dbt snapshot                  # SCD-2 snapshot
dbt build --select gold       # gold star schema + OBT + tests

# or run everything in dependency order:
dbt build
```

---

## Dashboard
The Gold star schema feeds a two-page Power BI dashboard:

**Page 1 — Overview**
- KPI cards: total encounters, total patients, total claim cost, avg cost per encounter
- Encounters by class (donut) and encounters over time (line)
- Cost by payor (bar) and payer coverage vs. patient responsibility by class (stacked column)

**Page 2 — Cost & Payor Analysis**
- KPI cards: total claim cost, total payer coverage, total patient responsibility, patient responsibility %
- Coverage vs. patient responsibility by payor (stacked bar)
- Patient count and patient cost by age band (columns)
- Revenue by hospital (bar, averaged per organization)

Both pages support cross-filtering through the star schema relationships, with month and payor slicers for interactivity.

---

## Dataset Note

This project uses a scoped Synthea sample (9 core entities). It is a demonstration of **architecture and modelling** rather than analytical scale — the pipeline is designed to run identically on a full-volume dataset.
