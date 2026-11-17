--Drill 1: First recorded customer revenue
--Establish the earliest recorded revenue observation for each customer
select
    customer_id,
    reporting_month,
    net_revenue,
    first_value(net_revenue) over (partition by customer_id order by
        reporting_month rows between unbounded preceding
        and unbounded following) as earliest_customer
from ranking_lab.customer_order_metrics
    ;
--Even without the full-partition frame, the first value is still selected from
--the first value in the partition frame thus the value stays the same



--Drill 2: Latest recorded customer revenue
--Compare each customer's historical revenue against thier most recently recorded
--revenue
select
    customer_id,
    reporting_month,
    net_revenue,
    last_value(net_revenue) over (partition by customer_id order by
        reporting_month rows between unbounded preceding and
        unbounded following) as latest_revenue
from ranking_lab.customer_order_metrics
    ;
    select
    customer_id,
    reporting_month,
    net_revenue,
    last_value(net_revenue) over (partition by customer_id order by
        reporting_month) as latest_revenue
from ranking_lab.customer_order_metrics
    ;
--Removing the window frame will return the latest value in the partition up to the
--current row range whereas using the window frame returns the last value in the last
--row position of the partition



--Drill 3: Second recorded supplier performance
--Examine supplier's second recorded performance observations
        --Examine table
        select
            count(*) as row_count,
            count(distinct record_id) as record_count,
            count(distinct supplier_id) as supplier_count
        from ranking_lab.supplier_performance;

select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    nth_value(performance_score, 2) over (partition by supplier_id
        order by reporting_month, record_id rows between unbounded preceding
        and unbounded following) as second_performance_score
from ranking_lab.supplier_performance
    ;
    --When supplier has only 1 recorded info, it returns the null value


--Drill 4: First and last inventory observation
--Identify the first and the last inventory observations within each warehouse product
--combination
        --Inspect table
        select * from ranking_lab.warehouse_inventory;

        select
            count(*) as row_count,
            count(distinct inventory_id) as inventory_count,
            count(distinct sku) as product_count
        from ranking_lab.warehouse_inventory;

select
    warehouse_city,
    sku,
    available_units,
    --i have used inventory_id as the column for listing chronological observations
    --of the inventories, assuming that observations were labelled by issuing
    --inventory_id, the table has no any timestamp column
    first_value(available_units) over (partition by warehouse_city, sku
        order by inventory_id rows between unbounded preceding
        and unbounded following) as first_inventory_units,
    last_value(available_units) over (partition by warehouse_city, sku
        order by inventory_id rows between unbounded preceding
        and unbounded following) as last_inventory_units
from ranking_lab.warehouse_inventory
order by warehouse_city,
        sku
        ;



--Drill 5: Customer revenue position analysis
--Compare the first, second and latest recorded revenue observations for every customer
select
    customer_id,
    reporting_month,
    net_revenue,
    first_value(net_revenue) over (partition by customer_id order by
        reporting_month rows between unbounded preceding
        and unbounded following) as first_revenue,
    nth_value(net_revenue, 2) over (partition by customer_id order by
        reporting_month rows between unbounded preceding
        and unbounded following) as second_revenue,
    last_value(net_revenue) over (partition by customer_id order by
        reporting_month rows between unbounded preceding
        and unbounded following) as latest_revenue
from ranking_lab.customer_order_metrics
    ;
    --nth value brings back same value in accordance to the partition and the window frame
    --whereas lead brings back the previous value based on the current row



--Drill 6: Investigating last_value() behaviour
select
    supplier_id,
    reporting_month,
    performance_score,
    last_value(performance_score) over (partition by supplier_id order by
        reporting_month, supplier_id rows between unbounded preceding
        and unbounded following) as latest_performance_score
from ranking_lab.supplier_performance
    ;
--Without using window frames, the last value is done up to the current row position
--as opposed to whenn using window frames where we get the last value of the value
--at the end of the partition and the frame



--Drill 7: Rows vs range investigation
select
    supplier_id,
    reporting_month,
    performance_score,
    last_value(performance_score) over (partition by supplier_id order by
        reporting_month rows between unbounded preceding
        and current row) as row_last_score,
    last_value(performance_score) over (partition by supplier_id order by
        reporting_month range between unbounded preceding
        and current row) as range_last_score
from ranking_lab.supplier_performance
    ;
    select
    supplier_id,
    reporting_month,
    performance_score,
    last_value(performance_score) over (partition by supplier_id order by
        reporting_month, supplier_id rows between unbounded preceding
        and current row) as row_last_score,
    last_value(performance_score) over (partition by supplier_id order by
        reporting_month, supplier_id range between unbounded preceding
        and current row) as range_last_score
from ranking_lab.supplier_performance
--using rows brings back the last row value in the partition regarding the current row
--as the last value to be added whereas using range brings back the last peer value
--in the partition

-- Adding a unique tie breaking column can eliminate peer groups, making rows and ranges
--behave identically for this particular frame boundaries



--Drill 8: Third recorded fleet performance observation
--Examine the third recorded delivery performance observation for each vehicle

    --Examine table
    select
        count(*) as row_count,
        count(distinct driver_id) as driver_count,
        --The table has chronological column, we check the number of values below to
        --examine if driver_id can be used chronologically
        min(driver_id) as first_driver_id,
        max(driver_id) as last_driver_id
    from ranking_lab.fleet_delivery_performance;

select
    driver_id,
    completed_deliveries,
    nth_value(completed_deliveries, 3) over (order by driver_id
        rows between unbounded preceding and
        unbounded following) as third_completed_delivery
from ranking_lab.fleet_delivery_performance;
--the table grain is 1 row per driver_id thus i do not know which column to use
--as observation



--Drill 9: First & latest shipment events
--Examine the earliest & latest recorded shipment events associated with each order

        select * from join_lab.fact_shipment_event;

        select
            count(*) as row_count,
            count(distinct shipment_event_id) as shipment_event_id_count,
            count(distinct order_id) as order_count
        from join_lab.fact_shipment_event;

select
    order_id,
    shipment_event_id,
    event_date,
    shipping_cost,
    first_value(shipment_event_id) over (partition by order_id order by
        event_date, shipment_event_id rows between unbounded preceding
        and unbounded following) as earliest_shipment,
    last_value(shipment_event_id) over (partition by order_id order by
        event_date, shipment_event_id rows between unbounded preceding
        and unbounded following) as latest_shipment
from join_lab.fact_shipment_event
    ;
--When tow events share the same timestamp, tyhe other column used in the order by
--window, ie shipment_event_id separates the tie



--Drill 10: Independent window frame engineering challenge
--Evaluate how customer revenue has evolved between the first and latest recorded observations
--Identify the third recorded revenue observation wheren available
with revenue_metrics as (
    select
        customer_id,
        reporting_month,
        net_revenue,
        first_value(net_revenue) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
            and unbounded following) as first_revenue,
        nth_value(net_revenue, 3) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
            and unbounded following) as third_revenue,
        last_value(net_revenue) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
            and unbounded following) as latest_revenue
    from ranking_lab.customer_order_metrics
)
select
    customer_id,
    reporting_month,
    net_revenue,
    first_revenue,
    third_revenue,
    latest_revenue,
    (latest_revenue - first_revenue) as revenue_change,
    round(100.0 * (latest_revenue - first_revenue) / nullif(
        first_revenue, 0), 2) as revenue_growth_pct
from revenue_metrics
    ;
--When first revenue is more than the net_revenue

--The first_revenue, latest  revenue becomes 0 &  the first two values of third_revenue
--becomes null

--yes, when it is the last row in the table is null

--It returns back null value

--The first & the latest observations give back the overall analysis of the revenue.
--Calculating consecutive months is used in progressive analysis with month to month
--progressive analysis
