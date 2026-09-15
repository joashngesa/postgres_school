--Drill 24: Full order line enrichment
    --inspect
    SELECT
        *
    FROM join_lab.fact_order_item
    ;

SELECT
    foi.order_item_id,
    foi.order_id,
    dd.full_date,
    dd.month_name,
    dc.customer_name,
    dc.customer_segment,
    dp.product_name,
    dp.category,
    dw.warehouse_city,
    foi.units_ordered,
    foi.unit_price,
    foi.discount_rate,
    foi.order_status
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
JOIN join_lab.dim_date as dd
ON dd.date_key = foi.order_date_key
;



--Drill 25: Monthly warehouse/ category report
SELECT
    dd.month_number,
    dd.month_name,
    dw.warehouse_city,
    dp.category,
    COUNT(DISTINCT foi.order_id) as order_count,
    COUNT(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_date as dd
ON dd.date_key = foi.order_date_key
JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
GROUP BY dd.month_number,
        dd.month_name,
        dw.warehouse_city,
        dp.category
ORDER BY dd.month_number,
        dw.warehouse_city,
        dp.category
        ;

        --  Inspect
        SELECT
            COUNT(*) as order_item_count,
            COUNT(DISTINCT order_id) as orders_count
        FROM join_lab.fact_order_item
        ;


--Drill 26: Customer segment * product category
SELECT
    dc.customer_segment,
    dp.category,
    COUNT(DISTINCT foi.customer_key) as customers_count,
    COUNT(DISTINCT foi.order_id) as orders_count,
    COUNT(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
GROUP BY dc.customer_segment,
        dp.category
        ;



--Drill 27: Warehouse performance by quarter
SELECT
    dd.quarter_number,
    dw.warehouse_city,
    COUNT(DISTINCT foi.order_id) as order_count,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value,
    COUNT(*) FILTER(
        WHERE foi.returned is True
    ) as returned_order_items
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
JOIN join_lab.dim_date as dd
ON dd.date_key = foi.order_date_key
GROUP BY dd.quarter_number,
        dw.warehouse_city
        ;



--Drill 28: Baseline row count
SELECT
    COUNT(*) as row_number
FROM join_lab.fact_order_item
    ;

SELECT
    COUNT(*) as join_row_count
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
    ;
--Comment: fact_order_item contains 180 rows, while the INNER JOIN produces 174 because
--      six fact rows reference customer keys that have no corresponding record in dim_customer.
--      INNER JOIN preserves only matched relationships.




--Drill 29: Left join preservation check
SELECT
    COUNT(*) as left_join_raw_count
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
    ;
--Comment: The joined row count is same as fact row count(left table) because when left join is used,
--  the table recorded first falls on the left which preserves all the values


--Drill 30: Find orphan customer keys
SELECT
    foi.order_item_id,
    foi.order_id,
    dc.customer_key
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
WHERE dc.customer_key is NULL;

--orphan row count
    SELECT
    COUNT(*) AS orphan_customer_rows
    FROM join_lab.fact_order_item AS foi
    LEFT JOIN join_lab.dim_customer AS dc
        ON dc.customer_key = foi.customer_key
    WHERE dc.customer_key IS NULL;
--distinct orphan customer keys
    SELECT
    COUNT(DISTINCT foi.customer_key) AS distinct_orphan_customer_keys
    FROM join_lab.fact_order_item AS foi
    LEFT JOIN join_lab.dim_customer AS dc
        ON dc.customer_key = foi.customer_key
    WHERE dc.customer_key IS NULL;



--Drill 31: Find orphan product keys
SELECT
    foi.product_key,
    COUNT(*) AS orphan_row_count
FROM join_lab.fact_order_item AS foi
LEFT JOIN join_lab.dim_product AS dp
    ON dp.product_key = foi.product_key
WHERE dp.product_key IS NULL
GROUP BY foi.product_key
ORDER BY foi.product_key;
    ;


--Drill 32: Find orphan warehouse keys
SELECT
    foi.order_id,
    foi.warehouse_key
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
WHERE dw.warehouse_key is NULL
    ;



--Drill 33: Referential-integrity summary
-- Customer referential-integrity check
SELECT 'orphan_customer_count' as orphan_count,
    COUNT(*) AS row_count
FROM join_lab.fact_order_item AS foi
LEFT JOIN join_lab.dim_customer AS dc
    ON dc.customer_key = foi.customer_key
WHERE dc.customer_key IS NULL
union all
-- Product referential-integrity check
SELECT 'orphan_product_rows' as orphan_count,
    COUNT(*) AS row_count
FROM join_lab.fact_order_item AS foi
LEFT JOIN join_lab.dim_product AS dp
    ON dp.product_key = foi.product_key
WHERE dp.product_key IS NULL
union all
-- Warehouse referential-integrity check
SELECT 'orphan_warehouse_rows' as orphan_count,
    COUNT(*) AS row_count
FROM join_lab.fact_order_item AS foi
LEFT JOIN join_lab.dim_warehouse AS dw
    ON dw.warehouse_key = foi.warehouse_key
WHERE dw.warehouse_key IS NULL
union all
-- Date referential-integrity check
SELECT 'orphan_date_rows' as orphan_count,
    COUNT(*) AS row_count
FROM join_lab.fact_order_item AS foi
LEFT JOIN join_lab.dim_date AS dd
    ON dd.date_key = foi.order_date_key
WHERE dd.date_key IS NULL;



