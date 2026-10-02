--Block H: iNVESTIGATION MODE
--Drill 70: Procurement supplier exposure
--Business request:
-- Procurement wants to know which products rely on only one supplier and
--  how much much sales value those products represent

with one_supplier_tbl as (
    select
        product_key,
        count(supplier_key) as supplier_count
    from join_lab.bridge_product_supplier
    group by product_key
    having count(supplier_key) = 1
),
product_tbl as (
select
    foi.product_key,
    dp.product_name,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join join_lab.dim_product as dp
on dp.product_key = foi.product_key
group by foi.product_key,
        dp.product_name
)
select
    ost.product_key,
    pt.product_name,
    ost.supplier_count,
    pt.gross_order_value
from one_supplier_tbl as ost
join product_tbl as pt
on pt.product_key = ost.product_key



--Drill 71: Multi-supplier products
--Business request:
-- Identify products with more than one supplier and summarize their sales performance

with supp_count as (
    select
        bps.product_key,
        count(bps.supplier_key) as supplier_count
    from join_lab.bridge_product_supplier as bps
    join join_lab.dim_product as dp
    on dp.product_key = bps.product_key
    group by bps.product_key,
            dp.product_name,
            dp.category
    having count(bps.supplier_key) > 1
),
product_tbl as (
    select
        foi.product_key,
        dp.product_name,
        dp.category,
        count(distinct foi.order_id) as distinct_orders,
        sum(foi.units_ordered) as total_units,
        sum(foi.units_ordered * foi.unit_price) as gross_order_value
    from join_lab.fact_order_item as foi
    join join_lab.dim_product as dp
    on dp.product_key = foi.product_key
    group by foi.product_key,
            dp.product_name,
            dp.category
)
select
    pt.product_key,
    pt.product_name,
    pt.category,
    sc.supplier_count,
    pt.distinct_orders,
    pt.total_units,
    pt.gross_order_value
from product_tbl as pt
join supp_count as sc
on sc.product_key = pt.product_key
order by gross_order_value desc



--Drill 72: Supplier portfolio
--Business request
-- Procurement wants every supplier and the number of products associated with them
--  preserve suppliers even if they have 0 products

select
    bps.supplier_key,
    ds.supplier_name,
    count(bps.product_key) as product_count,
    count(*) filter (where bps.preferred_supplier is True) as preferred_product_count
from join_lab.dim_supplier as ds
left join join_lab.bridge_product_supplier as bps
on ds.supplier_key = bps.supplier_key
group by bps.supplier_key,
        ds.supplier_name



--Drill 73: Suppliers with no products
select
    ds.supplier_key,
    ds.supplier_name,
    count(bps.product_key) as product_count
from join_lab.dim_supplier as ds
left join join_lab.bridge_product_supplier as bps
on ds.supplier_key = bps.supplier_key
group by ds.supplier_key,
        ds.supplier_name
having count(bps.product_key) = 0
    ;



--Drill 74: Products with no supplier relationship
select
    dp.product_key,
    dp.product_name,
    count(bps.supplier_key) as supplier_count
from join_lab.dim_product as dp
left join join_lab.bridge_product_supplier as bps
on bps.product_key = dp.product_key
group by dp.product_key,
        dp.product_name
having count(bps.supplier_key) = 0
    ;



--Drill 75: Supplier coverage audit
-- The classification should belong to the product
with product_supplier_count as (
    select
        dp.product_key,
        count(bps.product_key) as product_count,
        count(bps.supplier_key) as supplier_count
    from join_lab.dim_product as dp
    left join join_lab.bridge_product_supplier as bps
    on bps.product_key = dp.product_key
    group by dp.product_key
)
select
    case
        when supplier_count = 0 then 'No supplier'
        when supplier_count = 1 then 'Single supplier'
        when supplier_count > 1 then 'Multi supplier'
    end as supplier_status,
    count(product_count) as product_count
from product_supplier_count
group by case
        when supplier_count = 0 then 'No supplier'
        when supplier_count = 1 then 'Single supplier'
        when supplier_count > 1 then 'Multi supplier'
    end
;
