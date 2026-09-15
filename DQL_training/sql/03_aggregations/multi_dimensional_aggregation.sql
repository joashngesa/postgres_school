--Drill 54: Month & sales region
SELECT
    date_trunc('month', order_date) as order_month,
    sales_region,
    count(*) as order_count,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_order_value
    FROM training.supply_chain_orders
    GROUP BY date_trunc('month', order_date),
            sales_region;

--Output grain: one row per order month * sales region


--Drill 55: month & warehouse
SELECT
    date_trunc('month', order_date) as order_month,
    warehouse_city,
    count(*) as order_count,
    count(DISTINCT customer_id) as customer_count,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_order_value
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date),
        warehouse_city;

--Output grain: one row per order month & warehouse_city



--Drill 56: month & region return KPI
SELECT
    date_trunc('month', order_date) as order_month,
    sales_region,
    count(*) as order_count,
    count(*) filter (where returned is true) as returned_orders,
    round(count(*) filter (
        where returned is true)::numeric / NULLIF(
            count(*), 0), 4) as return_rate
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date),
        sales_region;

--Output grain: one row per order month & region



--Drill 57: month & region delivery KPI
WITH deliveries as (
SELECT
    date_trunc('month', order_date) as order_month,
    sales_region,
    count(*) filter (
        where actual_delivery_date is not NULL) as completed_deliveries,
    count(*) filter (
        where actual_delivery_date > promised_delivery_date) as late_deliveries
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date),
        sales_region
)
SELECT
    order_month,
    sales_region,
    completed_deliveries,
    late_deliveries,
    round(late_deliveries::numeric / nullif(
        completed_deliveries, 0), 4) as late_delivery_rate
FROM deliveries;

--Output grain: one row per order month & region



--Drill 58: month & region financial KPI
WITH orders as (
SELECT
    date_trunc('month', order_date) as order_month,
    sales_region,
    sum(units_ordered * unit_price) as gross_order_value,
    sum((units_ordered * unit_price) * discount_rate) as discount_value,
    sum(units_ordered * unit_cost) as product_cost,
    sum(shipping_cost) as shipping_cost,
    sum((units_ordered * unit_price) - (
        units_ordered * unit_price) * discount_rate) as net_sales
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date),
        sales_region
)
SELECT
    order_month,
    sales_region,
    gross_order_value,
    round(discount_value, 2) as discount_value,
    product_cost,
    shipping_cost,
    round(net_sales, 2) as net_sales,
    round(net_sales - (product_cost + shipping_cost), 2) as net_contribution,
    round((net_sales - (product_cost + shipping_cost)) / nullif(
        net_sales, 0), 4) as net_contribution_rate
FROM orders

--Output grain: one row per order month & region



--Drill 59: month * warehouse performance report
WITH warehouse as (
SELECT
    date_trunc('month', order_date) as order_month,
    warehouse_city,
    count(*) as order_count,
    count(DISTINCT customer_id) as customer_count,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_order_value,
    sum((units_ordered * unit_price) * discount_rate) as discount_value,
    sum(shipping_cost) as shipping_cost,
    sum(units_ordered * unit_cost) as product_costs,
    count(*) filter (where returned is true) as returned_orders,
    count(*) filter (
        where actual_delivery_date is not null) as completed_deliveries,
    count(*) filter (
        where actual_delivery_date > promised_delivery_date) as late_deliveries
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date),
        warehouse_city
)
SELECT
    order_month,
    warehouse_city,
    order_count,
    customer_count,
    total_units,
    gross_order_value,
    round(gross_order_value - discount_value, 2) as net_sales,
    round((gross_order_value - discount_value) - (
        shipping_cost + product_costs), 2) as net_contribution,
    returned_orders,
    round(returned_orders::numeric / nullif(
        order_count, 0), 4) as return_rate,
    completed_deliveries,
    late_deliveries,
    round(late_deliveries::numeric / nullif(
        completed_deliveries, 0), 4) as late_delivery_rate
FROM warehouse;

--Output grain: one row per order month & warehouse_city



--Phase 3 report
    --investigative query
    SELECT *
    FROM training.supply_chain_orders
    LIMIT 20;
    SELECT
        count(*) as total_orders,
        count(DISTINCT product_id) as product_count
    FROM training.supply_chain_orders;

with orders as (
SELECT
    date_trunc('month', order_date) as order_month,
    sales_region,
    warehouse_city,
    count(*) as order_count,
    count(DISTINCT customer_id) as customer_count,
    count(DISTINCT supplier_id) as supplier_count,
    count(DISTINCT product_id) as product_count,
    sum(units_ordered) as total_units,
    sum(units_ordered * unit_price) as gross_order_value,
    sum((units_ordered * unit_price) * discount_rate) as discount_value,
    sum(units_ordered * unit_cost) as product_cost,
    sum(shipping_cost) as shipping_cost,
    count(*) filter (where returned is true) as returned_orders,
    count(*) filter (
        where actual_delivery_date is not NULL) as completed_deliveries,

    count(*) filter (
        where actual_delivery_date > promised_delivery_date) as late_deliveries
FROM training.supply_chain_orders
GROUP BY date_trunc('month', order_date),
        sales_region,
        warehouse_city
)
SELECT
    order_month,
    sales_region,
    warehouse_city,
    order_count,
    customer_count,
    supplier_count,
    product_count,
    total_units,
    gross_order_value,
    round(discount_value, 2) as discount_value,
    round(gross_order_value - discount_value, 2) as net_sales,
    product_cost,
    shipping_cost,
    round((gross_order_value - discount_value) - (
        product_cost + shipping_cost), 2) as net_contribution,
    round(((gross_order_value - discount_value) - (
        product_cost + shipping_cost)) / nullif(
            gross_order_value - discount_value, 0
        ), 4) as net_contribution_rate,
    round(gross_order_value / nullif(
        order_count, 0), 2) as average_order_value,
    returned_orders,
    round(returned_orders

    ::numeric / nullif(
        order_count, 0), 4) as return_rate,
    completed_deliveries,
    late_deliveries,
    round(late_deliveries::numeric / nullif(
        completed_deliveries, 0), 4) as late_deliveries_rate
FROM orders;

    --Output grain: one row per order month & region & warehouse_city
