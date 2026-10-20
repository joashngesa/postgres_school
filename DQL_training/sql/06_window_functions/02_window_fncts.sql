--Block D: Multiple window calculations
--Objective: Calculate several analytical metrics within the same query

--Drill 16: Customer activity profile
--Calculate 3 customer level metrics using window functions
select
    order_item_id,
    customer_key,
    units_ordered,
    sum(units_ordered) over (partition by customer_key) as customer_total_units,
    count(order_item_id) over (partition by customer_key) as customer_item_count,
    round(avg(units_ordered) over (partition by customer_key), 2) as customer_avg_units
from join_lab.fact_order_item
order by order_item_id
    ;


--Drill 17: Product revenue profile
--Calculate total revenue, average item revenue and order_item count for each product
with item_revenue as (
    select
        order_item_id,
        product_key,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
)
select
    order_item_id,
    product_key,
    item_revenue,
    sum(item_revenue) over (partition by product_key) as product_total_revenue,
    round(avg(item_revenue) over (partition by product_key), 2) as product_avg_item_revenue,
    count(order_item_id) over (partition by product_key) as product_item_count
from item_revenue
    ;



--Drill 18: Warehouse performance profile
--Calculate three warehouse level metrics
with warehouse_item_revenue as (
    select
        order_item_id,
        warehouse_key,
        units_ordered,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
)
select
    order_item_id,
    warehouse_key,
    units_ordered,
    item_revenue,
    sum(units_ordered) over (partition by warehouse_key) as warehouse_total_units,
    sum(item_revenue) over (partition by warehouse_key) as warehouse_total_revenue,
    round(avg(item_revenue) over (partition by warehouse_key), 2) as warehouse_avg_item_revenue
from warehouse_item_revenue
    ;
--warehouse_total_units would be best to evaluate sales volume & warehouse_total_revenue
-- & warehouse_avg_item_revenue best used to evaluate gross revenue


--Drill 19: Customer revenue vs global revenue
--Calculate customer_level revenue and global revenue in the same query
select
    order_item_id,
    customer_key,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over (partition by customer_key) as customer_total_revenue,
    sum(units_ordered * unit_price) over () as global_total_revenue
from join_lab.fact_order_item
    ;
--customer_total_revenue gets the total revenue per customer whereas global_total_revenue
--gets the overall total revenue


--Drill 20: Order revenue profile
with order_item_revenue as (
    select
        order_item_id,
        order_id,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
)
select
    order_item_id,
    order_id,
    item_revenue,
    sum(item_revenue) over (partition by order_id) as order_total_revenue,
    round(avg(item_revenue) over (partition by order_id), 2) as order_avg_item_revenue,
    count(order_item_id) over (partition by order_id) as order_item_count,
    sum(item_revenue) over (
        partition by order_id order by order_item_id
    )as running_order_revenue
from order_item_revenue
    ;



--Block E: Window functions vs group by
--Objective:
--Understand when to use ordinary aggregation and when to use window functions

--Drill 21: Customer revenue aggregation
select
    customer_key,
    sum(units_ordered * unit_price) as customer_total_revenue
from join_lab.fact_order_item
group by customer_key
    ;
--Output grain: 1 row per customer_key


--Drill 22: Customer revenue window calculation
select
    order_item_id,
    customer_key,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over (
        partition by customer_key) as customer_total_revenue
from join_lab.fact_order_item
    ;
--Drill 21 returns rows per customer_key whereas drill 22 returns row per order_item even
--though they both calculate customer revenues


--Drill 23: Product revenue comparison
--
with product_revenue as (
    select
        product_key,
        sum(units_ordered * unit_price) as product_revenue
    from join_lab.fact_order_item
    group by product_key
    --Output grain: 1 row per product_key
),
order_item_product_revenue as (
    select
        order_item_id,
        product_key,
        sum(units_ordered * unit_price) over (
            partition by product_key) as item_product_revenue
    from join_lab.fact_order_item
    --Output grain: 1 row per order_item_id
),
product_revenue_row_count as (
    select
        count (*) as row_count
    from product_revenue
)
select
    count(*) as row_count
from order_item_product_revenue
    ;
--The product_revenue CTE is best suited for product_level_summary
--The order_item_product_revenue CTE is appropriate for enriching order_items records



--Drill 24: Warehouse revenue comparison
with ordinary_warehouse_revenue as (
    select
        warehouse_key,
        sum(units_ordered * unit_price) as warehouse_revenue
    from join_lab.fact_order_item
    group by warehouse_key
    --Output grain: 1 row per warehouse_key
),
windows_warehouse_revenue as (
    select
        warehouse_key,
        sum(units_ordered * unit_price) over (partition by warehouse_key) as wh_revenue,
        sum(units_ordered * unit_price) over () as overall_revenue
    from join_lab.fact_order_item
    --Output grain: 1 row per order_item
)
select
    sum(warehouse_revenue) as overall_wh_revenue
from ordinary_warehouse_revenue
    ;



--Drill 25: Customer revenue with customer names
with customer_revenue as (
    select
        foi.order_item_id,
        foi.customer_key,
        dc.customer_name,
        (foi.units_ordered * foi.unit_price) as item_revenue,
        sum(foi.units_ordered * foi.unit_price) over (
            partition by foi.customer_key) as customer_tot_revenue
    from join_lab.fact_order_item as foi
    join join_lab.dim_customer as dc
    on dc.customer_key = foi.customer_key
)
select
    count(*) as row_count
from customer_revenue
--Question: What would happen if dim_customer contained multiple matching rows for the
--same customer_key?
--Answer: This would result to a fanout


