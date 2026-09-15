--Drill 7
SELECT
    warehouse_city,
    count(warehouse_city) as warehouse_city_count
FROM training.supply_chain_orders
GROUP BY warehouse_city
ORDER BY count(warehouse_city) DESC;


--Drill 8:
SELECT
    warehouse_city,
    count(distinct warehouse_city) as warehouse_city_count
FROM training.supply_chain_orders
GROUP BY warehouse_city
ORDER BY count(warehouse_city) DESC;

--Comment: drill 7 counts the number of warehouse city value in group
-- whereas distinct counts the unique warehouse city in each group


--Drill 9:
SELECT
    supplier_name,
    COUNT(supplier_name) as supplier_count,
    product_category,
    COUNT(product_category) as product_category_count
FROM training.supply_chain_orders
GROUP BY supplier_name,
        product_category
ORDER BY COUNT(supplier_name);

SELECT
    warehouse_city,
    COUNT(warehouse_city) as warehouse_city_count,
    product_category,
    COUNT(product_category) as product_category_count
FROM training.supply_chain_orders
GROUP BY warehouse_city,
        product_category
ORDER BY COUNT(warehouse_city);


--Drill 10
--Comment: Output grain is 1 row per warehouse_city & product_category combination


--Drill 11:
SELECT
    product_category,
    SUM(units_ordered) as total_units_ordered
FROM training.supply_chain_orders
GROUP BY product_category
ORDER BY SUM(units_ordered) DESC;


--Drill 12:
--Comment: Addition of grouping column will result to more rows because
-- each row will be a break down of two columns, meaning one category will have
-- more than one combination
SELECT
    product_category,
    warehouse_city,
    SUM(units_ordered) as total_units_ordered
FROM training.supply_chain_orders
GROUP BY product_category,
        warehouse_city
ORDER BY SUM(units_ordered) DESC;


