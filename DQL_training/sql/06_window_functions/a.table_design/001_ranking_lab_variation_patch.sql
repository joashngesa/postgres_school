-- LEVEL 2 RANKING LAB: CONTROLLED VARIATION PATCH
-- Run once AFTER ranking_lab_setup.sql. No tables are dropped.
-- Safe to rerun: the patch history prevents the adjustments from stacking.
BEGIN;
CREATE TABLE IF NOT EXISTS ranking_lab.lab_patch_history (
    patch_name text PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
);
DO $patch$
BEGIN
    IF EXISTS (SELECT 1 FROM ranking_lab.lab_patch_history WHERE patch_name = 'ranking_variation_v1') THEN
        RAISE NOTICE 'ranking_variation_v1 already applied; no data changed.';
    ELSE
        -- Preserve NULLs and preserve ties among equal score values in each region.
        -- Regions have deliberately different performance distributions.
        UPDATE ranking_lab.supplier_performance
        SET performance_score = CASE region
            WHEN 'West' THEN LEAST(100::numeric, performance_score + 2)
            WHEN 'Prairies' THEN GREATEST(0::numeric, performance_score - 3)
            ELSE performance_score
        END;

        -- Vary depot delivery volume and on-time performance independently.
        -- Keep equal on-time scores tied within depots and within valid 0-100 bounds.
        UPDATE ranking_lab.fleet_delivery_performance
        SET completed_deliveries = completed_deliveries + CASE depot
                WHEN 'Edmonton' THEN 12
                WHEN 'Calgary' THEN 6
                WHEN 'Vancouver' THEN 3
                WHEN 'Winnipeg' THEN 0
                ELSE 0
            END,
            on_time_pct = CASE depot
                WHEN 'Edmonton' THEN GREATEST(0::numeric, on_time_pct - 3)
                WHEN 'Calgary' THEN LEAST(100::numeric, on_time_pct + 1)
                WHEN 'Vancouver' THEN GREATEST(0::numeric, on_time_pct - 1)
                WHEN 'Winnipeg' THEN LEAST(100::numeric, on_time_pct + 2)
                ELSE on_time_pct
            END;
        INSERT INTO ranking_lab.lab_patch_history (patch_name)
        VALUES ('ranking_variation_v1');
        RAISE NOTICE 'Applied ranking_variation_v1.';
    END IF;
END
$patch$;
COMMIT;

-- Verify resulting aggregate distributions.
SELECT region, COUNT(*) AS total_records, COUNT(performance_score) AS evaluated_records,
       ROUND(AVG(performance_score),2) AS average_score,
       MIN(performance_score) AS lowest_score, MAX(performance_score) AS highest_score
FROM ranking_lab.supplier_performance GROUP BY region ORDER BY region;

SELECT depot, COUNT(*) AS driver_records, SUM(completed_deliveries) AS total_deliveries,
       ROUND(AVG(on_time_pct),2) AS average_on_time_pct,
       MIN(on_time_pct) AS lowest_on_time_pct, MAX(on_time_pct) AS highest_on_time_pct
FROM ranking_lab.fleet_delivery_performance GROUP BY depot ORDER BY depot;


--Investigation A.
with average_performance_score as (
    select
        region,
        avg(performance_score) as regional_avg_score
    from ranking_lab.supplier_performance
    group by region
)
select
    region,
    regional_avg_score,
    rank() over (order by regional_avg_score desc) as regional_ranking
from average_performance_score
    ;


--Investigation B: Compare depo ranking metrics
with depot_averages as (
    select
        depot,
        sum(completed_deliveries) as tot_completed_deliveries,
        avg(on_time_pct) as avg_on_time_pct
    from ranking_lab.fleet_delivery_performance
    group by depot
)
select
    depot,
    tot_completed_deliveries,
    round(avg_on_time_pct, 2) as avg_on_time_pct,
    rank() over (
        order by tot_completed_deliveries desc nulls last) as delivery_volume_rank,
    dense_rank() over (
        order by avg_on_time_pct desc nulls last) as on_time_performance_rank
from depot_averages
    ;


--Ivestigation C: Verify that ties still exist
select
    region,
    reporting_month,
    performance_score,
    count(*) as records_sharing_score
from ranking_lab.supplier_performance
where performance_score is not null
group by region,
        reporting_month,
        performance_score
having count(*) > 1
    ;


Investigation D.
select
    'supplier_performance' as table,
    count(*) as row_count
from ranking_lab.supplier_performance
union all
select
    'fleet_delivery_performance',
    count(*) as row_count
from ranking_lab.fleet_delivery_performance;

select
    record_id,
    count(*) as row_count
from ranking_lab.supplier_performance
group by record_id
having count(*) > 1;

select
    driver_id,
    count(*) as row_count
from ranking_lab.fleet_delivery_performance
group by driver_id
having count(*) > 1;
