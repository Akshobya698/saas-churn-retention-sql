-- ============================================================================
-- Milestone 2 — Foundation: definitions, MRR, topline churn
-- SaaS Churn & Retention Analysis
--
-- DEFINITIONS (locked here; reused in M3 and M4 — do not redefine downstream)
--   * Grain: one row = one subscription (saas.subscriptions). Accounts often
--     hold 2-4 subscriptions, so headline churn is subscription-grain.
--   * Tier (normalized from the free-text `plan` column, which mixes case and
--     a legacy 'professional' label — see Q0):
--       tier = 'pro'         for plan IN ('pro','professional')
--       tier = 'enterprise'  for plan = 'enterprise' (any case)
--       tier = 'starter'     for plan = 'starter'
--       tier = 'free'        otherwise
--     PAID = tier <> 'free'.
--   * Active subscription: status = 'active'. Only these count toward MRR.
--   * Churned subscription: status = 'churned' (cancelled_at IS NOT NULL for
--     every churned row and no other status — verified in Q0).
--     Churn month = DATE_TRUNC('month', cancelled_at).
--   * past_due: subscription live but payment failing. NOT in headline MRR;
--     reported separately as at-risk MRR.
--   * paused: not billed. Excluded from MRR and churn base.
--     (paused/past_due rows all carry end_date IS NULL — end_date is NOT a
--     reliable "active-through" date: ~half of actives have a past end_date —
--     so liveness is derived from start_date + cancelled_at, never end_date.)
--   * trialing: pre-revenue. Excluded from MRR and churn base entirely.
--   * Monthly base (start of month m): start_date < m
--       AND (cancelled_at IS NULL OR cancelled_at >= m).
--   * Gross MRR churn (headline revenue metric):
--       SUM(mrr of paid subs churned in m) / SUM(mrr of paid base at start of m)
--     Net churn (with expansion) is out of scope for M2.
--   * Annual billing: the plans catalog lists annual prices, but ZERO
--     subscriptions reference an annual plan_id, so no amortization is needed.
-- DATA WINDOW: bulk data ends May 2026 (June 2026 extract is partial: 19
--   starts vs ~150/mo trend; sparse tail Jul 2026–May 2027). Trend window =
--   last 12 COMPLETE months: 2025-06-01 .. 2026-05-01. "Current" MRR = status
--   snapshot as of the June 2026 extract.
-- LIMITATION: money/tier are snapshot values (current `mrr`, current `plan`).
--   Mid-life upgrades/downgrades are not historized here (only ~230 such
--   events in-window, net +$29.7k — immaterial to the trend).
-- ============================================================================

SET search_path TO saas;

-- ----------------------------------------------------------------------------
-- Q0. Tier-mapping audit + status hygiene (run once; proves the definitions)
-- ----------------------------------------------------------------------------
-- 'professional' behaves like 'pro': 257 of 294 rows already point at the pro
-- plan_id with matching MRR levels (~$144 vs ~$144).
SELECT s.plan_id,
       p.plan_name,
       COUNT(*) AS n_subs,
       ROUND(AVG(s.mrr), 2) AS avg_mrr
FROM subscriptions s
LEFT JOIN plans p USING (plan_id)
WHERE s.plan = 'professional'
GROUP BY 1, 2;

-- Status hygiene: only 'churned' rows carry cancelled_at, and all of them do.
SELECT status,
       COUNT(*) AS n,
       COUNT(*) FILTER (WHERE cancelled_at IS NOT NULL) AS with_cancel_ts
FROM subscriptions
GROUP BY 1
ORDER BY 1;

-- Free plan must carry zero MRR (paid plans must carry ~all MRR).
SELECT CASE WHEN LOWER(plan) = 'free' THEN 'free' ELSE 'paid' END AS group_,
       COUNT(*) AS n,
       ROUND(SUM(mrr), 2) AS total_mrr
FROM subscriptions
WHERE status = 'active'
GROUP BY 1;

-- Annual plan_ids (5-8) must have zero subscribers.
SELECT p.plan_id, p.plan_name, p.billing_interval, COUNT(s.subscription_id) AS n_subs
FROM plans p
LEFT JOIN subscriptions s USING (plan_id)
GROUP BY 1, 2, 3
ORDER BY 1;

-- ----------------------------------------------------------------------------
-- Q1. Current MRR: headline (paid, active) + at-risk / excluded buckets
-- ----------------------------------------------------------------------------
WITH norm AS (
    SELECT CASE WHEN LOWER(plan) IN ('pro', 'professional') THEN 'pro'
                WHEN LOWER(plan) = 'enterprise' THEN 'enterprise'
                WHEN LOWER(plan) = 'starter' THEN 'starter'
                ELSE 'free' END AS tier,
           mrr,
           status
    FROM subscriptions
)
SELECT tier,
       COUNT(*) AS active_subs,
       ROUND(SUM(mrr), 2) AS mrr
FROM norm
WHERE status = 'active'
GROUP BY 1
ORDER BY 3 DESC;

-- At-risk (past_due, still subscribed) and excluded (paused, trialing) MRR.
SELECT status,
       COUNT(*) AS n_subs,
       ROUND(SUM(mrr), 2) AS mrr
FROM subscriptions
WHERE status IN ('past_due', 'paused', 'trialing')
GROUP BY 1
ORDER BY 1;

-- ----------------------------------------------------------------------------
-- Q2. Monthly PAID churn, last 12 complete months (headline trend)
-- ----------------------------------------------------------------------------
WITH months AS (
    SELECT (DATE '2025-06-01' + (n || ' months')::interval)::date AS m
    FROM generate_series(0, 11) AS n
),
base AS (
    SELECT DATE_TRUNC('month', m.m)::date AS month,
           COUNT(*) FILTER (
               WHERE LOWER(s.plan) <> 'free'
                 AND s.start_date < m.m
                 AND (s.cancelled_at IS NULL OR s.cancelled_at >= m.m)
                 AND s.status <> 'trialing') AS paid_start_n,
           COALESCE(SUM(s.mrr) FILTER (
               WHERE LOWER(s.plan) <> 'free'
                 AND s.start_date < m.m
                 AND (s.cancelled_at IS NULL OR s.cancelled_at >= m.m)
                 AND s.status <> 'trialing'), 0) AS paid_start_mrr,
           COUNT(*) FILTER (
               WHERE LOWER(s.plan) <> 'free'
                 AND s.cancelled_at >= m.m
                 AND s.cancelled_at < m.m + interval '1 month') AS paid_churn_n,
           COALESCE(SUM(s.mrr) FILTER (
               WHERE LOWER(s.plan) <> 'free'
                 AND s.cancelled_at >= m.m
                 AND s.cancelled_at < m.m + interval '1 month'), 0) AS paid_lost_mrr
    FROM subscriptions s
    CROSS JOIN months m
    GROUP BY 1
)
SELECT month,
       paid_start_n,
       paid_churn_n,
       ROUND(100.0 * paid_churn_n / NULLIF(paid_start_n, 0), 2) AS paid_customer_churn_pct,
       ROUND(paid_start_mrr, 0) AS paid_start_mrr,
       ROUND(paid_lost_mrr, 0) AS paid_lost_mrr,
       ROUND(100.0 * paid_lost_mrr / NULLIF(paid_start_mrr, 0), 2) AS paid_gross_mrr_churn_pct
FROM base
ORDER BY month;

-- ----------------------------------------------------------------------------
-- Q3. Monthly FREE churn (customer-count only; free MRR is zero by definition)
-- ----------------------------------------------------------------------------
WITH months AS (
    SELECT (DATE '2025-06-01' + (n || ' months')::interval)::date AS m
    FROM generate_series(0, 11) AS n
),
base AS (
    SELECT DATE_TRUNC('month', m.m)::date AS month,
           COUNT(*) FILTER (
               WHERE LOWER(s.plan) = 'free'
                 AND s.start_date < m.m
                 AND (s.cancelled_at IS NULL OR s.cancelled_at >= m.m)
                 AND s.status <> 'trialing') AS free_start_n,
           COUNT(*) FILTER (
               WHERE LOWER(s.plan) = 'free'
                 AND s.cancelled_at >= m.m
                 AND s.cancelled_at < m.m + interval '1 month') AS free_churn_n
    FROM subscriptions s
    CROSS JOIN months m
    GROUP BY 1
)
SELECT month,
       free_start_n,
       free_churn_n,
       ROUND(100.0 * free_churn_n / NULLIF(free_start_n, 0), 2) AS free_customer_churn_pct
FROM base
ORDER BY month;

-- ----------------------------------------------------------------------------
-- Q4. Trend summary: 12-mo average vs last-3-mo average (paid)
-- Re-run Q2 into a CTE in SQLTools, or compare the two rows below.
-- ----------------------------------------------------------------------------
-- (Computed from Q2 output; kept as a query for reproducibility.)

-- ----------------------------------------------------------------------------
-- Q5. Reconciliation: start-base + adds = where the MRR sits now
-- Identity (snapshot-MRR terms):
--   paid_base(Jun-2025 start) + paid_adds(Jun-2025..May-2026, incl. June-2026
--   partial starters) + pre-window churned MRR
--     = active_paid_now + churned_alltime_MRR + paused_past_due_MRR
-- ----------------------------------------------------------------------------
SELECT ROUND(SUM(mrr) FILTER (
           WHERE LOWER(plan) <> 'free'
             AND start_date < DATE '2025-06-01'
             AND (cancelled_at IS NULL OR cancelled_at >= DATE '2025-06-01')
             AND status <> 'trialing'), 0) AS paid_base_jun2025,
       ROUND(SUM(mrr) FILTER (
           WHERE LOWER(plan) <> 'free'
             AND start_date >= DATE '2025-06-01'
             AND status <> 'trialing'), 0) AS paid_adds_since,
       ROUND(SUM(mrr) FILTER (
           WHERE LOWER(plan) <> 'free'
             AND status = 'churned'
             AND cancelled_at < DATE '2025-06-01'), 0) AS prewindow_churned_mrr,
       ROUND(SUM(mrr) FILTER (
           WHERE LOWER(plan) <> 'free' AND status = 'active'), 0) AS active_paid_now,
       ROUND(SUM(mrr) FILTER (
           WHERE LOWER(plan) <> 'free' AND status = 'churned'), 0) AS churned_alltime_mrr,
       ROUND(SUM(mrr) FILTER (
           WHERE LOWER(plan) <> 'free'
             AND status IN ('paused', 'past_due')), 0) AS paused_pastdue_mrr
FROM subscriptions;
