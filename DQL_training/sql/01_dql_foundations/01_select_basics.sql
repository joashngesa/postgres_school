--mike check ..🚦
SELECT *
FROM training.supply_chain_orders
LIMIT 10;


--select specific columns
SELECT
    customer_name as customer,
    warehouse_city as warehouse,
    sales_region as region,
    transport_mode,
    units_ordered as units,
    unit_price as price,
    discount_rate as discount_allowed
FROM training.supply_chain_orders
LIMIT 20;


SELECT
    DISTINCT warehouse_city
FROM training.supply_chain_orders;


SELECT
    DISTINCT sales_region
FROM training.supply_chain_orders;


SELECT
    DISTINCT transport_mode
FROM training.supply_chain_orders;


--calculate gross sales 💱
SELECT
    order_id,
    product_name,
    units_ordered,
    unit_price,
    units_ordered * unit_price as gross_sales
FROM training.supply_chain_orders
LIMIT 20;



--query costs 💲
SELECT
    MIN(unit_cost) as cheapest_cost,
    MAX(unit_cost) as highest_cost
FROM training.supply_chain_orders;

SELECT
    warehouse_city,
    sales_region,
    unit_cost
FROM training.supply_chain_orders
WHERE unit_cost BETWEEN 500 AND 659
ORDER BY unit_cost DESC
;

SELECT
    COUNT(*) as prices_500_659
FROM training.supply_chain_orders
WHERE unit_cost BETWEEN 500 AND 659;


--query supplier names beginning with North
SELECT DISTINCT
    supplier_name
FROM training.supply_chain_orders
;


--inspect batch_id
SELECT
    DISTINCT batch_id
FROM training.supply_chain_orders
ORDER BY batch_id DESC;

