/*
Navigation Functions Lab — historical data enrichment
Target: ranking_lab.customer_order_metrics, ranking_lab.supplier_performance,
        ranking_lab.inventory_snapshots

Run in VS Code against the CORRECT training database.
Review the PREVIEW queries below before running the write transaction.

Design:
- Preserve existing August/September 2026 metrics and October 15 snapshots.
- Generate 10 earlier monthly periods (2025-10 through 2026-07) for
  customer and supplier combinations already present in August 2026.
- Generate 10 earlier weekly inventory observations, two revisions each.
- Deterministic values, occasional intentionally missing customer months,
  no RAND()/random(), and repeatable inserts using NOT EXISTS.
- Uses existing maximum integer IDs for record_id/snapshot_id. This is
  appropriate for an isolated training database, not production ingestion.

NOTE: Generated history is SYNTHETIC; do not interpret it as real historical data.
The script assumes ordinary nonnegative revenue/units, scores in 0..100,
and on_time_rate in either 0..1 or 0..100 (detected per seed row).
*/

-- ======================= 0. READ-ONLY PREVIEW =========================
SELECT 'customer_order_metrics' AS table_name, COUNT(*) AS rows_before
FROM ranking_lab.customer_order_metrics
UNION ALL
SELECT 'supplier_performance', COUNT(*) FROM ranking_lab.supplier_performance
UNION ALL
SELECT 'inventory_snapshots', COUNT(*) FROM ranking_lab.inventory_snapshots;

-- Check that the intended seed populations exist.
SELECT 'customers, August 2026' AS seed, COUNT(*) AS rows
FROM ranking_lab.customer_order_metrics
WHERE reporting_month = DATE '2026-08-01'
UNION ALL
SELECT 'suppliers, August 2026', COUNT(*)
FROM ranking_lab.supplier_performance
WHERE reporting_month = DATE '2026-08-01'
UNION ALL
SELECT 'inventory, Oct 15 2026', COUNT(*)
FROM ranking_lab.inventory_snapshots
WHERE observed_at::date = DATE '2026-10-15';

-- Spot-check constraints and identity/default definitions for the ID columns.
SELECT table_name, column_name, column_default, is_identity, identity_generation
FROM information_schema.columns
WHERE table_schema = 'ranking_lab'
  AND (table_name, column_name) IN (
       ('supplier_performance', 'record_id'),
       ('inventory_snapshots', 'snapshot_id'));

-- ====================== 1. ENRICHMENT TRANSACTION ======================
BEGIN;

-- Keep the training-table ID allocation stable for this transaction.
-- Do not run concurrent writers against these tables during the script.
LOCK TABLE ranking_lab.customer_order_metrics,
           ranking_lab.supplier_performance,
           ranking_lab.inventory_snapshots IN EXCLUSIVE MODE;

-- 1A. CUSTOMER: use August records as a stable seed; add 10 prior months.
-- Grain: customer_id + market + reporting_month.
WITH seed AS (
    SELECT DISTINCT ON (customer_id, market)
        customer_id, market,
        COALESCE(order_count, 0) AS base_orders,
        COALESCE(net_revenue, 0) AS base_revenue
    FROM ranking_lab.customer_order_metrics
    WHERE reporting_month = DATE '2026-08-01'
      AND customer_id IS NOT NULL
      AND market IS NOT NULL
    ORDER BY customer_id, market, reporting_month
),
proposed AS (
    SELECT
        s.customer_id,
        s.market,
        (DATE '2025-10-01' + (g.n * INTERVAL '1 month'))::date AS reporting_month,
        GREATEST(0, ROUND(s.base_orders * (
            0.75 + 0.09 * (g.n % 4) + 0.04 * (ASCII(LEFT(s.customer_id, 1)) % 3)
        )))::integer AS order_count,
        GREATEST(0, ROUND(s.base_revenue * (
            0.70 + 0.07 * (g.n % 4)
              + 0.03 * (ASCII(LEFT(s.market, 1)) % 4)
              + CASE WHEN g.n IN (2, 6) THEN -0.13 ELSE 0 END
        ), 2)) AS net_revenue
    FROM seed s
    CROSS JOIN generate_series(0, 9) AS g(n)
    -- Deliberately give a subset of partitions missing months.
    WHERE NOT (
        g.n IN (3, 7)
        AND (ASCII(LEFT(s.customer_id, 1)) + ASCII(LEFT(s.market, 1))) % 5 = 0
    )
)
INSERT INTO ranking_lab.customer_order_metrics
    (customer_id, market, reporting_month, order_count, net_revenue)
SELECT p.customer_id, p.market, p.reporting_month, p.order_count, p.net_revenue
FROM proposed p
WHERE NOT EXISTS (
    SELECT 1
    FROM ranking_lab.customer_order_metrics t
    WHERE t.customer_id = p.customer_id
      AND t.market = p.market
      AND t.reporting_month = p.reporting_month
);

-- 1B. SUPPLIERS: 10 prior months, preserve original August/September rows.
-- Grain for generated data: supplier_id + region + reporting_month.
WITH seed AS (
    SELECT DISTINCT ON (supplier_id, region)
        supplier_id, region,
        COALESCE(performance_score, 75) AS base_score,
        COALESCE(on_time_rate, 90) AS base_on_time
    FROM ranking_lab.supplier_performance
    WHERE reporting_month = DATE '2026-08-01'
      AND supplier_id IS NOT NULL
      AND region IS NOT NULL
    ORDER BY supplier_id, region, record_id
),
proposed AS (
    SELECT
        s.supplier_id, s.region,
        (DATE '2025-10-01' + (g.n * INTERVAL '1 month'))::date AS reporting_month,
        LEAST(100, GREATEST(0, ROUND(
            s.base_score + (g.n % 5 - 2) * 2.2
            + CASE WHEN g.n IN (1, 5) THEN -5 ELSE 0 END, 2
        ))) AS performance_score,
        CASE WHEN s.base_on_time <= 1
             THEN LEAST(1, GREATEST(0, ROUND(
                    s.base_on_time + (g.n % 5 - 2) * 0.015, 4)))
             ELSE LEAST(100, GREATEST(0, ROUND(
                    s.base_on_time + (g.n % 5 - 2) * 1.5, 2)))
        END AS on_time_rate
    FROM seed s CROSS JOIN generate_series(0, 9) AS g(n)
    WHERE NOT (
        g.n = 4 AND (ASCII(LEFT(s.supplier_id, 1)) +
                         ASCII(LEFT(s.region, 1))) % 4 = 0
    )
),
missing AS (
    SELECT p.*
    FROM proposed p
    WHERE NOT EXISTS (
       SELECT 1 FROM ranking_lab.supplier_performance t
       WHERE t.supplier_id = p.supplier_id
         AND t.region = p.region
         AND t.reporting_month = p.reporting_month
    )
),
numbered AS (
    SELECT m.*,
           (ROW_NUMBER() OVER (ORDER BY supplier_id, region, reporting_month))::integer AS rn
    FROM missing m
),
id_base AS (
    SELECT COALESCE(MAX(record_id), 0) AS last_id
    FROM ranking_lab.supplier_performance
)
INSERT INTO ranking_lab.supplier_performance
    (record_id, supplier_id, region, reporting_month, performance_score, on_time_rate)
    OVERRIDING SYSTEM VALUE
SELECT b.last_id + n.rn,
       n.supplier_id, n.region, n.reporting_month,
       n.performance_score, n.on_time_rate
FROM numbered n CROSS JOIN id_base b;

-- 1C. INVENTORY: choose one latest Oct-15 snapshot per warehouse/SKU.
-- Generate 10 earlier weekly observations with two revisions per observation.
-- The revision may have a later ingested_at than its observed_at.
WITH seed AS (
    SELECT DISTINCT ON (warehouse_city, sku)
        warehouse_city, sku, observed_at,
        COALESCE(available_units, 0) AS base_units
    FROM ranking_lab.inventory_snapshots
    WHERE observed_at::date = DATE '2026-10-15'
      AND warehouse_city IS NOT NULL
      AND sku IS NOT NULL
    ORDER BY warehouse_city, sku,
             observed_at DESC, source_revision DESC,
             ingested_at DESC NULLS LAST, snapshot_id DESC
),
proposed AS (
    SELECT
        s.warehouse_city, s.sku,
        s.observed_at - (g.weeks_back * INTERVAL '7 days') AS observed_at,
        s.observed_at - (g.weeks_back * INTERVAL '7 days')
            + CASE WHEN rev.revision = 1 THEN INTERVAL '20 minutes'
                   ELSE INTERVAL '4 hours' END
            + CASE WHEN g.weeks_back IN (3, 7) AND rev.revision = 2
                   THEN INTERVAL '2 days' ELSE INTERVAL '0 hours' END
            AS ingested_at,
        rev.revision AS source_revision,
        GREATEST(0, s.base_units
            + (g.weeks_back % 5 - 2) * 7
            + CASE WHEN rev.revision = 1 THEN 4 ELSE 0 END
            + (ASCII(LEFT(s.sku, 1)) % 9)
        )::integer AS available_units
    FROM seed s
    CROSS JOIN generate_series(1, 10) AS g(weeks_back)
    CROSS JOIN generate_series(1, 2) AS rev(revision)
),
missing AS (
    SELECT p.*
    FROM proposed p
    WHERE NOT EXISTS (
        SELECT 1 FROM ranking_lab.inventory_snapshots t
        WHERE t.warehouse_city = p.warehouse_city
          AND t.sku = p.sku
          AND t.observed_at = p.observed_at
          AND t.source_revision = p.source_revision
    )
),
numbered AS (
    SELECT m.*,
           (ROW_NUMBER() OVER (
               ORDER BY warehouse_city, sku, observed_at, source_revision
           ))::integer AS rn
    FROM missing m
),
id_base AS (
    SELECT COALESCE(MAX(snapshot_id), 0) AS last_id
    FROM ranking_lab.inventory_snapshots
)
INSERT INTO ranking_lab.inventory_snapshots
    (snapshot_id, warehouse_city, sku, observed_at, ingested_at,
     source_revision, available_units)
    OVERRIDING SYSTEM VALUE
SELECT b.last_id + n.rn, n.warehouse_city, n.sku,
       n.observed_at, n.ingested_at, n.source_revision, n.available_units
FROM numbered n CROSS JOIN id_base b;

-- Synchronize any existing SERIAL/IDENTITY sequences with explicitly allocated IDs.
-- Note: sequence setval is not transactional, which is acceptable for this lab.
DO $$
DECLARE
    supplier_seq TEXT := pg_get_serial_sequence('ranking_lab.supplier_performance','record_id');
    inventory_seq TEXT := pg_get_serial_sequence('ranking_lab.inventory_snapshots','snapshot_id');
BEGIN
    IF supplier_seq IS NOT NULL THEN
        PERFORM setval(supplier_seq::regclass,
            (SELECT MAX(record_id) FROM ranking_lab.supplier_performance), true);
    END IF;
    IF inventory_seq IS NOT NULL THEN
        PERFORM setval(inventory_seq::regclass,
            (SELECT MAX(snapshot_id) FROM ranking_lab.inventory_snapshots), true);
    END IF;
END $$;

-- ====================== 2. POST-LOAD VALIDATION ========================
-- Period counts and extents after enrichment.
SELECT 'customer' AS dataset,
       COUNT(*) AS rows_now,
       COUNT(DISTINCT reporting_month) AS distinct_periods,
       MIN(reporting_month)::text AS first_period,
       MAX(reporting_month)::text AS last_period
FROM ranking_lab.customer_order_metrics
UNION ALL
SELECT 'supplier', COUNT(*), COUNT(DISTINCT reporting_month),
       MIN(reporting_month)::text, MAX(reporting_month)::text
FROM ranking_lab.supplier_performance
UNION ALL
SELECT 'inventory', COUNT(*), COUNT(DISTINCT observed_at),
       MIN(observed_at)::text, MAX(observed_at)::text
FROM ranking_lab.inventory_snapshots;

-- Generated candidate-grain uniqueness checks: each should return zero rows.
SELECT customer_id, market, reporting_month, COUNT(*) AS duplicates
FROM ranking_lab.customer_order_metrics
GROUP BY customer_id, market, reporting_month
HAVING COUNT(*) > 1;

SELECT supplier_id, region, reporting_month, COUNT(*) AS duplicates
FROM ranking_lab.supplier_performance
GROUP BY supplier_id, region, reporting_month
HAVING COUNT(*) > 1;

SELECT warehouse_city, sku, observed_at, source_revision,
       COUNT(*) AS duplicates
FROM ranking_lab.inventory_snapshots
GROUP BY warehouse_city, sku, observed_at, source_revision
HAVING COUNT(*) > 1;

-- 12 months should be available in the aggregate customer/supplier datasets,
-- but some customer/market and supplier/region partitions intentionally have gaps.
WITH coverage AS (
   SELECT customer_id, market, COUNT(DISTINCT reporting_month) AS months
   FROM ranking_lab.customer_order_metrics
   GROUP BY customer_id, market
)
SELECT MIN(months) AS min_months, MAX(months) AS max_months,
       ROUND(AVG(months),2) AS avg_months
FROM coverage;

-- Once reviewed, COMMIT; replace with ROLLBACK to discard the inserts.
COMMIT;
