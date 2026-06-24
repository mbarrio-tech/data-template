---
version: 1.0
status: active
last-updated: YYYY-MM-DD
owner: "[Release Manager — writes at cycle close · PO — confirms outcome · Tech Lead — reviews at Context Reset]"
idf-ref: "Section 07 — Artifacts"
---

# Outcome Register

> Tracks whether shipped features actually delivered the client outcome they were intended to achieve.
>
> One row per Live-ON flag. Updated by the release manager at cycle close.
> PO confirms the outcome after 2–4 weeks live.
>
> This is the only artifact that answers: **"Did it work for the client?"**
> The intent-log records what was intended. The gate-report records what was verified before shipping.
> This register records what was observed after shipping.

<!-- IDF NOTE: Companion to INTENT_LOG.md. Closes the outcome loop per IDF v7.11 Section 07. -->

---

## How to Update This File

**At cycle close (release manager):**
Add a row for each flag flipped to Live-ON. Set Outcome to `Pending measurement — review [date 4 weeks out]`.

**After measurement window (PO):**
Update the Outcome column with the observed result: did the success signal from the intent manifest in the product?

---

## Outcome Register

| Flag Name | Cycle | Live-ON Date | Success Signal (from intent) | Measurement Method | Outcome | Reviewed By | Reviewed On |
|---|---|---|---|---|---|---|---|
| *(no flags live yet)* | — | — | — | — | — | — | — |

---

## Outcome Categories

| Category | Description |
|---|---|
| `Confirmed` | Success signal observed — outcome achieved |
| `Partial` | Some success signals observed, not all — note details |
| `Not confirmed` | Measurement window passed, success signal not observed |
| `Reverted` | Flag was rolled back before measurement window |
| `Pending measurement` | Still within measurement window — review date set |

---

## Measurement Window

Standard measurement window: **2–4 weeks** after Live-ON activation.
PO sets the review date at cycle close based on the success signal type:
- Usage/engagement metrics: 2 weeks
- Business outcome metrics: 4 weeks
- Client feedback-based: depends on client contact cadence

---

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0 | YYYY-MM-DD | [Author] | Initial outcome register created at inception |
