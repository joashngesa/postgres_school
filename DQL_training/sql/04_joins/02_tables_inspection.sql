SELECT 'dim_customer' AS table_name, COUNT(*) AS rows
FROM join_lab.dim_customer

UNION ALL

SELECT 'dim_date' as table_name,
    count(*) as rows
FROM join_lab.dim_date

UNION all

select 'dim_product' as table_name,
    count (*) as rows
from join_lab.dim_product

union all

select 'dim_supplier' as table_name,
    count(*) as rows
from join_lab.dim_supplier

union all

select 'dim_warehouse' as table_name,
    count(*) as rows
from join_lab.dim_warehouse

union all

select 'bridge_product_supplier' as table_name,
    count(*) as rows
from join_lab.bridge_product_supplier

union all

select 'fact_order_item' as table_name,
    count(*) as rows
from join_lab.fact_order_item

union all

select 'fact_return' as table_name,
    count(*) as rows
from join_lab.fact_return

union all

select 'fact_shipment_event' as table_name,
    count(*) as rows
from join_lab.fact_shipment_event

union all

select 'stg_order_line' as table_name,
    count(*) as rows
from join_lab.stg_order_line;


SELECT *
FROM join_lab.bridge_product_supplier;


SELECT *
FROM join_lab.dim_customer
ORDER BY customer_key;


SELECT *
FROM join_lab.dim_date
ORDER BY date_key;


SELECT *
FROM join_lab.dim_product
ORDER BY product_key;


SELECT *
FROM join_lab.dim_supplier
ORDER BY supplier_key;


SELECT *
FROM join_lab.dim_warehouse
ORDER BY warehouse_key;


SELECT *
FROM join_lab.fact_order_item
LIMIT 30;


SELECT *
FROM join_lab.fact_return
ORDER BY return_id;


SELECT *
FROM join_lab.fact_shipment_event
ORDER BY shipment_event_id;


SELECT *
FROM join_lab.stg_order_line
ORDER BY staging_row_id;
