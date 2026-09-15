--Drill 47: Orders by year
SELECT
    extract(year from order_date) as order_year,
    count(*) as order_count,
    sum(units_ordered) as total_units
FROM training.supply_chain_orders
GROUP BY extract(year from order_date)
ORDER BY extract(year from order_date);
--Output grain: one row per order date year


--Drill 48: Orders by month
SELECT
    date_trunc('month', order_date) as order_month,
    count(*) as order_count,
    sum(units_ordered) as total_units
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date)
ORDER BY date_trunc('month', order_date);
--Comment: It returns order_count & total_units extracted from order date,
--returning order_date monthly values for every month
--Output grain: one row per order date month


--Drill 49: monthly gross order value
SELECT
    date_trunc('month', order_date) as order_month,
    count(*) as order_count,
    sum(units_ordered) as total_units,
    round(sum(units_ordered * unit_price), 2) as gross_order_value
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date)
ORDER BY date_trunc('month', order_date);
--Output grain: one row per order date month


--Drill 50: monthly net sales
with sales as(
SELECT
    to_char(order_date, 'fmmonth') as order_month,
    sum(units_ordered * unit_price) as gross_order_value,
    sum((units_ordered * unit_price) * discount_rate)as discount_value,
    sum(units_ordered * unit_cost) as unit_costs,
    sum(shipping_cost) as shipping_costs
FROM training.supply_chain_orders
GROUP BY to_char(order_date, 'fmmonth')
)
SELECT
    order_month,
    gross_order_value,
    round(discount_value, 2) as discount_value,
    round(gross_order_value - (
        unit_costs + shipping_costs + discount_value), 2) as net_sales
FROM sales;
--Output grain: one row per order date month


--Drill 51: monthly return rate
    --investigative query
    SELECT DISTINCT
        returned
    FROM training.supply_chain_orders;
WITH monthly_returns as (
SELECT
    to_char(order_date, 'fmmonth') as order_month,
    count(*) as order_count,
    count(*) FILTER (WHERE returned is TRUE) as returned_orders
FROM training.supply_chain_orders
GROUP BY to_char(order_date, 'fmmonth')
)
SELECT
    order_month,
    order_count,
    returned_orders,
    round((returned_orders::NUMERIC / NULLIF(
        order_count, 0)) * 100, 2) as return_rate_pct
FROM monthly_returns
ORDER BY order_count DESC;
--Output grain: one row per order date month


--Drill 52: monthly late delivery rate
    --investigative query
    SELECT DISTINCT
        shipment_status
    FROM training.supply_chain_orders;
    SELECT *
    FROM training.supply_chain_orders
    LIMIT 20;

WITH orders_deliveries as (
SELECT
    date_trunc('month', order_date) as order_month,
    count(*) as orders_count,
    count(*) filter (
        where actual_delivery_date is not NULL) as completed_deliveries,
    count(*) filter (
        where actual_delivery_date > promised_delivery_date) as late_deliveries
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date)
)
SELECT
    order_month,
    orders_count,
    completed_deliveries,
    late_deliveries,
    round(late_deliveries::NUMERIC / NULLIF(
        completed_deliveries, 0), 4) as late_deliveries_rate
FROM orders_deliveries
ORDER BY orders_count;
--Output grain: one row per order date month

--Drill 53: monthly profitability
WITH sales as (
SELECT
    date_trunc('month', order_date) as order_month,
    count(*) as order_count,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_order_value,
    sum((units_ordered * unit_price) *
        discount_rate) as discount_value,
    sum(units_ordered * unit_cost) as product_cost,
    sum(shipping_cost) as shipping_cost
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date)
)
SELECT
    order_month,
    order_count,
    total_units,
    gross_order_value,
    round(discount_value, 2) as discount_value,
    round(gross_order_value - discount_value, 2) as net_sales,
    product_cost,
    shipping_cost,
    round((gross_order_value - discount_value) - (
        product_cost + shipping_cost), 2) as net_contribution,
    round(((gross_order_value - discount_value) - (
        product_cost + shipping_cost)) / NULLIF(
            (gross_order_value - discount_value), 0), 4) as net_contribution_rate
FROM sales
ORDER BY order_month;
--Output grain: one row per order date month
