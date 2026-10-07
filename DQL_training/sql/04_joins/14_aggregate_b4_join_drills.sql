--Block C: Aggregate before join
--Drill 68: Collapse shipment events to order grain
with baseline as (
    select
        order_id,
        count(distinct shipment_event_id) as shipment_event_count
    from join_lab.fact_shipment_event
    group by order_id
)
select
    count(*) as row_count,
    count(distinct order_id) as distinct_orders
from baseline
    ;



--Drill 69: Safe shipment summary -> order_item join
with shipment_summary as (
    select
        order_id,
        count(shipment_event_id) as shipment_event_count
    from join_lab.fact_shipment_event
    group by order_id
)
select
    count(*) as row_count,
    count(distinct foi.order_item_id) as distinct_order_items,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_revenue
from join_lab.fact_order_item as foi
join shipment_summary as ss
on ss.order_id = foi.order_id
    ;


--Drill 70: Build an order-item return summary
with return_summary as (
    select
        order_item_id,
        count(*) as return_count
    from join_lab.fact_return
    group by order_item_id
)
select
    count(*) as row_count,
    count(distinct order_item_id) as distinct_order_items
from return_summary;



--Drill 71: Safe return join at order-item grain
select
    count(*) as row_count,
    count(distinct foi.order_item_id) as distinct_order_items,
    sum(foi.units_ordered * foi.unit_price) as gross_revenue,
    coalesce(count(*) filter(where foi.returned is True), 0) as returned_item_count,
    count(fr.return_id) as total_return_records
from join_lab.fact_order_item as foi
left join join_lab.fact_return as fr
on fr.order_item_id = foi.order_item_id
    ;



--Block D: Cross-grain fact explosion
--Drill 72: Connect shipment events to returns through the item fact
    select
        order_id,
        count(*) as row_count
    from join_lab.fact_shipment_event
    group by order_id;

    select *
    from join_lab.fact_shipment_event;

select
    foi.order_item_id,
    foi.order_id,
    fse.shipment_event_id,
    fr.return_id
from join_lab.fact_order_item as foi
join join_lab.fact_shipment_event as fse
on fse.order_id = foi.order_id
join join_lab.fact_return as fr
on fr.order_item_id = foi.order_item_id
    ;



--Drill 73: Predict the explosion before joining
with shipment_tbl as (
    select
        order_id,
        count(shipment_event_id) as shipment_event_count
    from join_lab.fact_shipment_event
    group by order_id
),
return_tbl as (
    select
        foi.order_id,
        count(distinct fr.return_id) as return_count
    from join_lab.fact_order_item as foi
    join join_lab.fact_return as fr
    on fr.order_item_id = foi.order_item_id
    group by foi.order_id
)
select
    st.order_id,
    st.shipment_event_count,
    rt.return_count,
    st.shipment_event_count * rt.return_count as expected_join_rows
from shipment_tbl as st
join return_tbl as rt
on rt.order_id = st.order_id
    ;



--Drill 74: Verify the predicted explosion
with joining_tbl as (
    select
        foi.order_id,
        count(distinct fse.shipment_event_id) as shipment_event_count,
        count(distinct return_id) as return_count,
        count(*) as actual_join_rows
    from join_lab.fact_order_item as foi
    join join_lab.fact_shipment_event as fse
    on fse.order_id = foi.order_id
    join join_lab.fact_return as fr
    on fr.order_item_id = foi.order_item_id
    group by foi.order_id
)
select
    order_id,
    shipment_event_count,
    return_count,
    actual_join_rows,
    shipment_event_count * return_count as expected_join_rows
from joining_tbl
    ;
