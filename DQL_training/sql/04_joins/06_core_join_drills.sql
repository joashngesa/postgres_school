--Block A: inner join fundamentals
--Drill 1: Order-> customer enrichment
--Comment: Before JOIN: 180 fact rows
--          INNER JOIN:
--          ≤ 180 rows
--          because unmatched/orphan customer keys disappear

--            LEFT JOIN:
--            = 180 rows
--            because every fact row survives

SELECT
    foi.order_item_id,
    foi.order_id,
    foi.customer_key,
    dc.customer_name,
    dc.customer_segment,
    foi.units_ordered
from join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON foi.customer_key = dc.customer_key;

--inspect fact_order_item
SELECT
    count(*) as row_number
FROM join_lab.fact_order_item;

--Drill 2: Order-> product_enrichment
--Inspect product_key in fact_order_item
SELECT
    count(*) row_counts,
    product_key
FROM join_lab.dim_product
GROUP BY product_key
HAVING count(*) > 1;

SELECT
    foi.order_item_id,
    foi.order_id,
    foi.product_key,
    dp.sku,
    dp.product_name,
    dp.category,
    foi.units_ordered,
    foi.unit_price
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_product as dp
ON foi.product_key = dp.product_key;


--Drill 3: Warehouse enrichment
SELECT
    foi.order_id,
    foi.order_item_id,
    foi.warehouse_key,
    dw.warehouse_code,
    dw.warehouse_city,
    dw.capacity_class
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
ORDER BY foi.order_id,
    foi.order_item_id;


--Drill 4: Date enrichment
SELECT
    foi.order_id,
    foi.order_item_id,
    foi.order_date_key,
    dd.full_date,
    dd.month_name,
    dd.quarter_number,
    dd.day_name
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_date as dd
ON foi.order_date_key = dd.date_key;


--Drill 5: Customer revenue
SELECT
    dc.customer_name,
    dc.customer_key,
    count(distinct foi.order_id) as order_count,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
GROUP BY dc.customer_name,
        dc.customer_key;

--inspect order_id
SELECT
    count(*) as row_count,
    order_id
FROM join_lab.fact_order_item
GROUP BY order_id
HAVING count(*) > 1;



--Drill 6: Product-category sales
SELECT
    dp.category,
    count(distinct foi.order_id) as order_count,
    sum(foi.units_ordered) as units_sold,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_product as dp
ON foi.product_key = dp.product_key
GROUP BY dp.category
ORDER BY sum(foi.units_ordered * foi.unit_price) DESC;


--BLOCK B: LEFT JOIN fundamentals
--Drill 7: Preserve every customer
SELECT
    dc.customer_key,
    dc.customer_id,
    dc.customer_name,
    foi.order_id,
    foi.order_item_id
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON dc.customer_key = foi.customer_key;

--Comment: dim_customer controls the preservation


--Drill 8: customers without order item
SELECT
    dc.customer_key,
    dc.customer_id,
    dc.customer_name,
    dc.customer_segment
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key
WHERE foi.order_item_id is null;


--Drill 9: Preserve every product
SELECT
    dp.product_key,
    dp.sku,
    dp.product_name,
    foi.order_item_id,
    foi.order_id
FROM join_lab.dim_product as dp
LEFT JOIN join_lab.fact_order_item as foi
ON dp.product_key = foi.product_key;

    --Inspect product with no sales
    SELECT
    dp.product_key,
    dp.sku,
    dp.product_name,
    foi.units_ordered,
    foi.unit_price
    FROM join_lab.dim_product as dp
    LEFT JOIN join_lab.fact_order_item as foi
    ON dp.product_key = foi.product_key
    WHERE foi.order_item_id is NULL;


--Drill 10: Product sales including zero sales
SELECT
    dp.product_key,
    dp.product_name,
    dp.category,
    COUNT(foi.order_item_id) as order_item_count,
    COALESCE(sum(foi.units_ordered), 0) as total_units,
    COALESCE(sum(foi.units_ordered * foi.unit_price), 0) as gross_order_value
FROM join_lab.dim_product as dp
LEFT JOIN join_lab.fact_order_item as foi
ON dp.product_key = foi.product_key
GROUP BY dp.product_key,
        dp.product_name,
        dp.category;



--Drill 11: Warehouse activity
SELECT
    dw.warehouse_code,
    dw.warehouse_key,
    dw.warehouse_city,
    COUNT(distinct foi.order_id) as order_count,
    count(foi.order_item_id) as order_item_count,
    COALESCE(sum(foi.units_ordered), 0) as total_units,
    COALESCE(sum(foi.units_ordered * foi.unit_price), 0) as gross_order_value
FROM join_lab.dim_warehouse as dw
LEFT JOIN join_lab.fact_order_item as foi
ON dw.warehouse_key = foi.warehouse_key
GROUP BY dw.warehouse_key,
        dw.warehouse_code,
        dw.warehouse_city;



--Drill 12: Active customers only, while preserving no order customers
    --inspect dim_customer
    SELECT *
    FROM join_lab.dim_customer;

SELECT
    dc.customer_id,
    dc.customer_name,
    dc.active_flag,
    foi.order_id,
    foi.order_item_id
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key
WHERE dc.active_flag is True;


--Block C: JOIN condition vs Where- condition trap
--Drill 13: Completed orders: version A
    --inspect order_status
    SELECT
        DISTINCT order_status
    FROM join_lab.fact_order_item;

SELECT
    COUNT(dc.customer_key),
    dc.customer_name,
    foi.order_id,
    foi.order_status
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key
WHERE foi.order_status = 'Completed'
GROUP BY dc.customer_name,
        foi.order_id,
        foi.order_status;



--Drill 14: Completed orders version B
SELECT
    COUNT(DISTINCT dc.customer_key),
    dc.customer_name,
    foi.order_id,
    foi.order_status
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key AND
    foi.order_status = 'Completed'
GROUP BY dc.customer_name,
        foi.order_id,
        foi.order_status;


--      Comparison of drill 13 & 14
--1. Drill 13 results eliminates the null values because after joining, the table
-- selects order_status with the the value 'completed' whereas drill 14 conducts
-- join with the order_status 'completed' thus including the null values
--2. Drill 14 preserves customers with no completed orders
--3. Where dictates the query to behave like inner join thus eliminating all the
-- null values for the outer-join behaviour



--Drill 15: Products with completed-order sales only
SELECT
    dp.product_name,
    dp.category,
    COUNT(foi.order_item_id) as completed_order_items,
    COALESCE(sum(foi.units_ordered), 0) as completed_units
FROM join_lab.dim_product as dp
LEFT JOIN join_lab.fact_order_item as foi
ON foi.product_key = dp.product_key and
    foi.order_status = 'Completed'
GROUP BY dp.product_name,
        dp.category;



--Drill 16: Preserve every order item using right join
SELECT
    foi.order_item_id,
    foi.order_id,
    foi.customer_key,
    dc.customer_key,
    dc.customer_name
FROM join_lab.dim_customer as dc
RIGHT JOIN join_lab.fact_order_item as foi
ON dc.customer_key = foi.customer_key;
    --Objective
    --Rows in the table whose customer does not exist in the dimension
    SELECT
        foi.*
    FROM join_lab.dim_customer as dc
    RIGHT JOIN join_lab.fact_order_item as foi
    ON dc.customer_key = foi.customer_key
    WHERE dc.customer_key is NULL;


--Drill 17: Rewrite drill 16 using LEFT join
--preserve every order item using left join
SELECT
    foi.order_item_id,
    foi.order_id,
    foi.customer_key,
    dc.customer_key,
    dc.customer_name
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key;

--Documentation: LEFT JOIN is easier to use as it is easy to remember that the
-- the first table(left table) is the table that preserves all the content


--FULL OUTER JOIN
--Drill 18-Customer/fact reconciliation
SELECT
    dc.customer_key as dc_customer_key,
    foi.customer_key as foi_customer_key,
    dc.customer_name,
    foi.order_item_id,
    foi.order_id
FROM join_lab.dim_customer as dc
FULL OUTER JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key;



--Drill 19: Classify reconciliation status
SELECT
    dc.customer_key as dim_customer_key,
    foi.customer_key as fact_customer_key,
    dc.customer_name,
    foi.order_item_id,
    foi.order_id,
    CASE
        WHEN dc.customer_key is NULL and foi.customer_key is not NULL THEN 'Fact_only'
        WHEN dc.customer_key is not NULL and foi.customer_key is null THEN 'Dimension_only'
        WHEN dc.customer_key is not NULL and foi.customer_key is not null THEN 'Matched'
    end as match_status
FROM join_lab.dim_customer as dc
FULL OUTER JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key;


--Drill 20: Count reconciliation status
SELECT
    CASE
        WHEN dc.customer_key is NULL and foi.customer_key is not NULL THEN 'Fact_only'
        WHEN foi.customer_key is NULL and dc.customer_key is not NULL THEN 'Dimension_only'
        WHEN foi.customer_key is not NULL and dc.customer_key is not NULL THEN 'Matched'
    END AS match_status,
    count(*) as row_count
FROM join_lab.dim_customer as dc
FULL OUTER JOIN join_lab.fact_order_item as foi
ON foi.customer_key = dc.customer_key
GROUP BY
    CASE
        WHEN dc.customer_key is NULL and foi.customer_key is not NULL THEN 'Fact_only'
        WHEN foi.customer_key is NULL and dc.customer_key is not NULL THEN 'Dimension_only'
        WHEN foi.customer_key is not NULL and dc.customer_key is not NULL THEN 'Matched'
    END;


    --BLOCK F: Cross join
--Drill 21: Warehouse * month matrix
SELECT
    dw.warehouse_code,
    dw.warehouse_city,
    dd.month_number,
    dd.month_name
FROM join_lab.dim_warehouse as dw
cross join (
    SELECT DISTINCT
        month_number,
        month_name
    FROM join_lab.dim_date
) as dd
ORDER BY dd.month_number;

--Expected output (warehouse-5 * dim_date-12=60) matching every value of the warehouse
-- to the dimension date.


--Drill 22: Warehouse * product_category
    --Inspect
    SELECT *
    FROM join_lab.dim_warehouse;

    SELECT DISTINCT
        category
    FROM join_lab.dim_product;

SELECT
    dw.warehouse_code,
    dw.warehouse_city,
    dp.category
FROM join_lab.dim_warehouse as dw
cross join (
    select
        DISTINCT category
    from join_lab.dim_product
) as dp;



--Drill 23: Customer segment * category mix
SELECT
    dc.customer_segment,
    dp.category
FROM (
    SELECT DISTINCT
        customer_segment
    FROM join_lab.dim_customer
) as dc
cross join (
    select DISTINCT
        category
    from join_lab.dim_product
) as dp
ORDER BY dc.customer_segment,
        dp.category;



