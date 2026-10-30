# Data dictionary — `saas` schema (June 2026 extract)

Counts verified live; quirks are the ones that shaped M2–M4's definitions.

| Table | Rows | Grain | Key columns |
|---|---|---|---|
| accounts | 1,250 | company | `account_id`; `signup_date`, `acquisition_channel` |
| subscriptions | 2,113 | subscription | `subscription_id`, `account_id`, `plan` (text), `plan_id`, `mrr`, `status`, `start_date`, `end_date`, `cancelled_at` |
| subscription_events | 3,741 | subscription lifecycle event | `subscription_id`, `event_type`, `event_time`, `mrr_delta` |
| plans | 8 | price-book row | `plan_id`, `plan_name`, `monthly_price`, `billing_interval` |
| users | 2,556 | user | `user_id`, `account_id`, `plan_type` |
| signups | 2,556 | signup event | `user_id`, `account_id`, `signup_date` |
| events | 53,534 | product event | `account_id`, `event_type`, `occurred_at`, `feature_id` |
| support_tickets | 1,249 | ticket | `account_id`, `category`, `priority`, `csat` |
| seats | 1,556 | seat grant | `account_id`, `activated_at`, `deactivated_at` |
| trials | 250 | trial | `account_id`, `converted_subscription_id` |
| invoices | 4,201 | invoice | `subscription_id`, `amount`, `status` |
| payment_attempts | 5,690 | charge attempt | `subscription_id`, `status`, `failure_reason` |

Reference DDL (columns/types/nullability, reconstructed from
information_schema): [docs/schema.sql](../docs/schema.sql).

## Value distributions that matter

- **Statuses** (`subscriptions`): active 885, churned 557, trialing 292,
  past_due 195, paused 184. `cancelled_at` is set on all 557 churned rows and
  no others.
- **Plans:** free / starter ($29) / pro ($99) / enterprise ($399) monthly, plus
  annual price-book rows with **zero** subscribers. `plan` text mixes case
  (`Pro`, `Enterprise`) and a legacy `professional` label (folds into pro —
  see M2 Q0); 243 rows have NULL `plan_id`.
- **Events:** login 17,898 · feature_use 10,891 · dashboard_view 9,187 ·
  api_call 5,428 · export 3,740 · settings_change 2,753 · invite_sent 2,344 ·
  report_view 1,293. Range 2024-01 → 2027-03 (sparse future tail).
- **Tickets:** onboarding 271 · technical 257 · feature_request 247 ·
  bug_report 238 · billing 236; priorities medium 477 / low 325 / high 305 /
  critical 142.

## Quirks that shaped the analysis

1. `end_date` is unreliable (half of actives show a past `end_date`) —
   liveness is derived from `start_date` + `cancelled_at` only.
2. `accounts.signup_date` is unrelated to commercial start (only 145 of 888
   paid companies subscribe in their signup month) — cohorts anchor on first
   paid subscription instead.
3. `mrr` is a snapshot (seats/add-ons included: enterprise actives average
   $764 vs the $399 list price), not the list price.
4. Bulk data ends May 2026 (June extract partial; sparse event tail after).
5. `paused` rows never churn (no cancel event) — they sit in the base forever
   unless excluded, which is why M2's churn base is active + past_due only.
