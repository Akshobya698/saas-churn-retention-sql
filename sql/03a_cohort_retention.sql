-- ============================================================================
-- Milestone 3A — Cohort retention table (company-grain, paid)
-- SaaS Churn & Retention Analysis
--
-- COHORT ASSIGNMENT (deviation from the brief, with evidence):
--   The brief says "each company -> its signup month", but accounts.signup_date
--   is unrelated to commercial start in this data: only 145 of 888 paid
--   companies start their first subscription in their signup month, and lags
--   spread over 0-24+ months with no pattern. Cohort = month of the company's
--   FIRST PAID, non-trialing subscription start (activation cohort). This is
--   the standard SaaS meaning of "signup cohort" and the only anchor that
--   makes month-0 retention well-defined.
-- DEFINITIONS (M2 reused, one documented extension):
--   * Paid: LOWER(plan) NOT IN ('free'); 'professional' folds into 'pro'
--     (M2 Q0). Trialing subscriptions are pre-revenue and excluded everywhere.
--   * Retained at offset k (k >= 1): the company holds >= 1 paid subscription
--     that is live at END of month cohort+k, i.e. start_date < bound AND
--     (cancelled_at IS NULL OR cancelled_at >= bound), bound = cohort+(k+1)mo.
--     EXTENSION vs M2: the live subscription must be in billable standing
--     (status IN ('active','past_due')); a paused-only company counts as
--     churned for revenue retention. M2's 'active' set is unchanged.
--   * Offset 0 is 1.00 by construction (cohort members started a paid sub in
--     month 0). Same-month cancellations surface as month-1 attrition.
--   * Cells beyond elapsed time (cohort+offset past May 2026, the last
--     complete data month) are NULL -> the heatmap's empty bottom-right.
--   * Free-only companies (44, never held a paid sub) are outside this table;
--     free cancellation churn (~2%/mo, M2) understates abandonment anyway.
-- VALIDATION: collapsing this table's churned counts by calendar month
--   reproduces the M2 Q2 paid_churn_n trend (company-grain level is lower
--   because multi-subscription companies survive single-sub cancels).
-- ============================================================================

SET search_path TO saas;

-- ----------------------------------------------------------------------------
-- Q1. Cohort sizes (denominators)
-- ----------------------------------------------------------------------------
WITH first_paid AS (
    SELECT account_id,
           DATE_TRUNC('month', MIN(start_date))::date AS cohort
    FROM subscriptions
    WHERE LOWER(plan) <> 'free'
      AND status <> 'trialing'
    GROUP BY 1
)
SELECT cohort,
       COUNT(*) AS n_companies
FROM first_paid
GROUP BY 1
ORDER BY 1;

-- ----------------------------------------------------------------------------
-- Q2. Retention COUNTS: active companies per (cohort, month offset 0..12)
-- ----------------------------------------------------------------------------
WITH first_paid AS (
    SELECT account_id,
           DATE_TRUNC('month', MIN(start_date))::date AS cohort
    FROM subscriptions
    WHERE LOWER(plan) <> 'free'
      AND status <> 'trialing'
    GROUP BY 1
),
offsets AS (
    SELECT generate_series(1, 12) AS k  -- offset 0 is 1.00 by construction (see Q3)
),
grid AS (
    SELECT f.account_id,
           f.cohort,
           o.k,
           (f.cohort + ((o.k + 1) || ' months')::interval)::date AS bound
    FROM first_paid f
    CROSS JOIN offsets o
)
SELECT g.cohort,
       g.k AS month_offset,
       COUNT(DISTINCT g.account_id) AS cohort_size,
       COUNT(DISTINCT CASE WHEN s.subscription_id IS NOT NULL
                           THEN g.account_id END) AS n_active
FROM grid g
LEFT JOIN subscriptions s
  ON s.account_id = g.account_id
 AND LOWER(s.plan) <> 'free'
 AND s.status IN ('active', 'past_due')
 AND s.start_date < g.bound
 AND (s.cancelled_at IS NULL OR s.cancelled_at >= g.bound)
WHERE g.bound <= DATE '2026-06-01'  -- elapsed months only (last complete month: May 2026)
GROUP BY 1, 2
ORDER BY 1, 2;

-- HEATMAP_QUERY
-- ----------------------------------------------------------------------------
-- Q3. Retention FRACTIONS: the heatmap source (rows = cohort, cols = offset)
-- ----------------------------------------------------------------------------
WITH first_paid AS (
    SELECT account_id,
           DATE_TRUNC('month', MIN(start_date))::date AS cohort
    FROM subscriptions
    WHERE LOWER(plan) <> 'free'
      AND status <> 'trialing'
    GROUP BY 1
),
offsets AS (
    SELECT generate_series(1, 12) AS k
),
grid AS (
    SELECT f.account_id,
           f.cohort,
           o.k,
           (f.cohort + ((o.k + 1) || ' months')::interval)::date AS bound
    FROM first_paid f
    CROSS JOIN offsets o
),
per_cell AS (
    SELECT g.cohort,
           g.k AS month_offset,
           COUNT(DISTINCT g.account_id) AS cohort_size,
           COUNT(DISTINCT CASE WHEN s.subscription_id IS NOT NULL
                               THEN g.account_id END) AS n_active
    FROM grid g
    LEFT JOIN subscriptions s
      ON s.account_id = g.account_id
     AND LOWER(s.plan) <> 'free'
     AND s.status IN ('active', 'past_due')
     AND s.start_date < g.bound
     AND (s.cancelled_at IS NULL OR s.cancelled_at >= g.bound)
    WHERE g.bound <= DATE '2026-06-01'
    GROUP BY 1, 2
)
SELECT cohort,
       month_offset,
       cohort_size,
       n_active,
       CASE WHEN month_offset = 0 THEN 1.0
            ELSE ROUND(n_active::numeric / NULLIF(cohort_size, 0), 4) END AS retention_frac
FROM (
    SELECT DISTINCT cohort, 0 AS month_offset, COUNT(*) OVER (PARTITION BY cohort) AS cohort_size,
           NULL::int AS n_active
    FROM first_paid
    UNION ALL
    SELECT cohort, month_offset, cohort_size, n_active FROM per_cell
) t
ORDER BY cohort, month_offset;
