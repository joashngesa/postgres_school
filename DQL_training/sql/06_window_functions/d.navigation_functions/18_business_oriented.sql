--Part 4: Block C
--Drill 11: Driver performance evolution
--Compare each driver's initial delivery performance against their latest recorded
--performance. Identify whether individual drivers have improved / detoriated

with first_last_on_time_pct as (
    select
        driver_id,
        depot,
        reporting_month,
        on_time_pct,
        first_value(on_time_pct) over (partition by driver_id order by
            reporting_month) as first_on_time_pct,
        last_value(on_time_pct) over (partition by driver_id
            order by reporting_month rows between
            unbounded preceding and unbounded following) as latest_on_time_pct
    from ranking_lab.fleet_delivery_performance_history
)
select
    driver_id,
    depot,
    reporting_month,
    on_time_pct,
    first_on_time_pct,
    latest_on_time_pct,
    latest_on_time_pct - first_on_time_pct as overall_on_time_pct_change
from first_last_on_time_pct
    ;
--Q:Should performance change be calculated using the current row or the latest observation?
--performance_change per driver is calculated using latest_row minus earliest_row

--Q: What would a negative performance change indicate?
--Where the current on_time_pct has decreased compared with the first value for the partition

--Q: Why should the historical order be based on reporting_month rather than driver_id?
--reporting month represents a chronological order of observation compared to driver_id which
--represents driver identitity


--Drill 12: Second recorded driver performance
--Examine how drivers performed during their second recorded reporting period
--Management is particularly interested in comparing their initial performance with the second
--observation

with completed_deliveries_tbl as (
    select
        driver_id,
        depot,
        reporting_month,
        completed_deliveries,
        first_value(completed_deliveries) over (partition by driver_id order by
            reporting_month) as first_completed_delivery,
        nth_value(completed_deliveries, 2) over (partition by driver_id order by
            reporting_month rows between unbounded preceding
            and unbounded following) as second_completed_delivery
    from ranking_lab.fleet_delivery_performance_history
)
select
    driver_id,
    depot,
    reporting_month,
    completed_deliveries,
    first_completed_delivery,
    second_completed_delivery,
    second_completed_delivery - first_completed_delivery as observation_difference
from completed_deliveries_tbl
    ;
--If an observation has only one driver, we get the value null which is appropriate
--for representing the scenario



--Drill 13: Supplier performance: first, third, latest
--Performance team wants to understand how supplier evaluations evolve over time
    select
        *
    from ranking_lab.supplier_performance
    order by supplier_id

with performance_score_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        first_value(performance_score) over (partition by supplier_id
            order by reporting_month, record_id) as first_score,
        nth_value(performance_score, 3) over (partition by supplier_id
            order by reporting_month, record_id
                rows between unbounded preceding and
                    unbounded following) as third_score,
        last_value(performance_score) over (partition by supplier_id
            order by reporting_month, record_id
                rows between unbounded preceding and
                    unbounded following) as last_score
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    first_score,
    third_score,
    last_score,
    last_score - first_score as score_change
from performance_score_tbl
    ;
--Investigation Q: No, it would return the null value in the third position



--Drill 14: Warehouse inventory positional ranking
--Warehouse planning department wants to understand inventory concentration within
--its warehouse network
--For each warehouse, management wants to identify the product with the highest available
--inventory, the second highest inventory and the product with the lowest available inventory

with non_null_tbl as (
    select
        *
    from ranking_lab.warehouse_inventory
    where available_units is not null
)
select
    warehouse_city,
    sku,
    available_units,
    first_value(available_units) over (partition by warehouse_city
        order by available_units desc) as highest_unit,
    nth_value(available_units, 2) over (partition by warehouse_city
        order by available_units desc, inventory_id
            rows between unbounded preceding
                and unbounded following) as second_highest_unit,
    last_value(available_units) over (partition by warehouse_city
        order by available_units desc
            rows between unbounded preceding
                and unbounded following) as lowest_unit
from non_null_tbl
order by warehouse_city
    ;

--Alternatively:
with non_null_tbl as (
    select
        *
    from ranking_lab.warehouse_inventory
    where available_units is not null
)
select
    warehouse_city,
    sku,
    available_units,
    max(available_units) over (partition by warehouse_city) as highest_unit,
    nth_value(available_units, 2) over (partition by warehouse_city
        order by available_units desc, inventory_id
            rows between unbounded preceding
                and unbounded following) as second_highest_unit,
    min(available_units) over (partition by warehouse_city) as lowest_unit
from non_null_tbl
order by warehouse_city
    ;

--Because desc moves the highest position to first

--desc moves the lowest value to the last position

--The second raw in the ordered sequence

--Add another column to break the tie in the order by frame of the window function



--Drill 15: Shipment cost position analysis
--The logistics finance department wants to investigate how shipment-related costs vary
--across recorded shipment events associated with the same order
        --Investigate the orders distribution
        select
            order_id,
            count(*) as order_count
        from join_lab.fact_shipment_event
        group by order_id

with recorded_shipping_tbl as (
    select
        order_id,
        shipment_event_id,
        event_date,
        shipping_cost,
        first_value(shipping_cost) over (partition by order_id order by
            event_date, shipment_event_id) as first_shipping_cost,
        nth_value(shipping_cost, 2) over (partition by order_id order by
            event_date, shipment_event_id  rows between unbounded preceding
                and unbounded following) as second_shipping_cost,
        last_value(shipping_cost) over (partition by order_id order by
            event_date, shipment_event_id rows between unbounded preceding
                and unbounded following) as latest_shipping_cost
    from join_lab.fact_shipment_event
)
select
    order_id,
    shipment_event_id,
    event_date,
    shipping_cost,
    first_shipping_cost,
    second_shipping_cost,
    latest_shipping_cost,
    latest_shipping_cost - first_shipping_cost as shipping_cost_difference
from recorded_shipping_tbl
    ;

    --Latest shipping cost is 20 because the order follows the column selected
    --in the order by window frame
