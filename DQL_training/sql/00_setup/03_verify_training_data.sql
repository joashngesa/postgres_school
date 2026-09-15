--check total data
SELECT
    COUNT(*) as total_records
FROM training.supply_chain_orders;

--check sample
SELECT *
FROM training.supply_chain_orders
LIMIT 20;


--check sample
SELECT *
FROM training.supply_chain_orders
ORDER BY order_item_id
LIMIT 20;



--check the data range
SELECT
    MIN(order_date) as earliest_order_date,
    MAX(order_date) as latest_order_date
FROM training.supply_chain_orders;


--check category variety
SELECT
    DISTINCT product_category
FROM training.supply_chain_orders
ORDER BY product_category;



--check shipment statuses
SELECT
    DISTINCT shipment_status
FROM training.supply_chain_orders
ORDER BY shipment_status;



--check null delivery dates
SELECT
    COUNT(*) as missing_delivery_dates
FROM training.supply_chain_orders
WHERE actual_delivery_date is NULL;
