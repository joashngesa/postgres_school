-- Determine the grain for bridge_product_supplier
SELECT *
FROM join_lab.bridge_product_supplier;

SELECT
    product_key,
    count(*) as count
FROM join_lab.bridge_product_supplier
GROUP BY product_key
HAVING count(*) > 1;

SELECT
    supplier_key,
    count(*) as count
FROM join_lab.bridge_product_supplier
GROUP BY supplier_key
HAVING count(*) > 1;

SELECT
    product_key,
    supplier_key,
    count(*) as count
FROM join_lab.bridge_product_supplier
GROUP BY product_key,
    supplier_key
HAVING count(*) > 1;

--Determine the grain for dim_customer
SELECT *
FROM join_lab.dim_customer;

SELECT
    customer_key,
    count(*) as count
FROM join_lab.dim_customer
GROUP BY customer_key
HAVING count(*) > 1;

SELECT
    customer_id,
    count(*) as count
FROM join_lab.dim_customer
GROUP BY customer_id
HAVING count(*) > 1;


--Determine dim_date grain
SELECT *
FROM join_lab.dim_date;

SELECT
    date_key,
    count(*) as count
FROM join_lab.dim_date
GROUP BY date_key
HAVING count(*) > 1;

SELECT
    full_date,
    count(*) as count
FROM join_lab.dim_date
GROUP BY full_date
HAVING count(*) > 1;

--Determine dim_product grain
SELECT *
FROM join_lab.dim_product;

SELECT
    sku,
    count(*) as row
FROM join_lab.dim_product
GROUP BY sku
HAVING count(*) > 1;

SELECT
    product_name,
    count(*) as row
FROM join_lab.dim_product
GROUP BY product_name
HAVING count(*) > 1;

SELECT *
FROM join_lab.dim_product;

--Check dim_supplier
SELECT *
FROM join_lab.dim_supplier;

SELECT
    supplier_name,
    count(*) as count
FROM join_lab.dim_supplier
GROUP BY supplier_name
HAVING count(*) > 1;

--Check dim_warehouse
SELECT *
FROM join_lab.dim_warehouse;

SELECT
    warehouse_key,
    count(*) as count
FROM join_lab.dim_warehouse
GROUP BY warehouse_key
HAVING count(*) > 1;


--Check fact_order_item
SELECT *
FROM join_lab.fact_order_item
--LIMIT 30
;
SELECT
    order_item_id,
    count(*) as count
FROM join_lab.fact_order_item
GROUP BY order_item_id
HAVING count(*) > 1;

SELECT
    order_id,
    count(*) as count
FROM join_lab.fact_order_item
GROUP BY order_id
HAVING count(*) > 1;

SELECT
    order_id,
    count(*) as count
FROM join_lab.fact_order_item
GROUP BY order_id
HAVING count(*) > 1;

--Check fact_return
SELECT *
FROM join_lab.fact_return
LIMIT 20;

SELECT
    order_item_id,
    count(*) as count
FROM join_lab.fact_return
GROUP BY order_item_id
HAVING count(*) > 1;

SELECT
    return_id,
    count(*) as count
FROM join_lab.fact_return
GROUP BY return_id
HAVING count(*) > 1;

--Check fact_shipment_event
SELECT *
FROM join_lab.fact_shipment_event;

SELECT
    shipment_event_id,
    count(*) as count
FROM join_lab.fact_shipment_event
GROUP BY shipment_event_id
HAVING count(*) > 1;

SELECT
    order_id,
    count(*) as count
FROM join_lab.fact_shipment_event
GROUP BY order_id
HAVING count(*) > 1;

--Check stg_order_line
SELECT *
FROM join_lab.stg_order_line;

SELECT
    staging_row_id,
    count(*) as count
FROM join_lab.stg_order_line
GROUP BY staging_row_id
HAVING count(*) > 1;

SELECT
    source_order_id,
    count(*) as count
FROM join_lab.stg_order_line
GROUP BY source_order_id
HAVING count(*) > 1;

--product-supplier cardinality
SELECT *
FROM join_lab.dim_product;
SELECT *
FROM join_lab.dim_supplier;
SELECT *
FROM join_lab.bridge_product_supplier;

--lines per order cardinality
SELECT *
FROM join_lab.stg_order_line;

--shipment_event_per_order cardinality
SELECT *
FROM join_lab.fact_shipment_event
LIMIT 30;
SELECT *
FROM join_lab.fact_order_item
LIMIT 30;
