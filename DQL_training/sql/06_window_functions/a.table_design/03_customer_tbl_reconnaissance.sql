--CUSTOMER REPORTING COVERAGE

--Investigating table grain
--Confirm customer_id is not the table grain
select
    customer_id,
    count(*) as row_count
from ranking_lab.customer_order_metrics
group by customer_id
having count(*) > 1
    ;
--Results proof this is not the table grain


select
    customer_id,
    market,
    count(*) as row_count
from ranking_lab.customer_order_metrics
group by customer_id,
        market
having count(*) > 1
    ;
--Result proofs this is not the table grain

select
    customer_id,
    reporting_month,
    count(*) as row_count
from ranking_lab.customer_order_metrics
group by customer_id,
        reporting_month
having count(*) > 1
    ;
--Results proof this is not the table grain

select
    count(*) as row_count,
    count(distinct (customer_id, market, reporting_month)) as grain_combination
from ranking_lab.customer_order_metrics
    ;


select
    customer_id,
    market,
    reporting_month,
    count(*) as row_count
from ranking_lab.customer_order_metrics
group by customer_id,
        market,
        reporting_month
having count(*) > 1
    ;
--Results proof that this is the table grain as the results come back nothing,
--evidence is that their is no row count in the grain appearing more than once


--Investigate whether customers have multiple reporting months
select
    customer_id,
    count(distinct reporting_month) as reporting_months
from ranking_lab.customer_order_metrics
group by customer_id
order by reporting_months desc
    ;
--


--Data range investigation
select
    min(reporting_month) as earliest_month,
    max(reporting_month) as latest_month,
    count(*) as total_records,
    count(distinct customer_id) as customers
from ranking_lab.customer_order_metrics
    ;
--Comment: the difference between the earliest month and the last month is only
--one month. Having a one month disparity will reesult to a more monotonous drills
--set up.


--1. Determine how many distinct reporting months exist
select
    count(distinct reporting_month) as reporting_months_count
from ranking_lab.customer_order_metrics
    ;
    --Answer: 2

--2. How many distinct markets exist
select
    count(distinct market) as markets_count
from ranking_lab.customer_order_metrics
    ;
    --Answer: 3

--3. How many customer_market combinations exist
with customer_market_combo as (
    select
        customer_id,
        market,
        count(*) as combinations_count
    from ranking_lab.customer_order_metrics
    group by customer_id,
            market
)
select
    count(*) as row_count
from customer_market_combo
    ;
    --Answer: all customer market combinations appear twice(as evident in the
    --first CTE output. Their are a total of 36 combinations)


--4. What is the minimum, maximum, and average number of reporting months per
--customer-market combination
with combo_count as (
    select
        customer_id,
        market,
        count(distinct reporting_month) as reporting_months
    from ranking_lab.customer_order_metrics
    group by customer_id,
            market
)
select
    min(reporting_months) as earliest_month,
    max(reporting_months) as latest_month,
    round(avg(reporting_months), 2) as avg_customer_mkt_combo
from combo_count


--SUPPLIER HISTORICAL COVERAGE

--reporting month & supplier metrics
    select
        min(reporting_month) as earliest_reporting_month,
        max(reporting_month) as latest_reporting_month,
        count(distinct reporting_month) as month_count,
        count(distinct supplier_id) as supplier_count
    from ranking_lab.supplier_performance
    ;
    --earliest_reporting_month = 2026-08-01
    --latest_reporting_month = 2026-09-01


--max number of monthly observations for a supplier within a region
with supplier_region as (
    select
        supplier_id,
        region,
        count(distinct reporting_month) as supplier_month_count
    from ranking_lab.supplier_performance
    group by supplier_id,
            region
    order by supplier_id,
            region
)
select
    max(supplier_month_count) as max_supplier_month_count
from supplier_region
    ;
    --max_supplier_month_count = 2


--INVENTORY SNAPSHOT COVERAGE
select
    min(observed_at) as earliest_observed_time,
    max(observed_at) as latest_observed_time,
    count(distinct observed_at:: date) as observation_dates_count
from ranking_lab.inventory_snapshots
    ;


with warehouse_sku as (
    select
        warehouse_city,
        sku,
        count(*) as warehouse_sku_count
    from ranking_lab.inventory_snapshots
    group by warehouse_city,
            sku
)
select
    min(warehouse_sku_count) as min_warehouse_sku_count,
    max(warehouse_sku_count) as max_warehouse_sku_count
from warehouse_sku
    ;


--CUSTOMER COVERAGE
with month_market_counts as (
    select
        count(distinct reporting_month) as total_months,
        count(distinct market) as total_markets
    FROM ranking_lab.customer_order_metrics
),
customer_market as (
    select
        customer_id,
        market,
        count(distinct reporting_month) as reporting_months
    from ranking_lab.customer_order_metrics
    group by
        customer_id,
        market
),
customer_market_summary as (
    select
        count(*) as customer_market_combinations,
        min(reporting_months) as min_months,
        max(reporting_months) as max_months,
        round(avg(reporting_months), 2) as avg_months
    from customer_market
)
select
    mmc.total_months,
    mmc.total_markets,
    cms.customer_market_combinations,
    cms.min_months,
    cms.max_months,
    cms.avg_months
from month_market_counts as mmc
cross join customer_market_summary as cms
    ;



--Inventory revisions
select
    warehouse_city,
    sku,
    count(*) as total_records,
    count(distinct observed_at) as unique_observations,
    count(distinct source_revision) as revisions_count,
    min(observed_at) as earliest_observation,
    max(observed_at) as latest_observation
from ranking_lab.inventory_snapshots
group by warehouse_city,
        sku
        ;
--No, more than one record can be observed at a specific time
