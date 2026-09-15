--Drill one
-- Return tot number of rows
SELECT
    COUNT(*)
FROM training.supply_chain_orders;


--Drill 2: return 3 values in a single row
SELECT
    COUNT(*) as total_rows,
    COUNT(actual_delivery_date)actual_delivery_dates_rows,
    COUNT(*) FILTER(WHERE actual_delivery_date is NULL) as null_actual_delivery_dates
FROM training.supply_chain_orders;


--Drill 3:
SELECT
    MIN(units_ordered) as minimum_units_ordered,
    MAX(units_ordered) as maximum_units_ordered,
    ROUND(AVG(units_ordered),2) as average_units_ordered,
    SUM(units_ordered) as total_units_ordered
FROM training.supply_chain_orders;


--Drill 4
--Comment: using order_date to understand what time_frame the
--tables represents, the earliest order_date and the latest_order_date
SELECT
    MIN(order_date) as earliest_order_date,
    MAX(order_date) as latest_order_date
FROM training.supply_chain_orders;


--Drill 5:
SELECT
    COUNT(DISTINCT customer_name) as customers_count
FROM training.supply_chain_orders;


--Drill 6:
--NULL ORDER_IDs: count(*) - count(order_id) subtract total_rows from row_values
--REPEATED_ORDER_ID: count(order_id), counts all order_id listed in the table
--TABLE_GRAIN: represented by count(*)


--bonus
SELECT
    warehouse_city,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_order_count
FROM training.supply_chain_orders
GROUP BY warehouse_city
ORDER BY row_count DESC;

--table inspection
SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT order_item_id) AS distinct_order_items,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM training.supply_chain_orders;
