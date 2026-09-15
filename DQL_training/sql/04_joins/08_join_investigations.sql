SELECT foi.*
from join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key


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



--Drill 34: Customers with absolutely no order activity
--Business request: Marketing wants customers currently represented in the dimension who
--                  have never appeared in fact_order_item.
SELECT
    dc.*
FROM join_lab.dim_customer as dc
LEFT JOIN join_lab.fact_order_item as foi
ON dc.customer_key = foi.customer_key
WHERE foi.customer_key is NULL;



--Drill 35: Products never sold
--Business request: Procurement wants to identify dimension products that have never
--                  appeared in order activity
SELECT
    dp.*
FROM join_lab.dim_product as dp
LEFT JOIN join_lab.fact_order_item as foi
ON foi.product_key = dp.product_key
WHERE foi.product_key is NULL;



--Drill 36: Unrecognized dimension references
--Business request: Data Quality believes some fact rows reference customer, product,
--                  or warehouse surrogate keys that do not exist
--customer check
SELECT
    'customer_dimension' as missing_dimension_table,
    foi.order_item_id,
    foi.order_id,
    foi.customer_key as invalid_key
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
WHERE dc.customer_key is NULL
UNION ALL
--product_check
SELECT
    'product_dimension',
    foi.order_item_id,
    foi.order_id,
    foi.product_key
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
WHERE dp.product_key is NULL
UNION ALL
--warehouse check
SELECT
    'warehouse_dimension',
    foi.order_item_id,
    foi.order_id,
    foi.warehouse_key
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
WHERE dw.warehouse_key is NULL;



--Drill 37: Customer monthly revenue
SELECT
    dd.month_number,
    dd.month_name,
    dc.customer_name,
    dc.customer_segment,
    COUNT(DISTINCT foi.order_id) as orders_count,
    sum(foi.units_ordered) as units_ordered,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_date as dd
ON dd.date_key = foi.order_date_key
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
GROUP BY dd.month_number,
        dd.month_name,
        dc.customer_name,
        dc.customer_segment
ORDER BY dd.month_number,
        dd.month_name,
        dc.customer_name
        ;



--Drill 38: Warehouse/category/customer_segment report
SELECT
    dw.warehouse_city,
    dp.category,
    dc.customer_segment,
    COUNT(DISTINCT foi.order_id) as order_count,
    count(DISTINCT foi.customer_key) as customers_count,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered) as total_units,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
GROUP BY dw.warehouse_city,
        dp.category,
        dc.customer_segment
ORDER BY dw.warehouse_city
        ;



--Drill 39: Compare inner vs left join counts
SELECT
    'inner_join' as join_type,
    COUNT(*) as row_count
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
UNION ALL
SELECT
    'left_join' as join_type,
    count(*) as row_count
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
    ;

--Explanation: the inner join count is 174 compared to left join which is 180. This is because
--             left join brings back values from the fact table preserving the fact values whereas
--             inner join preserves the matching values from the dimensioin table.



--Drill 40: The prediction drill
SELECT
    COUNT(*)
FROM join_lab.dim_customer AS c
JOIN join_lab.fact_order_item AS f
    ON c.customer_key = f.customer_key;

--1. Left grain:
    -- one row per customer
--2. Right grain:
    --one row per order_item
--3. Join cardinality:
    --one to many relationship
--4. Can dim_customer rows fan out?
    SELECT
        count(*) row_number,
        customer_key
    FROM join_lab.dim_customer
    GROUP BY customer_key
    HAVING count(*) > 1;
    --yes it can fun out when the fact table has more than one customer
--5. Can fact rows fan out?
    SELECT
        count(*) row_number,
        customer_key
    FROM join_lab.fact_order_item
    GROUP BY customer_key
    HAVING count(*) > 1;
    --no, because the customer_key in the dimension table is uniqu
--6. Can unmatched dimension rows disappear?
    --the unmatched rows in dimension table will dissapear as the table is using inner join
--7. Can orphan fact rows disappear?
    --yes beacause the join will bring back only matching values
--8. Expected result grain:
    --174
