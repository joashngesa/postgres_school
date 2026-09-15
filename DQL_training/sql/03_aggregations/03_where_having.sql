--shipment_status
SELECT DISTINCT
    shipment_status
FROM training.supply_chain_orders;

--Drill 13
SELECT
    customer_segment,
    COUNT(customer_segment) as customer_segment_count
FROM training.supply_chain_orders
WHERE shipment_status = 'Cancelled'
GROUP BY customer_segment;


--Drill 14
SELECT
    customer_segment,
    COUNT(customer_segment) as customer_segment_count
FROM training.supply_chain_orders
WHERE shipment_status = 'Cancelled'
GROUP BY customer_segment
HAVING COUNT(customer_segment) > 1000;


--Drill 15
SELECT
    warehouse_city,
    SUM(units_ordered * unit_price) as gross_sales
FROM training.supply_chain_orders
WHERE shipment_status = 'Cancelled' or shipment_status = 'Delayed'
GROUP BY warehouse_city
HAVING SUM(units_ordered * unit_price) > 100000
ORDER BY SUM(units_ordered * unit_price) DESC;


--Drill 16
--Comment: we should not use aggregated condition in WHERE, instead we should use HAVING
SELECT
    sales_region,
    COUNT(*) as total_count
FROM training.supply_chain_orders
GROUP BY sales_region
HAVING COUNT(*) > 100;


--Drill 17
SELECT
    customer_segment,
    ROUND(AVG(units_ordered), 2) as average_units_ordered
FROM training.supply_chain_orders
GROUP BY customer_segment
HAVING AVG(units_ordered) > 10;


