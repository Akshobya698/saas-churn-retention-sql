# Milestone 3A — Cohort retention: the whole story is month one

## The one observation (M5 candidate)

**Retention is decided in the first 30 days — and then the bleeding stops.**
Across every activation cohort, 30–60% of newly paying companies are gone by
month 2, and after that the curve goes flat (even tilts upward). The business
does not have a loyalty problem; it has an onboarding problem. Anyone still
around at month 3 is essentially a customer for life — mean retention drifts
from ~69% at month 6 to ~73% at month 12, not down. If the CFO funds one fix,
it is first-month activation, not save-desk discounts for tenured accounts.

## Shape: cliff, floor, slow climb

- **Steepest drop: month 1, by far.** 2024–2026 cohorts keep 39–88% at month 1
  (typical: 55–70%). No later month-to-month step exceeds a few points.
- **The floor holds.** Past month 2 there is no gradual decay in any cohort —
  the classic SaaS "leaky bucket" is absent. Curves flatten by month 3–4.
- **The climb is win-back, not noise.** 41 of the 344 companies alive at month
  12 (12%) had already churned at month 1 and came back on a new paid
  subscription. Reactivation is a real second engine — worth measuring as its
  own funnel in M4/M5.

## Old vs new, and the M2 spike

Cohorts are not degrading: 2024 cohorts average ~73% at month 12; 2025
cohorts sit at comparable early-life levels (~62% at month 3 vs ~65% for 2024
cohorts at the same age). Spread between cohorts (47–94% at month 12) tracks
small cohort sizes (n = 10–48), not eras — best (2024-10, 94%) and worst
(2024-12, 47%) are both small-n neighbors. Answer to the CFO's question: the
Mar–May 2026 topline uptick is **broad-based, not one bad cohort** — those 79
company churns span 29 activation cohorts, with the largest share (11) coming
from 2025-12, itself the largest cohort on record.

## Footnotes for the skeptics

- **Cohort anchor:** `accounts.signup_date` is unrelated to commercial start
  (only 145 of 888 paid companies subscribe in their signup month), so cohorts
  are months of *first paid subscription* — documented in the SQL header.
- **M2 tie-out:** collapsing this table by calendar month reproduces M2's paid
  churn counts almost exactly (only Oct-2025 differs: 12 vs 13). Churn is
  whole-company loss — a cancelled subscription nearly always takes its entire
  account with it, so the company grain loses nothing.
- **Gates:** month 0 is 100.0% for all 51 cohorts, no cell exceeds 100%, and
  the empty bottom-right triangle is exactly the unelapsed future.
  Free-only companies (44) are excluded: cancellation-based free churn
  (~2.7%/mo in M2) understates abandonment and would flatter the picture.

![Paid company retention by activation cohort](../figures/cohort_heatmap.png)
