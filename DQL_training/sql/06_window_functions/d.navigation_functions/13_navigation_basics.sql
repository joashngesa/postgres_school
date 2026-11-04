--Drill 1: Previous customer revenue
--Compare each customer's monthly revenue against their preceding recorded month
--within the same market

select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    lag(net_revenue) over (
        partition by customer_id, market
        order by reporting_month) as previous_revenue
from ranking_lab.customer_order_metrics
order by customer_id,
        market,
        reporting_month
    ;
--Q1: The aim was to find customer's monthly revenue within the same market making
--customer & market the columns to partition
--Q2: In each partition the previous check starts from first check thus the first row
--in each partition means that the previous check is not present thus it brings back null
--Q3: No it brings back the same number of rows because lag does not group the table,
--it acts as a window function


--Drill 2: Next customer Revenue
--Examine the next recorded revenue observation for each customer-market combination
select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    lead(net_revenue) over (partition by customer_id, market
        order by reporting_month) as next_revenue
from ranking_lab.customer_order_metrics
    ;
--Q2: The last record in each partition brings back null
--Q2: No, it checks the next row.
--Q3: After February, the next record checks the value in the next row, meaning it
--checks April after Februaury.



--Drill 3: Previous supplier performance
--Examine how supplier performance evolves over successive reporting periods
    --*supplier_name is not present in the table
--Retrieve the previous performance score for each supplier within each region.
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    lag(performance_score) over (partition by supplier_id, region
        order by reporting_month) as previous_performance_score
from ranking_lab.supplier_performance
    ;
--Q1: partitioning by supplier alone returns the performance & the previous  score for each
--supplier but adding region to the partition returns the suppliers score in each region
--Q2: The current row is the first in its partition & The navigation succeeds, but the
--retrieved value is missing.
--Q3: In the previous_performance_score it returns the same value of the duplicate row



--Drill 4: Previous inventory snap shot
--Examine the inventory value recorded immidiately before each snapshot
        --Check the grain of the table
        select
            snapshot_id,
            count(*) as record_count
        from ranking_lab.inventory_snapshots
        group by snapshot_id
        having count(*) > 1;

select
    warehouse_city,
    sku,
    snapshot_id,
    observed_at,
    source_revision,
    available_units,
    lag(available_units) over (partition by warehouse_city, sku
        order by observed_at, source_revision, snapshot_id) as previous_available_units
from ranking_lab.inventory_snapshots
    ;
--Q1: snapshot_id is used as a value included in the sequence that the returned values
--are arranged
--Q2: Yes, when the row has a duplicate value
--Q3: It represents the previous available_units for each warehouse with the same sku



--Revison B: Diagnose null navigation
--Examine previous supplier within each region
with navigation_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        lag(record_id) over (partition by supplier_id, region order by
            reporting_month, record_id) as previous_record_id,
        lag(performance_score) over (partition by supplier_id, region order by
            reporting_month, record_id) as previous_performance_score
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    previous_record_id,
    previous_performance_score,
    case
        when previous_record_id is null then 'No previous record'
        when previous_performance_score is null then 'Previous score missing'
        else 'Previous score available'
    end as performance_classification
from navigation_tbl
    ;
