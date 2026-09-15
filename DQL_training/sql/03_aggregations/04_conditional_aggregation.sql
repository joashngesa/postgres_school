--Drill 18
--Comment: completed rows & late rows are not not in the table
SELECT
    COUNT(*) as total_rows,
    COUNT(actual_delivery_date) as non_null_actual_delivery_date,
    COUNT(*) FILTER(WHERE actual_delivery_date is NULL) as null_actual_delivery_date
FROM training.supply_chain_orders
WHERE shipment_status = 'In Transit';


--Drill 19
SELECT
    warehouse_city,
    COUNT(*) as total_rows,
    COUNT(actual_delivery_date) as non_null_actual_delivery_date,
    COUNT(*) FILTER(WHERE actual_delivery_date is NULL) as null_actual_delivery_date
FROM training.supply_chain_orders
WHERE shipment_status = 'Cancelled'
GROUP BY warehouse_city;


--Drill 20
SELECT DISTINCT
    units_ordered
FROM training.supply_chain_orders
ORDER BY units_ordered DESC;

SELECT
    supplier_name,
    warehouse_city,
    product_category,
    units_ordered,
    CASE
        WHEN units_ordered > 70 THEN 'High quantity'
        WHEN units_ordered > 30 THEN 'Medium quantity'
        ELSE 'Low quantity'
    end as quantity_classification
FROM training.supply_chain_orders;


--Drill 21
SELECT
    warehouse_city,
    product_category,
    sum(units_ordered)filter(WHERE units_ordered > 70) as high_units_ordered
FROM training.supply_chain_orders
GROUP BY warehouse_city,
        product_category;


--Drill 22
--the count will include the 0 values which alters the intention of the query,
-- the query counts all values.
SELECT
    warehouse_city,
    COUNT(
        CASE
            WHEN shipment_status = 'Delivered' THEN 1
            else 0
        end
    ) as delivered_count
FROM training.supply_chain_orders
GROUP BY warehouse_city;

SELECT
    warehouse_city,
    SUM(
        CASE
            WHEN shipment_status = 'Delivered' THEN 1
            else 0
        end
    ) as delivered_count
FROM training.supply_chain_orders
GROUP BY warehouse_city;


--view of the table
SELECT *
FROM training.supply_chain_orders
LIMIT 5;


--Checkpoint A
SELECT
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_item_id) as distinct_order_items,
    COUNT(DISTINCT order_id) as distinct_orders,
    COUNT(DISTINCT customer_id) as distinct_customers,
    COUNT(DISTINCT product_id) as distinct_products,
    COUNT(DISTINCT supplier_id) as distinct_suppliers
FROM training.supply_chain_orders;


--Checkpoint B
SELECT
    warehouse_city,
    COUNT(*) as rows_count,
    COUNT(DISTINCT order_id) as distinct_order_count,
    COUNT(DISTINCT customer_id) as distinct_customer_count
FROM training.supply_chain_orders
GROUP BY warehouse_city
ORDER BY COUNT(*) DESC;


--Checkpoint C
SELECT
    COUNT(*) as total_rows,
    COUNT(*) FILTER(WHERE shipment_status = 'Delivered') as delivered_rows,
    COUNT(*) FILTER(WHERE shipment_status = 'Cancelled') as cancelled_rows,
    COUNT(*) FILTER(WHERE returned is TRUE) as returned_rows,
    COUNT(*) FILTER(WHERE actual_delivery_date is NULL) as missing_actual_delivery_date,
    COUNT(*) FILTER(
        WHERE actual_delivery_date > promised_delivery_date) as late_delivery_date
FROM training.supply_chain_orders;


--Checkpoint D
SELECT
    CASE
        WHEN units_ordered > 70 THEN 'High Quantity'
        WHEN units_ordered > 30 THEN 'Medium Quantity'
        ELSE 'Low'
    end AS quantity_classification,
    count(*) as rows_count
FROM training.supply_chain_orders
GROUP BY
        CASE
            WHEN units_ordered > 70 THEN 'High Quantity'
            WHEN units_ordered > 30 THEN 'Medium Quantity'
        ELSE 'Low'
        end;
