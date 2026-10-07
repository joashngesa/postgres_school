--Block E: Measure corruption across three facts
--Drill 75: Build the dangerous three fact join
    --Investigate comparison table
    select
        count(*) as row_count,
        count(distinct order_item_id) as distinct_order_items,
        sum(units_ordered) as total_units,
        sum(units_ordered * unit_price) as gross_revenue
    from join_lab.fact_order_item;

select
    count(*) as joined_rows,
    count(distinct foi.order_item_id) as distinct_order_items,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_revenue
from join_lab.fact_order_item as foi
join join_lab.fact_shipment_event as fse
on fse.order_id = foi.order_id
left join join_lab.fact_return as fr
on fr.order_item_id = foi.order_item_id
    ;



--Drill 76: Explain measure multiplication per order
with baseline_tbl as (
    select
        order_id,
        count(distinct order_item_id) as order_item_count,
        sum(units_ordered * unit_price) as baseline_revenue
    from join_lab.fact_order_item as foi
    group by order_id
),
joined_tbl as (
select
    foi.order_id,
    count(*) as actual_join_rows,
    count(distinct fse.shipment_event_id) as shipment_event_count,
    sum(foi.units_ordered * foi.unit_price) as joined_revenue
from join_lab.fact_order_item as foi
join join_lab.fact_shipment_event as fse
on fse.order_id = foi.order_id
group by foi.order_id
)
select
    bt.order_id,
    bt.order_item_count,
    jt.shipment_event_count,
    bt.order_item_count * jt.shipment_event_count as expected_item_event_count,
    jt.actual_join_rows,
    bt.baseline_revenue,
    jt.joined_revenue,
    round(
        joined_revenue / nullif(baseline_revenue, 0), 2) as revenue_multiplier
from baseline_tbl as bt
join joined_tbl as jt
on jt.order_id = bt.order_id
    ;



--Drill 77: Repair the three-fact analysis
    --Comparison query:
    select
        count(*) as row_count,
        count(distinct order_item_id) as distinct_order_items,
        sum(units_ordered) as total_units,
        sum(units_ordered * unit_price) as gross_revenue
    from join_lab.fact_order_item;

with shipment_summary as (
    select
        order_id,
        count(*) AS shipment_event_count
    from join_lab.fact_shipment_event
    group by order_id
),
return_summary as (
    select
        order_item_id,
        count(*) as return_count
    from join_lab.fact_return
    group by order_item_id
)
select
    foi.order_item_id,
    foi.order_id,
    foi.units_ordered * foi.unit_price as item_revenue,
    coalesce(ss.shipment_event_count, 0) as shipment_event_count,
    coalesce(rs.return_count, 0) as return_count
from join_lab.fact_order_item as foi
left join shipment_summary as ss
on ss.order_id = foi.order_id
left join return_summary as rs
on rs.order_item_id = foi.order_item_id;
    ;
--When i use left join in the result query, it includes all records including
--  order_items that were not returned, when inner join is used, it only returns
--  order_items that were returned
