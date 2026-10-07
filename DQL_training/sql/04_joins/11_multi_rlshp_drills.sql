--Block G: Multi-relationship validation
--Drill 66: Customer/category/warehouse baseline
    -- Investigate customer
    select
        customer_key,
        count(*) as row_count
    from join_lab.dim_customer
    group by customer_key
    having count(*) > 1
        ;
    --Investigate product
    select
        product_key,
        count(*) as row_count
    from join_lab.dim_product
    group by product_key
    having count(*) > 1
        ;
    --Investigate warehouse
    select
        warehouse_key,
        count(*) as row_count
    from join_lab.dim_warehouse
    group by warehouse_key
    having count(*) > 1
        ;

select
    dc.customer_segment,
    dp.category,
    dw.warehouse_city,
    count(distinct foi.order_id) as distinct_orders,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join join_lab.dim_customer as dc
on dc.customer_key = foi.customer_key
join join_lab.dim_product as dp
on dp.product_key = foi.product_key
join join_lab.dim_warehouse as dw
on dw.warehouse_key = foi.warehouse_key
group by dc.customer_segment,
        dp.category,
        dw.warehouse_city
order by customer_segment
    ;



--Drill 67: Add suppliers
    --Investigative queries:
    select
        product_key,
        count(*) as row_count
    from join_lab.bridge_product_supplier
    where preferred_supplier is True
    group by product_key;

    select
        supplier_key,
        count(*) as row_count
    from join_lab.bridge_product_supplier
    where preferred_supplier is True
    group by supplier_key;

    select *
    from join_lab.dim_supplier;

select
    dc.customer_segment,
    dp.category,
    dw.warehouse_city,
    ds.supplier_name,
    count(distinct foi.order_id) as distinct_orders,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join join_lab.dim_customer as dc
on dc.customer_key = foi.customer_key
join join_lab.dim_product as dp
on dp.product_key = foi.product_key
join join_lab.dim_warehouse as dw
on dw.warehouse_key = foi.warehouse_key
join join_lab.bridge_product_supplier as bps
on bps.product_key = dp.product_key
join join_lab.dim_supplier as ds
on ds.supplier_key = bps.supplier_key
group by dc.customer_segment,
        dp.category,
        dw.warehouse_city,
        ds.supplier_name
order by customer_segment
    ;



--Drill 68: Preferred supplier version
select
    dc.customer_segment,
    dp.category,
    dw.warehouse_city,
    ds.supplier_name,
    count(distinct foi.order_id) as distinct_orders,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join join_lab.dim_customer as dc
on dc.customer_key = foi.customer_key
join join_lab.dim_product as dp
on dp.product_key = foi.product_key
join join_lab.dim_warehouse as dw
on dw.warehouse_key = foi.warehouse_key
join join_lab.bridge_product_supplier as bps
on bps.product_key = dp.product_key
and bps.preferred_supplier is True
join join_lab.dim_supplier as ds
on ds.supplier_key = bps.supplier_key
group by dc.customer_segment,
        dp.category,
        dw.warehouse_city,
        ds.supplier_name
order by customer_segment
-- Reconciliation is restored as the grain in bridge_product_supplier table is
--  restored to one row = 1 product hence the join does not fanout



--Drill 69: Identify the exact fanout path
-- in drill 67, when linking using product_key, the fact_order_item and
--  the bridge_product_supplier has many:many relationship where multiple
--  products can link to multiple order_items in fact table.
-- Thus the tables fans out when joined with the bridge_product_supplier table.

    --fact_order_item
    --many
    --  ↕
    --many
    --bridge_product_supplier
    --many
    --  ↓
    --one
    --dim_supplier
