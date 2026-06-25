---
version: 1.0
last-updated: 2026-06-25
owner: "[Craft Engineer]"
domain: "terraform-security"
applies-to: "Every Terraform file (.tf) that creates or modifies infrastructure in this project"
---

# Capability: Terraform Security

## Summary

Every Terraform change must pass a security review before it is merged. This capability defines the mandatory controls, the review checklist, and the anti-patterns that block merge for infrastructure code in this data pipeline project.

---

## Hard Gate

<HARD-GATE>
Do NOT mark any Terraform task as complete until ALL items in the Security Checklist below are verified. Infrastructure misconfigurations cannot be rolled back with a feature flag — a public bucket or over-privileged service account is a live security incident the moment Terraform apply runs.
</HARD-GATE>

---

## Automated Scan Requirement

Run a static security scanner on every Terraform change before committing. The scan must exit clean (zero HIGH or CRITICAL findings).

```bash
# Checkov (preferred)
checkov -d . --framework terraform

# tfsec (alternative)
tfsec .
```

If the project does not yet have a scanner configured in CI, block the task and ask the tech lead to add it before proceeding. A passing manual review does not substitute for automated scanning.

---

## Security Checklist

### 1. No Secrets in Code

- [ ] No passwords, API keys, tokens, connection strings, or private keys appear in any `.tf` file
- [ ] No secrets appear in `terraform.tfvars` files committed to the repository
- [ ] All sensitive values are passed via a secret manager reference (e.g. GCP Secret Manager, AWS Secrets Manager, Azure Key Vault) or via CI/CD environment variables

```hcl
# WRONG — secret in code
resource "google_sql_user" "app" {
  password = "SuperSecret123"
}

# CORRECT — value from secret manager
data "google_secret_manager_secret_version" "db_password" {
  secret = "db-app-password"
}
resource "google_sql_user" "app" {
  password = data.google_secret_manager_secret_version.db_password.secret_data
}
```

Variables that hold secrets must be declared with `sensitive = true`:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

### 2. Principle of Least Privilege on IAM

- [ ] Service accounts and IAM bindings grant only the minimum permissions required for the specific resource and operation
- [ ] No role bindings use `roles/owner`, `roles/editor`, or `*` wildcards in production
- [ ] Compute service accounts are not granted project-level IAM roles — bind roles to specific resources where possible
- [ ] Service accounts used by pipeline jobs are distinct from service accounts used for infrastructure management

```hcl
# WRONG — over-privileged
resource "google_project_iam_binding" "pipeline_sa" {
  role    = "roles/editor"
  members = ["serviceAccount:${google_service_account.pipeline.email}"]
}

# CORRECT — scoped to the specific resource and operation needed
resource "google_bigquery_dataset_iam_member" "pipeline_bq_writer" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.pipeline.email}"
}
```

### 3. Storage: No Public Access

- [ ] No GCS bucket, S3 bucket, or Azure Blob container has public access enabled
- [ ] `uniform_bucket_level_access = true` for all GCS buckets
- [ ] S3 buckets have `block_public_acls`, `block_public_policy`, `ignore_public_acls`, and `restrict_public_buckets` all set to `true`
- [ ] No ACL or bucket policy grants access to `allUsers` or `allAuthenticatedUsers`

```hcl
# GCS — correct configuration
resource "google_storage_bucket" "pipeline_data" {
  name                        = "project-pipeline-data"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

# AWS S3 — correct configuration
resource "aws_s3_bucket_public_access_block" "pipeline_data" {
  bucket                  = aws_s3_bucket.pipeline_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 4. Encryption at Rest

- [ ] All storage resources (buckets, BigQuery datasets, database instances) use encryption at rest
- [ ] For regulated data: customer-managed encryption keys (CMEK) are used, not Google/AWS default managed keys
- [ ] KMS key resources are in a separate project or account from the data they protect

```hcl
# GCS with CMEK
resource "google_storage_bucket" "pipeline_data" {
  encryption {
    default_kms_key_name = google_kms_crypto_key.pipeline.id
  }
}
```

### 5. Encryption in Transit

- [ ] All external-facing load balancers and APIs enforce TLS 1.2 minimum (TLS 1.3 preferred)
- [ ] `ssl_policy` is explicitly set on any Google load balancer — do not rely on the default
- [ ] Database connections require SSL/TLS — `require_ssl = true` on Cloud SQL, `transit_encryption_mode = "REQUIRED"` on Redis, etc.
- [ ] No `insecure` flag is set to `true` on any provider configuration

### 6. Network Isolation

- [ ] Pipeline compute resources (VMs, Cloud Run, Dataproc) are deployed inside a VPC — no resources are created without an explicit `network` or `subnetwork` reference
- [ ] Firewall rules / security groups follow allow-list logic: deny by default, allow explicitly
- [ ] No firewall rule or security group allows inbound traffic from `0.0.0.0/0` on ports other than 80 and 443
- [ ] Database instances and internal services are not assigned public IP addresses
- [ ] VPC Service Controls perimeter is applied to BigQuery datasets containing PII or regulated data (if the project scope includes this)

```hcl
# WRONG — database with public IP
resource "google_sql_database_instance" "main" {
  settings {
    ip_configuration {
      ipv4_enabled = true   # public IP
    }
  }
}

# CORRECT — private IP only
resource "google_sql_database_instance" "main" {
  settings {
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}
```

### 7. Terraform State Security

- [ ] Remote state backend is configured — no local `terraform.tfstate` files are committed to the repository
- [ ] State backend storage is encrypted at rest and not publicly accessible
- [ ] State backend access is restricted to the CI/CD service account and authorised engineers — not the pipeline runtime service account
- [ ] State locking is enabled (GCS state uses object versioning; S3 state uses DynamoDB lock table)

```hcl
# GCS remote backend — correct
terraform {
  backend "gcs" {
    bucket = "project-tf-state"
    prefix = "terraform/state"
  }
}
```

### 8. Logging and Audit Trail

- [ ] Data access audit logs are enabled for BigQuery, Cloud Storage, and any service handling PII
- [ ] Admin activity logs are enabled on all projects
- [ ] Log sink or export is configured to a long-term retention destination (30 days minimum, 365 days for regulated data)
- [ ] Terraform changes are applied only through CI/CD — no manual `terraform apply` from developer workstations in production

### 9. Resource Tagging and Labelling

- [ ] All resources have at minimum these labels/tags: `project`, `environment`, `owner`
- [ ] Labels are consistent across all resources in the same pipeline — enforced via a `locals` block, not repeated inline

```hcl
locals {
  common_labels = {
    project     = var.project_name
    environment = var.environment
    owner       = var.team_name
  }
}

resource "google_bigquery_dataset" "raw" {
  labels = local.common_labels
}
```

---

## Anti-Patterns Reference

| Anti-Pattern | Risk | Correct Pattern |
|---|---|---|
| Secret in `.tf` or `.tfvars` committed to repo | Credential exposure in git history | Use secret manager references; mark variables `sensitive = true` |
| `roles/owner` or `roles/editor` on service accounts | Blast radius if SA is compromised covers entire project | Bind the narrowest role to the specific resource |
| `ipv4_enabled = true` on database instances | Database reachable from internet | Private IP only; use Cloud SQL Auth Proxy or VPC peering |
| Public GCS/S3 bucket | Data exfiltration | `public_access_prevention = "enforced"` + `uniform_bucket_level_access = true` |
| Local state file committed to repo | State contains secrets; concurrent applies corrupt state | Remote backend with locking |
| Firewall rule `0.0.0.0/0` on non-web port | Lateral movement into the network | Restrict source ranges to known CIDR blocks |
| No encryption key specified | Relies on provider default; may not meet compliance | Explicit CMEK reference |
| Single service account for pipeline + infra | Compromised pipeline SA can modify infrastructure | Separate SAs for pipeline runtime and infrastructure management |

---

## Completion Gate

Before marking any Terraform task done:

- [ ] `checkov -d . --framework terraform` exits with zero HIGH or CRITICAL findings
- [ ] No secrets, passwords, or tokens in any `.tf` or `.tfvars` file committed to repo
- [ ] No IAM binding uses `roles/owner`, `roles/editor`, or wildcard `*` permissions
- [ ] All storage resources have public access explicitly blocked
- [ ] All storage and database resources have encryption at rest configured
- [ ] All database instances use private IP only
- [ ] Remote state backend is configured with locking
- [ ] Data access audit logs are enabled for all services handling pipeline data
- [ ] All resources carry the mandatory labels (`project`, `environment`, `owner`)
- [ ] Network resources follow allow-list firewall rules — no `0.0.0.0/0` on internal ports
