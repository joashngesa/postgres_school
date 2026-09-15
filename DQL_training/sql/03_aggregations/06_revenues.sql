--Drill 31: Gross order value
    --investigate query
    SELECT DISTINCT
        units_ordered
    FROM training.supply_chain_orders;

--main query
SELECT
    COUNT(*) as total_orders,
    sum(units_ordered) as total_units,
    round(sum(units_ordered * unit_price), 2) as gross_order_value
FROM training.supply_chain_orders;


--Drill 32: Product cost
SELECT
    SUM(units_ordered) as total_units,
    round(SUM(units_ordered * unit_cost), 2) as total_product_cost
FROM training.supply_chain_orders;


--Drill 33: Gross product margin
WITH base_metrics as (
SELECT
    SUM(units_ordered * unit_price) as gross_order_value,
    SUM(units_ordered * unit_cost) as gross_product_cost
FROM training.supply_chain_orders
)
SELECT
    gross_order_value,
    gross_product_cost,
    gross_order_value - gross_product_cost as gross_product_margin
FROM base_metrics;



--Drill 34: Gross margin rate
WITH base_metrics as (
SELECT
    SUM(units_ordered * unit_price) as gross_order_value,
    SUM(units_ordered * unit_cost) as gross_product_cost,
    SUM(units_ordered * unit_price) - SUM(units_ordered * unit_cost) as gross_product_margin
FROM training.supply_chain_orders
)
SELECT
    ROUND(gross_product_margin / NULLIF(
        gross_order_value, 0), 1) as gross_margin_rate
FROM base_metrics;



--Drill 35: Discount_value
    --investigative query
    SELECT
        units_ordered * unit_price as gross_value,
        discount_rate,
        round((units_ordered * unit_price) * discount_rate, 2) as dicount_value
    FROM training.supply_chain_orders
    LIMIT 20;
SELECT
    SUM(units_ordered * unit_price) as gross_order_value,
    round(SUM((units_ordered * unit_price) * discount_rate),2) as discount_value
FROM training.supply_chain_orders;



--Drill 36: Net sales
SELECT
    sum(units_ordered * unit_price) as gross_order_value,
    round(sum((units_ordered * unit_price) * discount_rate), 2) as discount_value,
    round(sum(units_ordered * unit_price) - sum(
        (units_ordered * unit_price) * discount_rate), 2) as net_sales
FROM training.supply_chain_orders;



--Drill 37: shipping adjusted contribution
WITH base_metrics as (
SELECT
    SUM(units_ordered * unit_price) as gross_product_value,
    SUM(units_ordered * unit_cost) as gross_product_cost,
    SUM(shipping_cost) as total_shipping_cost,
    SUM(round((units_ordered * unit_price) * discount_rate, 2)) as total_discount_value
FROM training.supply_chain_orders
)
SELECT
    gross_product_value - total_discount_value as net_sales,
    gross_product_cost,
    total_shipping_cost,
    (gross_product_value - total_discount_value
    ) - gross_product_cost - total_shipping_cost as net_contribution
FROM base_metrics;


--Drill 38: Regional profitability
WITH region_metrics as (
SELECT
    sales_region,
    COUNT(order_id) as order_count,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_order_value,
    round(sum((units_ordered * unit_price) * discount_rate), 2) as discount_value,
    round(sum((units_ordered * unit_price) - ((
        units_ordered * unit_price) * discount_rate)), 2) as net_sales,
    round(sum(units_ordered * unit_cost), 2) as product_cost,
    sum(shipping_cost) as shipping_cost
FROM training.supply_chain_orders
GROUP BY sales_region
),
region_derived_metrics as (
SELECT
    sales_region,
    order_count,
    total_units,
    gross_order_value,
    discount_value,
    net_sales,
    product_cost,
    shipping_cost,
    net_sales - product_cost - shipping_cost as net_contribution
FROM region_metrics
)
SELECT
    sales_region,
    order_count,
    total_units,
    gross_order_value,
    discount_value,
    net_sales,
    product_cost,
    shipping_cost,
    net_contribution,
    ROUND(net_contribution / NULLIF(
        net_sales, 0), 2) as net_contribution_rate
FROM region_derived_metrics
ORDER BY net_contribution DESC;
