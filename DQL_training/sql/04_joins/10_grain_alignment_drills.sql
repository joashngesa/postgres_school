--Block F: Grain alignment
--Drill 62: Sales per product
    --Investigate product_key uniqueness
    select
        product_key,
        count(*)
    from join_lab.dim_product
    group by product_key
    having count(*) > 1;
select
    dp.product_key,
    count(distinct foi.order_id) as distinct_orders,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join join_lab.dim_product as dp
on dp.product_key = foi.product_key
group by dp.product_key
    ;



--Drill 63: Supplier count per product
    select
    count(*)
    from join_lab.bridge_product_supplier;
    -- Investigate product_key uniqueness
    select
        product_key,
        count(*) as product_count
    from join_lab.bridge_product_supplier
    group by product_key
    having count(*) > 1;
select
    product_key,
    count(supplier_key) as supplier_count
from join_lab.bridge_product_supplier
group by product_key
;



--Drill 64: Safe product performance join
    --Investigate tables
    select
        count(product_name) as product_name_count,
        count(product_key) as product_key_count
    from join_lab.dim_product
    ;
with product_supplier_tbl as (
    select
        product_key,
        count(supplier_key) as supplier_count
    from join_lab.bridge_product_supplier
    group by product_key
),
product_level_sales as (
    select
        foi.product_key,
        dp.product_name,
        count(distinct foi.order_id) as distinct_orders,
        sum(foi.units_ordered) as total_units,
        sum(foi.units_ordered * foi.unit_price) as gross_order_value
    from join_lab.fact_order_item as foi
    join join_lab.dim_product as dp
    on dp.product_key = foi.product_key
    group by foi.product_key,
            dp.product_name
)
select
    pls.product_key,
    pls.product_name,
    pst.supplier_count,
    pls.distinct_orders,
    pls.total_units,
    pls.gross_order_value
from product_supplier_tbl as pst
join product_level_sales as pls
on pls.product_key = pst.product_key
    ;



--Drill 65: Compare safe vs unsafe approach
--Version A:Unsafe
with unsafe_tbl as (
    select
        foi.product_key,
        bps.supplier_key,
        sum(foi.units_ordered * foi.unit_price) as gross_order_value
    from join_lab.fact_order_item as foi
    join join_lab.bridge_product_supplier as bps
    on bps.product_key = foi.product_key
    group by foi.product_key,
            bps.supplier_key
)
select
    count(*) as row_count,
    sum(gross_order_value) as unsafe_total_revenue
from unsafe_tbl
    ;

--Version B : Safe
with product_supplier as (
    select
        product_key,
        count(supplier_key) as supplier_count
    from join_lab.bridge_product_supplier as bps
    group by product_key
),
product_tbl as (
select
    dp.product_key,
    sum(foi.units_ordered) as units_ordered,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join join_lab.dim_product as dp
on dp.product_key = foi.product_key
group by dp.product_key
),
final_tbl as (
select
    ps.product_key,
    ps.supplier_count,
    pt.units_ordered,
    pt.gross_order_value
from product_supplier as ps
join product_tbl as pt
on pt.product_key = ps.product_key
order by ps.product_key
    )
select
    count(*) as row_count,
    sum(gross_order_value) as safe_total_revenue
from final_tbl
    ;
