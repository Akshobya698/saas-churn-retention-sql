# Milestone 2 — Foundation: definitions, MRR, topline churn

## Definitions (locked for M3/M4)

- **Grain:** one row = one subscription (1,250 accounts hold 1–8 subs each,
  mostly 2–4). Headlines are subscription-grain.
- **Tier:** normalized from the free-text `plan` column, which mixes case and a
  legacy label. `pro` + `professional` → **pro** (257 of 294 `professional`
  rows already point at the pro `plan_id` at identical MRR ≈ $144);
  `enterprise` (any case) → **enterprise**; `starter` → **starter**; rest →
  **free**. Paid = tier ≠ free.
- **Active:** `status = 'active'` — the only statuses counting toward MRR.
- **Churned:** `status = 'churned'`. All 557 churned rows carry `cancelled_at`
  and no other status does; churn month = month of `cancelled_at`. Liveness
  comes from `start_date` + `cancelled_at` — `end_date` is unreliable (half of
  actives show a past `end_date`).
- **past_due** ($34,170 MRR): live but failing payment — **at-risk**, excluded
  from headline MRR. **paused** ($34,454): not billed — excluded. **trialing**
  (292 subs): pre-revenue — excluded from MRR and base.
- **Churn base:** active + past_due (subscribed, billable or recovering) alive
  at month start. Paused subs are out — they can't churn (no cancel event) and
  would dilute the rate; this matches M3's retained set exactly.
- **MRR** = `SUM(mrr)` over active paid subs. It reflects seats/add-ons
  (enterprise actives average $764 vs the $399 list price), so the row value —
  not list price — is the source of truth.
- **Gross MRR churn** = MRR cancelled in month ÷ paid MRR at month start.
  Gross, not net; expansion is M4 territory. No annual amortization needed —
  annual `plan_id`s 5–8 have zero subscribers.
- **Window:** bulk data ends May 2026 (June extract is partial). Trend = 12
  complete months, Jun 2025 – May 2026; "current" = June 2026 snapshot.
  Snapshot-MRR limitation: mid-life upgrades aren't historized (net +$29.7k
  in-window — immaterial).

## Headline numbers

Current MRR **$246,739** over 773 active paid subscriptions: enterprise
$168,373 (230 subs, 68% of MRR), pro $69,684 (388), starter $8,682 (155).
112 active free subscriptions contribute $0, as they should.

| Month | Paid base MRR | Cust. churn | MRR churn | Free churn |
|---|---|---|---|---|
| 2025-06 → 2026-02 | $129k → $214k | 1.9–3.5% | 0.9–2.9% | 0.0–4.2% |
| 2026-03 / 04 / 05 | $231k / $244k / $263k | 3.11 / 2.91 / 3.86% | 2.32 / 1.93 / 1.76% | 2.9 / 2.8 / 2.5% |

12-month averages: paid customer churn **2.64%**, gross MRR churn **1.62%**,
free churn **2.69%** — inside the 1–15% sanity band every month except two
quiet months that dip just under 1% on the revenue measure only.

## Read for the CFO

Lead with paid: ≈2.6%/mo customer churn, ≈1.6%/mo revenue churn — leavers
skew smaller than average, which is healthy. The base doubled in a year
($129k → $263k); additions dwarf losses every month. Watch item: churn stepped
up Mar–May 2026 (3.1/2.9/3.9%, May's 33 cancels a record) — that uptick is
M3's question. Free churn (≈2.7%) runs level with paid: free users don't
cancel, they go quiet, so cancellation-based free churn understates
abandonment — M3 should use activity data. Books reconcile: Jun-2025 attached
stock ($142,787) + adds ($205,296) + pre-window churned ($30,655) +
paused-ever ($34,454) = $413,192 vs the current stack ($412,679) — within
$513 (0.1%).
