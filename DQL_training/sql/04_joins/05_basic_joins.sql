--Enrich order lines with customer names
SELECT
    ctm.customer_name,
    sol.staging_row_id,
    sol.source_order_id,
    sol.customer_id,
    sol.sku,
    sol.warehouse_code,
    sol.units_ordered
FROM join_lab.stg_order_line AS sol
join join_lab.dim_customer as ctm
ON sol.customer_id = ctm.customer_id;

--Comment: Inner join was used as we are keen enrich the stg_order_line
        -- with matching customer names



--Enrich sales with products
SELECT
    pdt.product_name,
    pdt.category,
    foi.units_ordered,
    foi.unit_price,
    foi.units_ordered * foi.unit_price as sales
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_product as pdt
ON foi.product_key = pdt.product_key;


--Attach warehouse cities
SELECT
    whs.warehouse_city,
    whs.province,
    foi.units_ordered,
    foi.unit_price,
    foi.discount_rate,
    foi.shipping_cost,
    foi.order_status,
    foi.returned
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_warehouse as whs
ON foi.warehouse_key = whs.warehouse_key;

--Attach calender attributes
SELECT
    dd.full_date,
    dd.year_number,
    dd.month_name,
    foi.units_ordered,
    foi.unit_price,
    foi.discount_rate,
    foi.shipping_cost,
    foi.order_status,
    foi.returned
FROM join_lab.fact_order_item as foi
left JOIN join_lab.dim_date as dd
ON foi.order_date_key = dd.date_key;


--Identify customers with orders
SELECT
    dc.customer_name,
    foi.units_ordered,
    foi.unit_price
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON dc.customer_key = foi.customer_key
WHERE foi.units_ordered is not NULL;

--Alternatively

SELECT
    dc.customer_name,
    foi.units_ordered,
    foi.unit_price
FROM join_lab.dim_customer as dc
JOIN join_lab.fact_order_item as foi
ON dc.customer_key = foi.customer_key;


--Preserve customers without orders
SELECT
    dc.*
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON dc.customer_key = foi.customer_key
WHERE foi.customer_key is NULL;


--preserve products without sales;
SELECT
    dp.*
FROM join_lab.dim_product as dp
LEFT JOIN join_lab.fact_order_item as foi
ON dp.product_key = foi.product_key
WHERE foi.product_key is NULL;


--compare source and reference populations;



--generate every warehouse × month combination
SELECT
    dw.*,
    dd.month_name
FROM join_lab.dim_warehouse as dw
JOIN join_lab.fact_order_item as foi
ON dw.warehouse_key = foi.warehouse_key
JOIN join_lab.dim_date as dd
ON foi.order_date_key = dd.date_key;
