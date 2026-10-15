--Objective:
--Learn how to calculate separate business metrics independently before combining them.

--Drill 6: Revenue & order volume
--Business scenario:
--Finance wants a consolidated summary of revenue and order volume
with revenue_summary as (
    select
        sum(units_ordered * unit_price) as gross_revenue
    from join_lab.fact_order_item
),
order_summary as (
    select
        count(distinct order_id) as total_orders
    from join_lab.fact_order_item
)
select
    rvs.gross_revenue,
    ods.total_orders,
    round(rvs.gross_revenue / nullif(
        ods.total_orders, 0
    ), 2) as average_order_value
from revenue_summary as rvs
cross join order_summary as ods;

--Engineering question:
--When designing both queries make sure that the order grain used is the same



--Drill 7: Customer & product coverage
--Business scenario:
--The commercial department wants a quick overview of business activity
with customer_activity as (
    select
        count(distinct customer_key) as customer_count
    from join_lab.fact_order_item
),
product_activity as (
    select
        count(distinct product_key) as products_count
    from join_lab.fact_order_item
)
select
    cta.customer_count,
    pra.products_count
from customer_activity as cta
cross join product_activity as pra;

--Engineering question:
--What would happen if one CTE unexpectedly returned multiple rows?
--It multiplys the table from the left with the table to the right



--Drill 8: Customer revenue vs overall revenue
--Business Scenario:
--Management wants to know how much revenue each customer contributes to the business.
with customer_revenue as (
    select
        customer_key,
        sum(units_ordered * unit_price) as customer_revenue
    from join_lab.fact_order_item
    group by customer_key
),
company_revenue as (
    select
        sum(units_ordered * unit_price) as company_revenue
    from join_lab.fact_order_item
)
select
    ctr.customer_key,
    ctr.customer_revenue,
    cpr.company_revenue,
    round((ctr.customer_revenue / nullif(
        cpr.company_revenue, 0
    )) * 100, 2) as customer_revenue_contribution_pct
from customer_revenue as ctr
cross join company_revenue as cpr
order by ctr.customer_revenue desc;



--Drill 9: Product performance vs company average
--Business scenario:
--Management wants to identify products generating above-average revenue
with product_revenue as (
    select
        product_key,
        sum(units_ordered * unit_price) as product_revenue
    from join_lab.fact_order_item
    group by product_key
),
average_product_revenue as (
    select
        avg(product_revenue) as avg_product_revenue
    from product_revenue
)
select
    pdr.product_key,
    pdr.product_revenue,
    round(apr.avg_product_revenue, 2) as avg_product_revenue,
    round((
        pdr.product_revenue - apr.avg_product_revenue), 2) as difference_from_average
from product_revenue as pdr
cross join average_product_revenue as apr
where pdr.product_revenue > apr.avg_product_revenue
order by pdr.product_revenue;

--Engineering question:
    --Why would averaging units_ordered * unit_price directly from the fact table
    --answer a different business question?

--this would find the average revenue per order line item



--Drill 10: Customer order frequency
--Business scenario:
--The customer retention team wants to identify customers who purchase more
--frequently than average
with customer_order_counts as (
    select
        customer_key,
        count(distinct order_id) as order_counts
    from join_lab.fact_order_item
    group by customer_key
),
average_order_frequency as (
    select
        avg(order_counts) as avg_order_counts
    from customer_order_counts
)
select
    customer_key,
    order_counts
from customer_order_counts as coc
cross join average_order_frequency as aof
where coc.order_counts > aof.avg_order_counts;

--Engineering question:
--The second CTE is dependent on the first one because the first CTE calculates the order
--counts per customer and the second CTE finds its average.
