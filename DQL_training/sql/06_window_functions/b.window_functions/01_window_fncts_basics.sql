--LEVEL 1: Window function foundations

--Block A:
--Objective:
--Understand how window functions calculate values across an entire result set while
--preserving individual rows.

--Drill 1: Global order_item count
select
    order_item_id,
    order_id,
    customer_key,
    units_ordered,
    count (order_item_id) over () as total_order_items
from join_lab.fact_order_item
limit 20
    ;
--Comment: using over without partitioning / order by gives back the dataset wide count
--of all order_item_id rows appearing in the table.



--Drill 2: Global units ordered
select
    order_item_id,
    product_key,
    units_ordered,
    sum(units_ordered) over() as global_units_ordered
from join_lab.fact_order_item
limit 20
    ;
    --Comment: using sum with over() returns back the global value of the sum while sum()
    --gives back the sum value of the grouped values that make up the grain of the table



--Drill 3: Global revenue
select
    order_item_id,
    order_id,
    units_ordered,
    unit_price,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over() as global_revenue
from join_lab.fact_order_item
    ;
--Comment: window function gives back the value of each row either by aggregating the entire
--dataset / partitioning the dataset



--Drill 4: Global average order_item revenue
with order_item_revenue as (
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
    round(avg(item_revenue) over(), 2) as avg_item_revenue
from order_item_revenue
    ;
--Comment: It calculates average revenue per order_item as the avg is done from a table where
--the grain is order_item, it would be concidered as order average if the grain was order_id.



--Drill 5: Global revenue comparison
with item_revenue_metrics as (
    select
        order_item_id,
        customer_key,
        (units_ordered * unit_price) as item_revenue,
        avg(units_ordered * unit_price) over () as global_average_revenue
    from join_lab.fact_order_item
)
select
    order_item_id,
    customer_key,
    item_revenue,
    round(global_average_revenue, 2) as global_average_revenue,
    round(item_revenue - global_average_revenue, 2) as difference_from_avg
from item_revenue_metrics
    ;
--Comment: + difference values show that the row order revenue is more than the average revenue
--whereas - difference values show that the row order revenue is less than the average revenue


--Block B: Understanding partition by
--Drill 6: Customer total units
--Calculate the total quantity ordered by each customer
select
    order_item_id,
    customer_key,
    units_ordered,
    sum(units_ordered) over (
        partition by customer_key) as customer_total_units
from join_lab.fact_order_item
order by order_item_id
    ;
--Comment: When 2 rows belong to the same customer, the units_ordered are added



--Drill 7: Customer order_item count
--Calculate how many order_item_id records belong to each customer
select
    order_item_id,
    customer_key,
    order_id,
    count(order_item_id) over(
        partition by customer_key) as customer_item_count
from join_lab.fact_order_item
order by order_item_id
    ;
--Question: Is the result necessarily equivalent to the number of distinct orders placed
--by each customer?
--Answer: No, the customer_item_count sums up the total number of order_items per customer


--Drill 8: Product revenue contribution
--Calculate total gross revenue for each product
select
    order_item_id,
    product_key,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over (
        partition by product_key) as product_total_revenue
from join_lab.fact_order_item
    ;
--Question: Why might several order items display the same product revenue?
--Answer: 1 product can be ordered more than once thus having more than one order_item



--Drill 9: Warehouse units ordered
--Calculate total units ordered through each warehouse
select
    order_item_id,
    warehouse_key,
    units_ordered,
    sum(units_ordered) over (partition by warehouse_key) as warehouse_total_units
from join_lab.fact_order_item
    ;
--Business interpretation: This can be used to analyze and deduct information about
--units stored in each warehouse



--Drill 10: Order level revenue
--Calculate the total gross revenue associated with each order
select
    order_item_id,
    order_id,
    product_key,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over (partition by order_id) as order_total_revenue
from join_lab.fact_order_item
order by order_id,
        order_item_id
        ;
--Question: If one order contains five order items, how many rows should appear for
--that order?
--Answer: 5. The table maintains order_item_id as the grain thus the order will show
--five times for each order_item


--Block C: Understanding window order by
--Objective: Understand how ordering affects window calculations
--Key PostgreSQL behaviour: When an aggregate window function includes order by  but no explicit
--frame, PostgreSQL generally used default frame extending from the partition beginning through
--the current row's last peer.
--Rows with equal ordering values are peer.

--Drill 11: Global running units
--Calculate a cumulative total of units ordered
select
    order_item_id,
    units_ordered,
    sum(units_ordered) over (order by order_item_id) as running_units
from join_lab.fact_order_item
    ;
--Comment: The running units add up cumulatively as you move down the rows of each order_item


--Drill 12: Customer running units
--Calculate cumulative units ordered separately for each customer
select
    order_item_id,
    customer_key,
    units_ordered,
    sum(units_ordered) over (
        partition by customer_key order by order_item_id) as customer_running_units
from join_lab.fact_order_item
    ;
--Comment: The units_ordered add up and each time the customer changes, the additions start
--a fresh with the proceeding customer_key


--Drill 13: Product running revenue
--Calculate cumulative gross revenue separately for each product
select
    order_item_id,
    product_key,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over (
        partition by product_key order by order_item_id) as product_running_revenue
from join_lab.fact_order_item
    ;



--Drill 14: Warehouse running units
--Calculate cumulative units ordered for each warehouse
select
    order_item_id,
    warehouse_key,
    units_ordered,
    sum(units_ordered) over (
        partition by warehouse_key order by order_item_id) as warehouse_running_units
from join_lab.fact_order_item
    ;
--Question: Does ordering by order_item_id necessarily represent the chronological
--order in which goods were ordered?
--Answer: No. The query follows the chronological order of order_item_id


--Drill 15: Running order revenue
--Calculate cumulative revenue within each order & total revenue for the entire order
select
    order_item_id,
    order_id,
    (units_ordered * unit_price) as item_revenue,
    sum(units_ordered * unit_price) over (
        partition by order_id order by order_item_id) as running_order_revenue,
    sum(units_ordered * unit_price) over (partition by order_id) as order_total_revenue
from join_lab.fact_order_item
    ;
--Cumulative revenue within each order adds up each order item revenue progressively for
--each order whereas order_revenue for the entire order sums up the revenue for each order
