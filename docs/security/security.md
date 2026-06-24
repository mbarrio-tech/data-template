---
version: 1.0
status: draft
last-updated: YYYY-MM-DD
owner: "[Security Lead / Tech Lead]"
---

# Security

> Covers security requirements, threat model, compliance requirements, and controls.
> Review and update at each sprint boundary or when architecture changes. Bump `version` in frontmatter.

## Security Requirements

| Requirement | Priority | Status | Owner |
|---|---|---|---|
| [Requirement 1] | High | Pending | [Name] |
| [Requirement 2] | Medium | Pending | [Name] |

## Threat Model

### Protected Assets

| Asset | Sensitivity | Data Classification |
|---|---|---|
| [e.g. User credentials] | Critical | Restricted |
| [e.g. Client data / PII] | High | Confidential |
| [e.g. API keys / secrets] | Critical | Restricted |

### Threats (STRIDE)

| Threat | Category | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| [Threat 1] | Spoofing | Medium | High | [Control] |
| [Threat 2] | Information Disclosure | Low | High | [Control] |

## Compliance Requirements

- [ ] [e.g. GDPR — data residency, retention, subject rights]
- [ ] [e.g. ISO 27001 — information security management]
- [ ] [e.g. Client's IT Security Policy — internal policy reference]

## Security Controls

| Control | Implementation | Status |
|---|---|---|
| Authentication | [e.g. Identity Provider with MFA — provider defined at inception] | Pending |
| Authorization | [e.g. RBAC with defined role matrix] | Pending |
| Data encryption at rest | [e.g. AES-256 via cloud provider storage encryption] | Pending |
| Data encryption in transit | TLS 1.3 minimum | Pending |
| Secret management | [e.g. cloud secret vault — no secrets in code; specific tooling defined at inception] | Pending |
| Dependency scanning | [e.g. Mend / Dependabot] | Pending |
| SAST | [e.g. SonarQube / GitHub Advanced Security] | Pending |
| DAST | [e.g. OWASP ZAP in CI pipeline] | Pending |

## OWASP Top 10 Coverage

| Risk | Mitigation in Place |
|---|---|
| A01 Broken Access Control | [Control or Pending] |
| A02 Cryptographic Failures | [Control or Pending] |
| A03 Injection | [Control or Pending] |
| A04 Insecure Design | [Control or Pending] |
| A05 Security Misconfiguration | [Control or Pending] |
| A06 Vulnerable Components | [Control or Pending] |
| A07 Auth and Session Failures | [Control or Pending] |
| A08 Software and Data Integrity Failures | [Control or Pending] |
| A09 Logging and Monitoring Failures | [Control or Pending] |
| A10 Server-Side Request Forgery | [Control or Pending] |

## Security Review History

| Date | Reviewer | Findings | Resolution |
|---|---|---|---|
| YYYY-MM-DD | [Reviewer] | Initial baseline review | Open |

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0 | YYYY-MM-DD | [Author] | Initial security baseline from inception |
