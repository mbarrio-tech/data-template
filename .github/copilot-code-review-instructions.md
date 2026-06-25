# Copilot Code Review Instructions

You are reviewing a **data pipeline project**. Apply the rules below to every pull request.
Be specific — every finding must include the file name and the column/CTE/line that is wrong.
Do not praise correct code. Focus on problems.

---

## SQL Quality

Flag as **critical** if any of the following are present:

- `SELECT *` in any production query — every column must be listed explicitly
- A `WHERE` filter applied **after** a `JOIN` or aggregation when it could have been
  applied before — push filters into a CTE before the join
- A function wrapping a partition column in a `WHERE` clause
  (e.g. `WHERE DATE(created_at) = …`) — use range comparisons instead
- An implicit cross join (missing `ON` clause)
- `ORDER BY` without `LIMIT` inside a subquery or CTE
- A table larger than 1 GB read without an incremental time-window filter

Flag as **important** if:

- Keywords are not in UPPER CASE (`select` instead of `SELECT`)
- Table or column aliases are missing the `AS` keyword
- `GROUP BY` or `ORDER BY` uses positional integers instead of column names
- A CTE is defined but never referenced
- Nested subqueries go deeper than 3 levels without a comment explaining why
- `DISTINCT` is used without an explanation of where the duplicates come from

---

## SQL Spec Testing

Flag as **critical** if a model contains any of the following **without** a corresponding
`specs/<model_name>/<behaviour>.spec.sql` file committed in the same PR:

- Window function: `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`, `SUM() OVER`, etc.
- Deduplication via `ROW_NUMBER() OVER (PARTITION BY … ORDER BY …)`
- Conditional aggregation: `SUM(CASE WHEN … END)`, `COUNT(IF(…))`, etc.
- A call to a project-defined UDF or custom function
- Date/calendar arithmetic beyond `DATE_ADD` / `DATE_DIFF`
- A `CASE WHEN` expression with 3 or more branches
- A chain of 4 or more interdependent CTEs
- `WITH RECURSIVE`
- Pivot or unpivot logic

---

## Data Quality Checks

Flag as **critical** if a new or modified model does **not** have:

- `not_null` and `unique` tests on its primary key column(s)
- `accepted_values` tests on every categorical column with a fixed value set
- A `relationships` (referential integrity) test on every foreign key column

Flag as **important** if a **Critical** or **Standard** tier model is missing:

- A row count assertion (fails when the table returns zero rows)
- A freshness assertion (fails when the most recent record is older than the SLA)

Flag as **critical** if a **Critical** tier model is missing:

- At least one business logic assertion (e.g. no negative totals, delivery after shipment)
- Column-level documentation (description + null policy) on every column

---

## Terraform Security

Flag as **critical** if any `.tf` file contains:

- A hardcoded password, token, API key, or connection string
- An IAM binding with `roles/owner`, `roles/editor`, or a `*` wildcard
- A GCS bucket without `uniform_bucket_level_access = true`
  and `public_access_prevention = "enforced"`
- An S3 bucket without all four `block_public_*` settings set to `true`
- A database instance with `ipv4_enabled = true` (public IP)
- A firewall rule allowing inbound traffic from `0.0.0.0/0` on any port other
  than 80 or 443
- A local `terraform.tfstate` file committed to the repository
- Missing mandatory resource labels: `project`, `environment`, `owner`

---

## General

Flag as **important** if:

- A secret, credential, or token appears in an inline SQL comment
- Error handling is absent where an external call or I/O operation could fail
- A function or transformation has no obvious name and no comment explaining
  the non-obvious intent
