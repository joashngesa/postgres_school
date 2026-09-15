--Drill 39: Average gross order value: Method A
SELECT
    ROUND(AVG(units_ordered * unit_price), 2) as average_order_value
FROM training.supply_chain_orders;


--Drill 40: Average gross order value:Method B
--Comment: Both averages will get the same results because the grain of the table is order_id,
--         in case the grain changes, AVG will be finding the average of the table grain(order_item_id)
--         , the latter will work if we use count(distinct order_id) as the denominator.
--         AVG skips the null values whereas count(*) counts all values including null values.
SELECT
    ROUND(AVG(units_ordered * unit_price), 2) as aov_avg_method,
    SUM(units_ordered * unit_price) as gross_order_value,
    count(*) as order_count,
    round(SUM(units_ordered * unit_price) / NULLIF(
        count(*), 0), 4) as aov_sum_div_count_method
FROM training.supply_chain_orders;



--Drill 41: AOV by customer segment
SELECT
    customer_segment,
    COUNT(*) as order_count,
    round(sum(units_ordered * unit_price), 2) as gross_order_value,
    round(avg(units_ordered * unit_price), 2) as average_order_value
FROM training.supply_chain_orders
GROUP BY customer_segment
ORDER BY round(avg(units_ordered * unit_price), 2) DESC;



--Drill 42: customer_productivity
with customer_metrics as (
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id) as customer_count,
    COUNT(*) as order_count,
    sum(units_ordered * unit_price) as gross_order_value
FROM training.supply_chain_orders
GROUP BY customer_segment
)
SELECT
    customer_segment,
    customer_count,
    order_count,
    gross_order_value,
    ROUND(order_count::NUMERIC / NULLIF(
        customer_count, 0), 2) as orders_per_customer,
    ROUND(gross_order_value / NULLIF(
        customer_count, 0), 2) as revenue_per_customer
    FROM customer_metrics;


--Drill 43: Simple average price
SELECT
    ROUND(AVG(unit_price), 2) as average_unit_price
FROM training.supply_chain_orders;



--Drill 44: weighted average selling price
SELECT
    round(AVG(unit_price), 2) as simple_average_unit_price,
    round(sum(units_ordered * unit_price) / nullif(
        sum(units_ordered), 0), 2) as weighted_average_unit_price
FROM training.supply_chain_orders;
    --investigate query
    SELECT
        MIN(unit_price) as lowest_unit_price,
        max(unit_price) as highest_unit_price,
        min(units_ordered) as minimum_units_ordered,
        max(units_ordered) as maximum_units_ordered,
        round(avg(units_ordered), 2) as simple_average_units_ordered,
        round(sum(units_ordered::NUMERIC * (unit_price * units_ordered)) / nullif(
            sum(unit_price * units_ordered), 0), 2) as weighted_average_units_ordered
    FROM training.supply_chain_orders;



--Drill 45: weighted average cost
SELECT
    ROUND(AVG(unit_cost), 2) as average_cost,
    round(sum(units_ordered * unit_cost) / NULLIF(
        sum(units_ordered), 0), 2) as weighted_average_unit_cost
FROM training.supply_chain_orders;
    --investigate query
    SELECT
        min(unit_cost) as lowest_unit_cost,
        max(unit_cost) as highest_unit_cost
    FROM training.supply_chain_orders;


--Drill 46: Product_category weighted analysis
SELECT
    product_category,
    count(*) as order_count,
    sum(units_ordered) as total_units,
    round(avg(unit_price), 2) as simple_avg_unit_price,
    round(sum(units_ordered * unit_price) / NULLIF(
        sum(units_ordered), 0), 2) as weighted_avg_unit_price,
    round(avg(unit_cost), 2) as simple_avg_unit_cost,
    round(sum(units_ordered * unit_cost) / NULLIF(
        sum(units_ordered), 0), 2) as weighted_avg_unit_cost
FROM training.supply_chain_orders
GROUP BY product_category
ORDER BY sum(units_ordered) DESC;



