-- Pipeline batch investigation
SELECT
    order_id,
    supplier_name,
    units_ordered,
    unit_cost,
    batch_id
FROM training.supply_chain_orders
WHERE regexp_replace(batch_id, '[^0-9]', '', 'g') = '202401'
LIMIT 20;

SELECT
    batch_id,
    length(batch_id) as character_length,
    COUNT(*)
FROM training.supply_chain_orders
WHERE batch_id like '%202401%'
GROUP BY batch_id,
    length(batch_id)



--High valued delayed orders
--find delayed shipments worth more than $25,000
SELECT
    COUNT(*)
FROM training.supply_chain_orders
WHERE shipment_status ILIKE 'Delayed';

SELECT
    customer_name,
    sales_region,
    units_ordered * unit_price as value_order
FROM training.supply_chain_orders
WHERE units_ordered * unit_price > 25000
ORDER BY units_ordered * unit_price DESC
limit 30;


SELECT
    COUNT(*) as orders_above_25000
FROM training.supply_chain_orders
WHERE units_ordered * unit_price > 25000



--Suspicious warehouse assignments
--where warehouse_city is null and shipment_status is delivered
SELECT
    COUNT(*)
FROM training.supply_chain_orders
WHERE warehouse_city is NULL AND shipment_status ILIKE '%delivered%';



--date boundary
SELECT
    order_id,
    customer_name,
    actual_delivery_date
FROM training.supply_chain_orders
WHERE actual_delivery_date is not NULL AND
        actual_delivery_date >= date '2025-01-01'
        AND actual_delivery_date < date '2026-01-01'
LIMIT 30;


--retrive orders from edmonton
--status (delayed, cancelled)
--units > 500 ( i had to change the units_ordered to 50 beacause the max is 100)
--sort highest unit first
--return only 20 records
SELECT
    product_id,
    product_name,
    product_category,
    warehouse_city,
    shipment_status,
    units_ordered
FROM training.supply_chain_orders
WHERE warehouse_city ilike 'edmonton' AND
        shipment_status in ('Delayed', 'Cancelled') AND
        units_ordered > 50
ORDER BY units_ordered DESC
LIMIT 50;

SELECT
    units_ordered
FROM training.supply_chain_orders
ORDER BY units_ordered DESC
LIMIT 10;



--show 25 most valuable orders
--focuss on batch_id 202412 that are not delivered and have a known supplier
SELECT
    COUNT(*)
FROM training.supply_chain_orders
WHERE supplier_id is NULL;

SELECT
    order_id,
    supplier_name,
    shipment_status,
    units_ordered,
    unit_price,
    units_ordered * unit_price as order_value
FROM training.supply_chain_orders
ORDER BY units_ordered * unit_price DESC
LIMIT 25;
