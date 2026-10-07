--Drill 81:
--Management asks:
-- Build a trustworthy order-item operational dataset combining sales, shipment activity, and
--and return activity. The dataset must preserve original order-item measures and must not
--introduce fanout

with shipment_count as (
    select
        order_id,
        count(distinct shipment_event_id) as shipment_event_count
    from join_lab.fact_shipment_event
    group by order_id
),
shipment_summary as (
    select
        foi.order_item_id,
        foi.order_id,
        foi.units_ordered,
        foi.unit_price,
        coalesce(sc.shipment_event_count, 0) as shipment_event_count,
        (foi.units_ordered * foi.unit_price) as item_revenue
    from join_lab.fact_order_item as foi
    left join shipment_count as sc
    on sc.order_id = foi.order_id
),
return_summary as (
    select
        foi.order_item_id,
        count(distinct fr.return_id) as return_count
    from join_lab.fact_order_item as foi
    join join_lab.fact_return as fr
    on fr.order_item_id = foi.order_item_id
    group by foi.order_item_id
),
final_dataset as (
    select
        ss.order_item_id,
        ss.order_id,
        ss.units_ordered,
        ss.unit_price,
        ss.item_revenue,
        coalesce(ss.shipment_event_count, 0) as shipment_event_count,
        coalesce(rs.return_count, 0) as return_count
    from shipment_summary as ss
    left join return_summary as rs
    on rs.order_item_id = ss.order_item_id
)
select
    count(*) as row_count,
    count(distinct order_item_id) as distinct_final_order_items
from final_dataset;
