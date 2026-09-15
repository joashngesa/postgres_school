--Drill 23: Basic percentages
WITH totals as (
SELECT
    COUNT(order_id) as total_orders,
    COUNT(*) FILTER(WHERE returned is TRUE) as returned_orders
FROM training.supply_chain_orders
)
SELECT
    total_orders,
    returned_orders,
    ROUND((returned_orders::NUMERIC / NULLIF(total_orders, 0)) * 100, 2) as return_rate_pct
FROM totals;


--Drill 24: Cancellation rate
    --investigative query
    SELECT DISTINCT
        shipment_status
    FROM training.supply_chain_orders;
    --main query
WITH cancelled_orders as(
SELECT
    COUNT(order_id) as total_orders,
    COUNT(*) FILTER(WHERE shipment_status = 'Cancelled') as cancelled_orders
FROM training.supply_chain_orders
)
SELECT
    total_orders,
    cancelled_orders,
    ROUND((cancelled_orders:: NUMERIC / NULLIF(total_orders, 0)) * 100, 2)
FROM cancelled_orders;


--Drill 25: delivery completion rates
WITH deliveries as (
SELECT
    COUNT(order_id) as total_orders,
    COUNT(*) FILTER(WHERE actual_delivery_date is not NULL) as completed_deliveries
FROM training.supply_chain_orders
)
SELECT
    total_orders,
    completed_deliveries,
    ROUND((completed_deliveries:: NUMERIC / NULLIF(
        total_orders, 0)) * 100, 2) as completion_rate_pct
FROM deliveries;


--Drill 26: late delivery rate
WITH late_deliveries as (
SELECT
    COUNT(*) FILTER(WHERE
        actual_delivery_date > promised_delivery_date) as late_deliveries,
    COUNT(*) FILTER(WHERE actual_delivery_date is not NULL) as total_deliveries
FROM training.supply_chain_orders
)
SELECT
    late_deliveries,
    total_deliveries,
    ROUND((late_deliveries::NUMERIC / NULLIF(
        total_deliveries, 0)) * 100, 2) as late_deliveries_rate_pct
FROM late_deliveries;
--Comment: using total_orders as the denominator is avoided beacause not all orders
--         were delivered, it is more accurate to use total_deliveries


--Drill 27: denominator experimenting
--Rate A(experiment)
SELECT
    COUNT(*) FILTER(WHERE
        actual_delivery_date > promised_delivery_date) as late_deliveries,
    COUNT(order_id) as total_orders,
    round(COUNT(*) FILTER(WHERE
        actual_delivery_date > promised_delivery_date)::NUMERIC / NULLIF(
            COUNT(order_id), 0
        ),4) as late_deliveries_rate
FROM training.supply_chain_orders;

--Rate B
WITH deliveries as (
SELECT
    COUNT(*) FILTER(
        WHERE actual_delivery_date > promised_delivery_date) as late_deliveries,
    COUNT(order_id) as total_orders,
    COUNT(*) FILTER (WHERE actual_delivery_date is not null) as completed_orders
FROM training.supply_chain_orders
)
SELECT
    late_deliveries,
    total_orders,
    completed_orders,
    ROUND((late_deliveries::NUMERIC / NULLIF(
        total_orders, 0)) * 100, 2) as late_rate_all_orders_pct,
    round((late_deliveries::NUMERIC / NULLIF(
        completed_orders, 0)) * 100, 2) as late_rate_completed_orders_pct
FROM deliveries;
--Comment: using completed_orders is more accurate as it conciders all orders that were
--         delivered as opposed to all_orders that entails orders that were not delivered.
--         This is important because late deliveries should use denominator that compares
--         total deliveries.



--Drill 28: warehouse return rate
SELECT
    warehouse_city,
    COUNT(*) as total_orders,
    COUNT(*) FILTER(WHERE returned is TRUE) as returned_orders,
    ROUND((COUNT(*) FILTER(WHERE returned is TRUE)::NUMERIC / NULLIF(
        COUNT(*), 0)) * 100, 2) as return_rate_pct
FROM training.supply_chain_orders
GROUP BY warehouse_city
ORDER BY ROUND((COUNT(*) FILTER(WHERE returned is TRUE)::NUMERIC / NULLIF(
        COUNT(*), 0)) * 100, 2) DESC;




--Drill 29: warehouse late delivery rate
with warehouse as (
SELECT
    warehouse_city,
    COUNT(*) FILTER(WHERE actual_delivery_date is not NULL) as completed_orders,
    COUNT(*) FILTER(
        WHERE actual_delivery_date > promised_delivery_date) as late_orders
FROM training.supply_chain_orders
GROUP BY warehouse_city
)
SELECT
    warehouse_city,
    completed_orders,
    late_orders,
    ROUND((late_orders::NUMERIC / NULLIF(
        completed_orders, 0)) * 100, 2) as late_delivery_rate_pct
FROM warehouse
ORDER BY late_delivery_rate_pct DESC;



--Drill 30: regional KPI comparison
WITH sales_region as (
SELECT
    sales_region,
    COUNT(order_id) as order_count,
    COUNT(distinct customer_id) as customer_count,
    COUNT(*) FILTER(WHERE returned is TRUE) as returned_order_count,
    COUNT(*) FILTER(WHERE actual_delivery_date is not NULL) as completed_delivery_count,
    COUNT(*) FILTER(
        WHERE actual_delivery_date > promised_delivery_date) as late_delivery_count
FROM training.supply_chain_orders
GROUP BY sales_region
)
SELECT
    sales_region,
    order_count,
    customer_count,
    returned_order_count,
    ROUND(returned_order_count::NUMERIC / NULLIF(
        order_count, 0), 4) as return_rate,
    completed_delivery_count,
    late_delivery_count,
    round(late_delivery_count::NUMERIC / NULLIF(
        completed_delivery_count, 0), 4) as late_delivery_rate
FROM sales_region;

--Bonus: check east data
SELECT
    sales_region,
    COUNT(*) FILTER (
        WHERE actual_delivery_date IS NOT NULL
    ) AS completed_deliveries,
    COUNT(*) FILTER (
        WHERE actual_delivery_date <= promised_delivery_date
    ) AS on_time_deliveries,
    COUNT(*) FILTER (
        WHERE actual_delivery_date > promised_delivery_date
    ) AS late_deliveries
FROM training.supply_chain_orders
GROUP BY sales_region
ORDER BY sales_region;
