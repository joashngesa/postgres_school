--Drill 5: Two period customer navigation
--Inspect the preceding record and the record two positions earlier

select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    lag(net_revenue) over (partition by customer_id, market order by
        reporting_month) as previous_revenue,
    lag(net_revenue, 2) over (partition by customer_id, market order by
        reporting_month) as revenue_2_records_ago
from ranking_lab.customer_order_metrics
    ;


--Drill 6: Supplier previous and next scores
--Inspect each supplier's performance relative to its preceding and following
--recorded assesments
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    lag(performance_score) over (partition by supplier_id, region order by
        reporting_month) as previous_score,
    lead(performance_score) over (partition by supplier_id, region order by
        reporting_month) as next_score
from ranking_lab.supplier_performance
    ;



--Drill 7: Inventory revision navigation
--Examine the sequence of revisions recorded for individual warehouse-sku observations
--the partition must represent one inventory observation for one warehouse and SKU.
select
    warehouse_city,
    sku,
    observed_at,
    source_revision,
    snapshot_id,
    available_units,
    lag(available_units) over (partition by warehouse_city, sku, observed_at
        order by source_revision, snapshot_id) as previous_revision_units
from ranking_lab.inventory_snapshots
    ;
--Drill 4 checks the previous available_units while drill 3 checks the previous
--source_revision
--when a row has no predecessor within its observation partition and when the existing
--available units is null
--It does not automatically indicate that the revision number is missing. In instances
--where the value sequence skip a number for example revision 2 and 4, it would not automatically
--report the missing number
--it does not guarantee that the physical stock moved, it shows what the snapshot recorded
--at the particular recorded time



--Drill 8: Previous and next reporting periods
--The analytics team suspects that some customer-market reporting sequences contain
--missing months.
--Before investigating the gaps, they want to inspect the chronological sequence of
--reporting dates.

select
    customer_id,
    market,
    reporting_month,
    lag(reporting_month) over (partition by customer_id, market
        order by reporting_month) as previous_reporting_month,
    lead(reporting_month) over (partition by customer_id, market
        order by reporting_month) as next_reporting_month
from ranking_lab.customer_order_metrics
    ;
--April
--No. the preceding & proceeding values are positional based rather than value based
--We can check the previous month and compare it with the current month and or proceeding
--month and identify where the gaps are in the month sequence.



        --Q1: Partition grain
        -- You need to add market to the partition because without it the comparison is being
        --made among customers alone as opposed to customers within each market
        --Q2: Observation grain
        --3 rows because the first row of the partition has no predecessor



--Drill 9: Shipment exception sequence
--Investigate the chronological sequence of recorded shipment exceptions

select
    exception_id,
    shipment_id,
    region,
    reported_at,
    lag(exception_id) over (partition by region order by
        reported_at, shipment_id, exfception_id) as previous_exception
from ranking_lab.shipment_exceptions
    ;

select * from ranking_lab.warehouse_inventory
--Drill 10: Independent navigation challenge
--Investigate how available inventory quantities compare between adjacent products
--within each warehouse

select
    inventory_id,
    warehouse_city,
    category,
    available_units,
    lag(available_units) over (partition by warehouse_city, category order by
        available_units desc, inventory_id) as preceding_units,
    lead(available_units) over (partition by warehouse_city, category order by
        available_units desc, inventory_id) as proceeding_units
from ranking_lab.warehouse_inventory
    ;
--Q1. What does the previous record mean when ordering inventory quantities in
--descending order?
--the previous row in the sorted products arranged from highest to lowest available units

--Q2. Why is deterministic ordering important when two products have identical inventory
--quantities?
--it uses the column used to choose which row comes first

--Q3. Does moving to the next record necessarily mean moving to a product with fewer
--available units?
--yes, when units are arranged in descending order unless it is the last row in the partition

--Q4. How would you validate that your query has preserved every original inventory record?
--by counting the number of rows & the distinct inventory_id



    --Extra drill
    --Retrieve the next chronological revenue observation for each customer-market combination
    select
        customer_id,
        market,
        reporting_month,
        net_revenue,
        lead(net_revenue) over (partition by customer_id, market order by
            reporting_month, customer_id) as next_revenue
    from ranking_lab.customer_order_metrics
        ;


    --Extra drill
    --Explain why you partitioned shipment exceptions by region, and adjust the ordering
    --to ensure deterministic navigation.
    select
        exception_id,
        shipment_id,
        region,
        reported_at,
        lag(exception_id) over (partition by region order by
            reported_at, shipment_id, exception_id) as previous_exception
    from ranking_lab.shipment_exceptions
        ;
    --The aim was to find the chronological sequence of recorded shipment exceptions
    --within each region

