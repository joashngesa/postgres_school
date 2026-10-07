select *
from join_lab.stg_order_line;


select *
from join_lab.fact_return;

select
    return_id,
    count(distinct return_id) as return_id_count,
    count(distinct order_item_id) as order_item_count,
    count(*) as row_count
from join_lab.fact_return
group by return_id;

select *
from join_lab.fact_order_item;

select *
from join_lab.fact_shipment_event;

select
    order_id,
    count(*) as row_count
from join_lab.fact_shipment_event
group by order_id;

select
    *
from join_lab.fact_order_item as foi
join join_lab.fact_shipment_event as fse
on fse.order_id = foi.order_id
order by foi.order_item_id,
        foi.order_id;


with baseline_tbl as (
    select
        order_id,
        count(distinct order_item_id) as order_item_count,
        sum(units_ordered * unit_price) as revenue
    from join_lab.fact_order_item as foi
    group by order_id
)
select
    foi.order_id,
    count(distinct fse.shipment_event_id) as shipment_event_count
    bt.revenue
from baseline_tbl as bt
join join_lab.fact_shipment_event as fse
on fse.order_id = bt.order_id
join join_lab.fact_return as fr
on fr.order_item_id = ??
group by foi.order_id
