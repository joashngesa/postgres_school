--Drill 30: Engineering challenge
--Business scenario
--Develop an analytical dataset for the commercial operations team. The team wants to
--examine order_item performance while simultaneously understanding customer, product,
--warehouse and overall revenue

with fact_table as (
    select
        order_item_id,
        order_id,
        customer_key,
        product_key,
        warehouse_key,
        unit_price,
        units_ordered,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
),
joined_tbl as (
    select
        ftl.order_item_id,
        ftl.order_id,
        ftl.customer_key,
        dc.customer_name,
        ftl.product_key,
        dp.product_name,
        ftl.warehouse_key,
        dw.warehouse_city,
        ftl.units_ordered,
        ftl.item_revenue
    from fact_table as ftl
    join join_lab.dim_customer as dc
    on dc.customer_key = ftl.customer_key
    join join_lab.dim_product as dp
    on dp.product_key = ftl.product_key
    join join_lab.dim_warehouse as dw
    on dw.warehouse_key = ftl.warehouse_key
),
aggregated_table as (
    select
        order_item_id,
        order_id,
        customer_name,
        product_name,
        warehouse_city,
        units_ordered,
        item_revenue,
        sum(item_revenue) over (partition by customer_key) as customer_tot_revenue,
        sum(item_revenue) over (partition by product_key) as product_tot_revenue,
        sum(item_revenue) over (partition by warehouse_key) as warehouse_tot_revenue,
        sum(item_revenue) over () as global_tot_revenue,
        sum(item_revenue) over (
            partition by customer_key order by order_item_id) as customer_running_revenue
    from joined_tbl
),
contribution_percentage as (
    select
        order_item_id,
        order_id,
        customer_name,
        product_name,
        warehouse_city,
        units_ordered,
        item_revenue,
        customer_tot_revenue,
        product_tot_revenue,
        warehouse_tot_revenue,
        global_tot_revenue,
        customer_running_revenue,
        (item_revenue / nullif(
            customer_tot_revenue, 0)) * 100 as item_customer_contribution_pct
    from aggregated_table
),
fact_validation_tbl as (
    select
        count(*) as row_count,
        sum(item_revenue) as total_gross_revenue
    from fact_table
),
analytical_tbl_validation as (
    select
        count(*) as row_count,
        sum(item_revenue) as total_gross_revenue
    from contribution_percentage
)
--The difference of row_count & gross_revenue in the fact & analytical table comes by
--when you join the tables by using inner join which leaves out customers without a match.
--This reduces the row_count number consequently the total gross revenue
select
    order_item_id,
    order_id,
    customer_name,
    product_name,
    warehouse_city,
    units_ordered,
    item_revenue,
    customer_tot_revenue,
    product_tot_revenue,
    warehouse_tot_revenue,
    global_tot_revenue,
    customer_running_revenue,
    round(item_customer_contribution_pct, 2) as item_customer_contribution_pct
from contribution_percentage
    ;
--1. Grian of the final analytical table?
--   order_item_id
--2. Why does customer_total_revenue appear repeatedly?
--   The table grain is order_item_id, each customer has more than one order_item_id. The
--   sum of each customer revenues will read the same figure across the table thus
--   appearing repeatedly.
--3. Why should you not sum the repeated customer_total_revenue values across all
--   order-item rows to calculate global revenue?
--   This will result to erroneous revenue figures due to revenue repetition
--4. What would happen if the product dimension contained duplicate product_key values?
--   It would result to a fanout in the joined table.
--5. Why is PARTITION BY customer_key different from GROUP BY customer_key?
--   partition by does not break down the row values grain, it aggregates the row in relation
--   to other rows whereas group changes the grain to the grouped values
--6. Does ordering by order_item_id necessarily produce a chronological revenue analysis?
--   It only changes the appearance of the final table and the ordering of the rows.
