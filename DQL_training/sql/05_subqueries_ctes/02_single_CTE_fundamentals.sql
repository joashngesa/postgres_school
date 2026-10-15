--Drill 1: Order revenue preparation
--Business scenario
--  The finance department wants to understand the total gross sales generated
--by individual order items.
with order_item_revenue as (
    select
        order_item_id,
        order_id,
        product_key,
        units_ordered,
        unit_price,
        (units_ordered * unit_price) as gross_revenue
    from join_lab.fact_order_item
)
select
    count(order_item_id) as order_items_count,
    sum(gross_revenue) as total_gross_revenue,
    round(avg(gross_revenue), 2) as average_gross_revenue
from order_item_revenue;
--Grain of the CTE is one row per order_item_id



--Drill 2: High value order items
--Business scenario:
--Management wants to identify order items generating unusually high sales.
with order_items_value as (
    select
        order_item_id,
        order_id,
        product_key,
        units_ordered,
        unit_price,
        (units_ordered * unit_price) as gross_sales
    from join_lab.fact_order_item
)
select
    order_item_id,
    order_id,
    product_key,
    units_ordered,
    unit_price,
    gross_sales
from order_items_value
where gross_sales > 1000
order by gross_sales desc;
--Engineering questions:
--  The CTE design enhances better readability and better format for future
--troubleshooting and better separation of responsibilities.



--Drill 3: Order level revenue
--Business scenario:
--  The finance department wants to report revenue at the order level rather
--than the order-item level.
with order_revenue as (
    select
        order_id,
        count(distinct order_item_id) as order_items_count,
        sum(units_ordered) as total_units,
        sum(units_ordered * unit_price) as gross_order_revenue
    from join_lab.fact_order_item
    group by order_id
)
select
    order_id,
    order_items_count,
    total_units,
    gross_order_revenue
from order_revenue
where gross_order_revenue > 2000;
--Engineering questions
--Source table grain: order_item_id
--CTE grain: order_id
--Group by changes the table grain by grouping all the columns into orders



--Drill 4: Customer purchasing activity
--Business scenario:
--The customer analytics department wants to understand purchasing activity
with customer_purchases as (
    select
        customer_key,
        count(distinct order_id) as orders_count,
        count(order_item_id) as order_item_count,
        sum(units_ordered) as total_units,
        sum(units_ordered * unit_price) as total_gross_revenue
    from join_lab.fact_order_item
    group by customer_key
)
select
    customer_key,
    orders_count,
    order_item_count,
    total_units,
    total_gross_revenue
from customer_purchases
where orders_count > 3
order by total_gross_revenue desc;
--Engineering questions:
--  Count(*) counts all the order_id belonging to that customer including
--repeated orders
--whereas distinct does not count each appearance



--Drill 5: Product revenue classification
--Business scenario:
--The merchandising department wants to classify products according to revenue contribution
with product_revenues as (
    select
        product_key,
        count(distinct order_id) as orders_count,
        sum(units_ordered) as total_units,
        sum(units_ordered * unit_price) as gross_revenue
    from join_lab.fact_order_item
    group by product_key
)
select
    product_key,
    orders_count,
    total_units,
    gross_revenue,
    case
        when gross_revenue >= 50000 then 'High revenue'
        when gross_revenue >= 20000 then 'Medium revenue'
        else 'Low revenue'
    end as revenue_classification
from product_revenues
order by gross_revenue desc;
--Engineering question
--  The classification must occur after product-level aggregation because the business
--rule operates on total revenue at the product grain
