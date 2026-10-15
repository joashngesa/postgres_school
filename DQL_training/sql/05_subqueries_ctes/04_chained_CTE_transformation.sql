--OBJECTIVE:
--Develop the ability to construct multi-stage transformations

--Drill 11: Three stage customer revenue pipeline
--Business scenario:
--The customer analytics team wants to classify customers based on their purchasing
--contribution

--I changed the metrics you provided for segments to allow application of all the segments

with order_item_values as (
    select
        order_item_id,
        order_id,
        customer_key,
        units_ordered,
        unit_price,
        (units_ordered * unit_price) as order_item_revenue
    from join_lab.fact_order_item
),
customer_revenues as (
    select
        customer_key,
        count(distinct order_id) as total_orders,
        sum(units_ordered) as total_units,
        sum(order_item_revenue) as customer_revenue
    from order_item_values
    group by customer_key
),
customer_segment as (
    select
        customer_key,
        total_orders,
        total_units,
        customer_revenue,
        case
            when customer_revenue >= 15000 then 'Platinum'
            when customer_revenue >= 12000 then 'Gold'
            when customer_revenue >= 8000 then 'Silver'
            else 'Bronze'
        end as segment
    from customer_revenues
    order by customer_revenue desc
)
select
    customer_key,
    total_orders,
    total_units,
    customer_revenue,
    segment
from customer_segment
;

--Order_item_values grain: 1 row per order_item_id
--customer_revenues grain: 1 row per customer_key
--customer_segment grain: 1 row per customer_key

--the grain changes in the customer_revenues after grouping the table by customer_key

--The segmentation rule operates on total customer revenue, so customer revenue must
--first exist at the customer grain before the rule can be applied.



--Drill 12: Product revenue ranking
--Business scenario:
--The merchandising department wants to identify the highest-performing products
with order_item_values as (
    select
        order_item_id,
        product_key,
        units_ordered,
        unit_price,
        (units_ordered * unit_price) as order_item_revenue
    from join_lab.fact_order_item
),
product_revenues as (
    select
        product_key,
        sum(units_ordered) as total_units,
        sum(order_item_revenue) as revenue
    from order_item_values
    group by product_key
),
ranked_products as (
select
    product_key,
    total_units,
    revenue,
    dense_rank() over (order by revenue desc) as order_ranking
from product_revenues
)
select
    product_key,
    total_units,
    revenue,
    order_ranking
from ranked_products
where order_ranking <= 5
;

--Engineering challenge:
--ROW_NUMBER → unique numbers

--RANK       → ties + gaps

--DENSE_RANK → ties + no gaps



--Drill 13: Customer average order value
--Business scenario:
--Finance wants to calculate average order value of each customer
with order_item_values as (
    select
        order_item_id,
        order_id,
        customer_key,
        units_ordered,
        unit_price,
        (units_ordered * unit_price) as order_item_revenue
    from join_lab.fact_order_item
),
customer_orders as (
    select
        order_id,
        customer_key,
        sum(units_ordered) as total_units,
        sum(order_item_revenue) as revenue
    from order_item_values
    group by order_id,
            customer_key
),
customer_aov as (
select
    customer_key,
    count(distinct order_id) as order_count,
    sum(revenue) as customer_revenue,
    avg(revenue) as average_order
from customer_orders
group by customer_key
)
select
    customer_key,
    order_count,
    customer_revenue,
    round(average_order, 2) as average_order
from customer_aov
where average_order > 1500
;

--Why must we aggregate revenue at the customer-order grain before
--calculating customer average order value?
--when calculating the customer average, we need the total revenue per customer divided
--by the total orders distinct orders made by the customer, therefore we need the aggregated
--revenue per customer to calculate the customer average



--Drill 14: Revenue concentration analysis
--Business scenario:
--Managment wants to understand whether the business depends heavily on small no. of customers

with order_item_revenue as (
    select
        order_item_id,
        customer_key,
        units_ordered,
        (units_ordered * unit_price) as items_revenue
    from join_lab.fact_order_item
),
customer_revenue as (
    select
        customer_key,
        sum(items_revenue) as revenue
    from order_item_revenue
    group by customer_key
),
ranked_customers as (
    select
        customer_key,
        revenue,
        row_number() over (order by revenue desc) as revenue_ranking,
        sum(revenue) over() as total_company_revenue,
        sum(revenue) over(
            order by revenue desc rows between unbounded preceding
            and current row
        ) as running_revenue_total
    from customer_revenue
),
revenue_contribution as (
    select
        customer_key,
        revenue,
        revenue_ranking,
        total_company_revenue,
        round((revenue / nullif(
            total_company_revenue, 0
        )) * 100, 2) as customer_pct_contribution,
        round((running_revenue_total / nullif(
            total_company_revenue, 0
        )) * 100, 2) as cumulative_revenue_contribution_pct
    from ranked_customers
)
select
    customer_key,
    revenue,
    revenue_ranking,
    total_company_revenue,
    customer_pct_contribution,
    cumulative_revenue_contribution_pct
from revenue_contribution

--Engineering question:
--What is the difference between individual revenue contribution and cumulative
--revenue contribution?
--individual revenue refers to percentage each customer contributes of the total revenue
--cumulative refers to what percent of revenue is covered by each customer, egs, at 80%,
--all records under this would be interpreted us all the customers bring 80 % of all revenues



--Drill 15: Customer purchase frequency classification

--I changed the order_count classification to fit the data in the table

--Business scenario:
--The customer retention team wants to classify customers by purchasing frequency

with customer_orders as (
    select
        order_id,
        customer_key
    from join_lab.fact_order_item
),
customer_frequency as (
    select
        customer_key,
        count(distinct order_id) as order_count
    from customer_orders
    group by customer_key
),
frequency_classification as (
    select
        customer_key,
        order_count,
        case
            when order_count >= 4 then 'Very frequent'
            when order_count >= 3 then 'Frequent'
            when order_count >= 2 then 'Occasional'
            else 'One-time'
        end as frequency_segment
    from customer_frequency
),
segment_summary as (
select
    frequency_segment,
    count(distinct customer_key) as customer_count,
    sum(order_count) as order_count,
    avg(order_count) as avg_order_per_customer
from frequency_classification
group by frequency_segment
)
select
    frequency_segment,
    customer_count,
    order_count,
    round(avg_order_per_customer, 2)
from segment_summary

--Engineering challenge
--customer_orders: 1 row per order_item_id
--customer_frequency: 1 row per customer_key , was changed by grouping the table to customer_key
--frequency_classification: 1 row per per customer_key
--segment_summary: 1 row per frequency_segment
