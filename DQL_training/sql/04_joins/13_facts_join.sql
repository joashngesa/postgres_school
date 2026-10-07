--Block A: Establish the grains
--Drill 60: Inspect fact_order_item
    --Determine whether order_item_id uniquely identifies row
    select
        order_item_id,
        count(*) as row_count
    from join_lab.fact_order_item
    group by order_item_id
    having count(*) > 1;

select
    count(*) as total_rows,
    count(distinct order_item_id) as distinct_order_items,
    count(*) - count(distinct order_item_id) as duplicate_rows
from join_lab.fact_order_item;



--Drill 61: Inspect shipment_event grain
select
    count(*) as total_rows,
    count(distinct shipment_event_id) as distinct_shipment_events,
    count(distinct order_id) as distinct_orders
from join_lab.fact_shipment_event;



--Drill 62: shipment cardinality
select
    order_id,
    count(*) AS order_item_count
from join_lab.fact_order_item
group by order_id
order by order_item_count desc;

with order_item_counts as (
    select
        order_id,
        count(*) AS order_item_count
    from join_lab.fact_order_item
    group by order_id
)
select
    min(order_item_count) as min_items,
    max(order_item_count) as max_items,
    round(avg(order_item_count), 2) as avg_items
from order_item_counts;

with shipment_counts as (
    select
        order_id,
        count(*) as shipment_event_count
    from join_lab.fact_shipment_event
    group by order_id
)
select
    min(shipment_event_count) as min_events,
    max(shipment_event_count) as max_events,
    round(avg(shipment_event_count), 2) as avg_events
from shipment_counts;



--Drill 63: Inspect return grain
select
    count(*) as row_count,
    count(distinct order_item_id) as order_item_count
from join_lab.fact_return;

select
    order_item_id,
    count(*) as return_count
from join_lab.fact_return
group by order_item_id
having count(*) > 1;

--order_item_id is the table grain as each row represents one order_item_id



--Block B: Controlled fact to fact fan-out
--Drill 64: Establish order_item baseline
select
    count(*) as row_count,
    count(distinct order_item_id) as distinct_order_items,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_revenue
from join_lab.fact_order_item;



--Drill 65: Perform the dangerous join
select
    count(*) as joined_row_count,
    count(distinct order_item_id) as distinct_order_items,
    sum(foi.units_ordered) as joined_total_units,
    sum(foi.units_ordered * foi.unit_price) as joined_gross_revenue
from join_lab.fact_order_item as foi
join join_lab.fact_shipment_event as fse
on fse.order_id = foi.order_id
    ;



--Drill 66: Measure inflation
with baseline_tbl as (
    select
        order_id,
        count(*) as baseline_rows,
        sum(units_ordered * unit_price) as baseline_revenue
    from join_lab.fact_order_item as foi
    group by order_id
),
joined_tbl as (
    select
        foi.order_id,
        count(*) as joined_rows,
        sum(foi.units_ordered * foi.unit_price) as joined_revenue
    from join_lab.fact_order_item as foi
    join join_lab.fact_shipment_event as fse
    on fse.order_id = foi.order_id
    group by foi.order_id
)
select
    bt.baseline_rows,
    jt.joined_rows,
    jt.joined_rows - bt.baseline_rows as row_increase,
    bt.baseline_revenue,
    jt.joined_revenue,
    jt.joined_revenue - bt.baseline_revenue as revenue_increase,
    round(((jt.joined_revenue - bt.baseline_revenue) / nullif(
        bt.baseline_revenue, 0))
     * 100, 2) as revenue_increase_pct
from baseline_tbl as bt
join joined_tbl as jt
on jt.order_id = bt.order_id;



--Drill 67: Find the corrupted fact rows
with baseline as (
    select
        order_id,
        count(order_item_id) as order_item_count,
        count(*) as row_count
    from join_lab.fact_order_item
    group by order_id
),
joined as (
    select
        foi.order_id,
        count(distinct fse.shipment_event_id) as shipment_event_count,
        count(*) as actual_join_rows
    from join_lab.fact_order_item as foi
    join join_lab.fact_shipment_event as fse
    on fse.order_id = foi.order_id
    group by foi.order_id
)
select
    bs.order_id,
    bs.order_item_count,
    jn.shipment_event_count,
    bs.order_item_count * jn.shipment_event_count as expected_join_rows,
    bs.row_count * jn.shipment_event_count as expected_join_rows_rc,
    jn.actual_join_rows
from baseline as bs
join joined as jn
on jn.order_id = bs.order_id
