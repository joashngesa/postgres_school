--Drill 41: Four-dimension enrichment
SELECT
    foi.order_item_id,
    foi.order_id,
    dd.full_date,
    dc.customer_name,
    dc.customer_segment,
    dp.product_name,
    dp.category,
    dw.warehouse_city,
    foi.units_ordered,
    foi.unit_price
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

    --compare counts
    SELECT COUNT(*) as fact_row_count
    FROM join_lab.fact_order_item
        ;

    with joined_tbl as (
        SELECT
        foi.order_item_id,
        foi.order_id,
        dd.full_date,
        dc.customer_name,
        dc.customer_segment,
        dp.product_name,
        dp.category,
        dw.warehouse_city,
        foi.units_ordered,
        foi.unit_price
        FROM join_lab.fact_order_item as foi
        JOIN join_lab.dim_customer as dc
        ON dc.customer_key = foi.customer_key
        JOIN join_lab.dim_product as dp
        ON dp.product_key = foi.product_key
        JOIN join_lab.dim_warehouse as dw
        ON dw.warehouse_key = foi.warehouse_key
        JOIN join_lab.dim_date as dd
        ON dd.date_key = foi.order_date_key
    )
    SELECT
        COUNT(*) as joined_row_count
    FROM joined_tbl
        ;



--Drill 42: Why did rows dissapear
SELECT
    'dim_customer' as orphan_table,
    'customer missing in dim_customer' as absence_reason,
    foi.customer_key as missing_key,
    foi.order_item_id,
    foi.order_id
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
WHERE dc.customer_key is NULL
UNION ALL
SELECT
    'dim_product',
    'product missing in dim_product',
    foi.product_key,
    foi.order_item_id,
    foi.order_id
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
WHERE dp.product_key is NULL
UNION ALL
SELECT
    'dim_warehouse',
    'warehouse missing in dim_warehouse',
    foi.warehouse_key,
    foi.order_item_id,
    foi.order_id
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
WHERE dw.warehouse_key is NULL
    ;



--Drill 43: Preserve the fact population
SELECT
    foi.order_item_id,
    foi.order_id,
    dd.full_date,
    dc.customer_name,
    dc.customer_segment,
    dp.product_name,
    dp.category,
    dw.warehouse_city,
    foi.units_ordered,
    foi.unit_price
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
LEFT JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
LEFT JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
LEFT JOIN join_lab.dim_date as dd
ON dd.date_key = foi.order_date_key
    ;

    --Inspect counts
    SELECT
        COUNT(*) as fact_rows_count
    FROM join_lab.fact_order_item
        ;

    WITH left_joins as (
        SELECT
            foi.order_item_id,
            foi.order_id,
            dd.full_date,
            dc.customer_name,
            dc.customer_segment,
            dp.product_name,
            dp.category,
            dw.warehouse_city,
            foi.units_ordered,
            foi.unit_price
        FROM join_lab.fact_order_item as foi
        LEFT JOIN join_lab.dim_customer as dc
        ON dc.customer_key = foi.customer_key
        LEFT JOIN join_lab.dim_product as dp
        ON dp.product_key = foi.product_key
        LEFT JOIN join_lab.dim_warehouse as dw
        ON dw.warehouse_key = foi.warehouse_key
        LEFT JOIN join_lab.dim_date as dd
        ON dd.date_key = foi.order_date_key
    )
    SELECT
        COUNT(*) as left_join_row_count
    FROM left_joins;



--Drill 44: Complete vs incomplete enrichment
--          Count rows per status
SELECT
    foi.order_item_id,
    foi.order_id,
    foi.customer_key,
    foi.product_key,
    foi.warehouse_key,
    CASE
        WHEN dc.customer_key is NULL and dp.product_key is NULL and dw.warehouse_key is NULL THEN 'Multiple reference failures'
        WHEN dc.customer_key is NULL and dp.product_key is NULL THEN 'Multiple reference failures'
        WHEN dc.customer_key is NULL and dw.warehouse_key is NULL THEN 'Multiple reference failures'
        WHEN dp.product_key is NULL and dw.warehouse_key is NULL THEN 'Multiple reference failures'
        WHEN dc.customer_key is NULL THEN 'Missing customer'
        WHEN dp.product_key is NULL THEN 'Missing product'
        WHEN dw.warehouse_key is NULL THEN 'Missing warehouse'
        ELSE 'Fully enriched'
    end as enrichment_status
FROM join_lab.fact_order_item as foi
LEFT JOIN join_lab.dim_customer as dc
ON dc.customer_key = foi.customer_key
LEFT JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
LEFT JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
    ;

--Alternatively:
with enrichment_check as (
    SELECT
    foi.order_item_id,
    foi.order_id,
    foi.customer_key,
    foi.product_key,
    foi.warehouse_key,

    CASE
        WHEN
        (CASE WHEN dc.customer_key IS NULL THEN 1 ELSE 0 END)
        + (CASE WHEN dp.product_key IS NULL THEN 1 ELSE 0 END)
        + (CASE WHEN dw.warehouse_key IS NULL THEN 1 ELSE 0 END) > 1
            THEN 'Multiple reference failures'

        WHEN dc.customer_key IS NULL
            THEN 'Missing customer'

        WHEN dp.product_key IS NULL
            THEN 'Missing product'

        WHEN dw.warehouse_key IS NULL
            THEN 'Missing warehouse'

        ELSE 'Fully enriched'
    END AS enrichment_status

    FROM join_lab.fact_order_item AS foi

    LEFT JOIN join_lab.dim_customer AS dc
        ON dc.customer_key = foi.customer_key

    LEFT JOIN join_lab.dim_product AS dp
        ON dp.product_key = foi.product_key

    LEFT JOIN join_lab.dim_warehouse AS dw
        ON dw.warehouse_key = foi.warehouse_key
)
SELECT
    enrichment_status,
    COUNT(*) as row_count
FROM enrichment_check
GROUP BY enrichment_status
ORDER BY enrichment_status
    ;



--Drill 45: Monthly category/ warehouse sales
--OUTPUT GRAIN: month * warehouse * category
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
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
JOIN join_lab.dim_warehouse as dw
ON dw.warehouse_key = foi.warehouse_key
GROUP BY dd.month_number,
        dd.month_name,
        dw.warehouse_city,
        dp.category
        ;



--Drill 46: Supplier relationship per product
    --Inspect tables
    SELECT *
    FROM join_lab.dim_product;
    SELECT *
    FROM join_lab.dim_supplier;
    SELECT *
    FROM join_lab.bridge_product_supplier;
    SELECT
        product_key,
        COUNT(*) as product_key_count
    FROM join_lab.bridge_product_supplier
    GROUP BY product_key
    ORDER BY product_key;
    SELECT
        supplier_key,
        COUNT(*) as supplier_count
    FROM join_lab.bridge_product_supplier
    GROUP BY supplier_key
    ORDER BY supplier_key;

SELECT
    dp.product_key,
    dp.sku,
    dp.product_name,
    ds.supplier_key,
    ds.supplier_name,
    bps.preferred_supplier
FROM join_lab.dim_product as dp
JOIN join_lab.bridge_product_supplier as bps
ON bps.product_key = dp.product_key
JOIN join_lab.dim_supplier as ds
ON ds.supplier_key = bps.supplier_key
ORDER BY dp.product_key,
        ds.supplier_key
    ;



--Drill 47: Suppliers per product
SELECT
    dp.product_key,
    dp.product_name,
    COUNT(bps.supplier_key) as supplier_count
FROM join_lab.bridge_product_supplier as bps
JOIN join_lab.dim_product as dp
ON dp.product_key = bps.product_key
JOIN join_lab.dim_supplier as ds
ON ds.supplier_key = bps.supplier_key
GROUP BY dp.product_key,
        dp.product_name
ORDER BY COUNT(bps.supplier_key) DESC
    ;



--Drill 48: Products per supplier
SELECT
    ds.supplier_key,
    ds.supplier_name,
    COUNT(bps.product_key) as product_count
FROM join_lab.bridge_product_supplier as bps
JOIN join_lab.dim_supplier as ds
ON ds.supplier_key = bps.supplier_key
JOIN join_lab.dim_product as dp
ON dp.product_key = bps.product_key
GROUP BY ds.supplier_key,
        ds.supplier_name
ORDER BY ds.supplier_key
        ;

--Comment: The relationship between suppliers & product dimension tables is prooved to be
--         many to many because one supplier can have more than one product and one product
--         can have more than one supplier.



--Drill 49: Preferred supplier only
SELECT
    dp.product_key,
    dp.product_name,
    ds.supplier_name,
    bps.preferred_supplier
FROM join_lab.bridge_product_supplier as bps
JOIN join_lab.dim_product as dp
ON dp.product_key = bps.product_key
JOIN join_lab.dim_supplier as ds
ON ds.supplier_key = bps.supplier_key

--Check if every product has exactly one preferred supplier?
WITH preferred_suppliers as (
    SELECT
        dp.product_key,
        dp.product_name,
        ds.supplier_name,
        bps.preferred_supplier
    FROM join_lab.bridge_product_supplier as bps
    JOIN join_lab.dim_product as dp
    ON dp.product_key = bps.product_key
    JOIN join_lab.dim_supplier as ds
    ON ds.supplier_key = bps.supplier_key
    WHERE bps.preferred_supplier is True
)
SELECT
    product_key,
    COUNT(*) as product_count
FROM preferred_suppliers
GROUP BY product_key
HAVING COUNT(*) > 1
    ;


        --CONTROLLED FAN-OUT
--Drill 50: Order items -> supplier relationships
SELECT COUNT(*) as row_count
FROM join_lab.fact_order_item;
--Check for join key uniqueness
    SELECT
        product_key,
        COUNT(*) as product_key_count
    FROM join_lab.bridge_product_supplier
    GROUP BY product_key
    HAVING COUNT(*) > 1
    ORDER BY product_key;

with join_tbl as (
    SELECT
        foi.order_item_id,
        foi.order_id,
        foi.product_key,
        bps.supplier_key
    FROM join_lab.fact_order_item as foi
    JOIN join_lab.bridge_product_supplier AS bps
    ON bps.product_key = foi.product_key
)
SELECT
    COUNT(*) as row_count
FROM join_tbl

--N/B:
--The bridge correctly represents the many-to-many product/supplier relationship.
--Joining another many-side dataset to that bridge can legitimately fan out rows.
--Whether that's acceptable depends on the required output grain and whether any
--  measures survive that grain change safely.



--Drill 51: Which fact rows fanned out?
--desired output grain: one row per fact fanned out row
WITH join_tbl AS (
    SELECT
        foi.order_item_id,
        foi.order_id,
        foi.product_key,
        bps.supplier_key
    FROM join_lab.fact_order_item AS foi
    JOIN join_lab.bridge_product_supplier AS bps
    ON bps.product_key = foi.product_key
)
SELECT
    order_item_id,
    COUNT(*) AS supplier_matches
FROM join_tbl
GROUP BY order_item_id
HAVING COUNT(*) > 1
ORDER BY supplier_matches DESC,
        order_item_id;



--Drill 52: Maximum fan out
WITH supplier_matches AS (
    SELECT
        foi.order_item_id,
        COUNT(bps.supplier_key) AS supplier_matches
    FROM join_lab.fact_order_item AS foi
    LEFT JOIN join_lab.bridge_product_supplier AS bps
    ON bps.product_key = foi.product_key
    GROUP BY foi.order_item_id
)
SELECT
    MIN(supplier_matches) AS minimum_supplier_matches,
    MAX(supplier_matches) AS maximum_supplier_matches,
    ROUND(AVG(supplier_matches), 2) AS average_supplier_matches
FROM supplier_matches;



--Drill 53: Full supplier enrichment
with enrichment_tbl as (
    SELECT
        foi.order_item_id,
        foi.order_id,
        bps.product_key,
        ds.supplier_key,
        ds.supplier_name,
        bps.preferred_supplier,
        foi.units_ordered,
        foi.unit_price
    FROM join_lab.fact_order_item as foi
    JOIN join_lab.bridge_product_supplier as bps
    ON bps.product_key = foi.product_key
    JOIN join_lab.dim_supplier as ds
    ON ds.supplier_key = bps.supplier_key
)
SELECT
    COUNT(DISTINCT order_item_id) as distinct_order_item_id,
    COUNT(*) as row_count
FROM enrichment_tbl
    ;



--BLOCK D: Measuring Inflation
--Drill 54: Establish trusted baseline revenue
with baseline_revenue as (
    SELECT
        order_item_id,
        sum(units_ordered) as units_ordered,
        sum(units_ordered * unit_price) as baseline_revenue
    FROM join_lab.fact_order_item
    GROUP BY order_item_id
    ORDER BY order_item_id
)
SELECT
    COUNT(*) as row_count
FROM baseline_revenue
    ;


--Drill 55: Join suppliers & recalculate revenue
select
    count(*) as fact_row_count,
    sum(units_ordered * unit_price) as baseline_gross_order_value
from join_lab.fact_order_item
    ;

with joined_baseline as (
    SELECT
        foi.order_item_id,
        bps.supplier_key,
        sum(foi.units_ordered) as units_ordered,
        sum(foi.units_ordered * foi.unit_price) as joined_revenue
    FROM join_lab.fact_order_item as foi
    JOIN join_lab.bridge_product_supplier as bps
    ON bps.product_key = foi.product_key
    GROUP BY foi.order_item_id,
            bps.supplier_key
    ORDER BY order_item_id
)
SELECT
    COUNT(*) as joined_row_count
FROM joined_baseline
    ;

--Comment: Drills differ in outcome and when sales is calculated they will bring different figures.
--         The relationship multiplies the measure because the join has many to many
--         relationship where the order_item_id(grain) can appear twice in the join thus
--         increasing the measure
--


--Drill 56: Find products causing inflation
with baseline_revenue as (
    SELECT
        sum(units_ordered * unit_price) as baseline_revenue
    FROM join_lab.fact_order_item
),
joined_baseline as (
    SELECT
        sum(foi.units_ordered * foi.unit_price) as joined_revenue
    FROM join_lab.fact_order_item as foi
    JOIN join_lab.bridge_product_supplier as bps
    ON bps.product_key = foi.product_key
)
SELECT
    baseline_revenue,
    joined_revenue,
    (joined_revenue - baseline_revenue) as inflation_amount,
    round(((
        joined_revenue - baseline_revenue) / baseline_revenue) * 100, 2) as inflation_percentage
FROM baseline_revenue
CROSS JOIN joined_baseline
    ;



--Drill 57: Find products causing inflation
with baseline_revenue as (
    SELECT
        product_key,
        sum(units_ordered * unit_price) as baseline_revenue
    FROM join_lab.fact_order_item
    GROUP BY product_key
),
joined_revenue as (
SELECT
    dp.product_key,
    dp.product_name,
    count(distinct ds.supplier_key) as supplier_count,
    sum(foi.units_ordered * foi.unit_price) as joined_revenue
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
JOIN join_lab.bridge_product_supplier as bps
ON bps.product_key = dp.product_key
JOIN join_lab.dim_supplier as ds
ON ds.supplier_key = bps.supplier_key
GROUP BY dp.product_key,
        dp.product_name
)
SELECT
    br.product_key,
    jr.product_name,
    jr.supplier_count,
    br.baseline_revenue as true_revenue,
    jr.joined_revenue as revenue_after_supplier_join,
    (jr.joined_revenue - br.baseline_revenue) as inflated_amount
FROM baseline_revenue as br
JOIN joined_revenue as jr
ON jr.product_key = br.product_key
WHERE jr.joined_revenue > br.baseline_revenue
    ;



--Drill 58: Preferred supplier revenue
with baseline_revenue as (
    SELECT
        product_key,
        sum(units_ordered * unit_price) as baseline_revenue
    FROM join_lab.fact_order_item
    GROUP BY product_key
),
joined_revenue as (
SELECT
    dp.product_key,
    dp.product_name,
    count(distinct ds.supplier_key) as supplier_count,
    sum(foi.units_ordered * foi.unit_price) as joined_revenue
FROM join_lab.fact_order_item as foi
JOIN join_lab.dim_product as dp
ON dp.product_key = foi.product_key
JOIN join_lab.bridge_product_supplier as bps
ON bps.product_key = dp.product_key
and bps.preferred_supplier is True
JOIN join_lab.dim_supplier as ds
ON ds.supplier_key = bps.supplier_key
and bps.preferred_supplier is True
GROUP BY dp.product_key,
        dp.product_name
)
SELECT
    br.product_key,
    jr.product_name,
    jr.supplier_count,
    br.baseline_revenue as true_revenue,
    jr.joined_revenue as revenue_after_supplier_join,
    (jr.joined_revenue - br.baseline_revenue) as inflated_amount
FROM baseline_revenue as br
JOIN joined_revenue as jr
ON jr.product_key = br.product_key
    ;



--Checkpoint D: Aggregate before join  + grain alignment
--Drill 59: Supplier count by product first

    select
        product_key,
        count(supplier_key) as supplier_count
    from join_lab.bridge_product_supplier
    group by product_key
    ;



--Drill 60: Join supplier count to facts
with supplier_count as (
    select
        foi.order_item_id,
        foi.product_key,
        count(distinct bps.supplier_key) as supplier_count
    from join_lab.fact_order_item as foi
    join join_lab.bridge_product_supplier as bps
    on foi.product_key = bps.product_key
    and bps.preferred_supplier is True
    group by foi.order_item_id,
            foi.product_key
),
facts_table as (
    select
        foi.order_item_id,
        dp.product_key,
        sum(foi.units_ordered) as units_ordered,
        sum(foi.unit_price) as unit_price
    from join_lab.fact_order_item as foi
    join join_lab.dim_product as dp
    on dp.product_key = foi.product_key
    group by foi.order_item_id,
            dp.product_key
)
select
    ft.order_item_id,
    ft.product_key,
    ft.units_ordered,
    ft.unit_price,
    sc.supplier_count
from facts_table as ft
join supplier_count as sc
on ft.order_item_id = sc.order_item_id



--Drill 61: Revenue by supplier-count band
    --Investigate:
    select *
    from join_lab.bridge_product_supplier;
with supplier_count as (
    select
    product_key,
    count(supplier_key) as supplier_count
from join_lab.bridge_product_supplier
group by product_key
),
supp_structure as (
    select
        product_key,
        case
            when supplier_count = 1 then 'single supplier'
            when supplier_count > 1 then 'multi supplier'
            end as
        supplier_structure
    from supplier_count
)
select
    ss.supplier_structure,
    count(distinct foi.product_key) as distinct_products,
    count(distinct foi.order_id) as distinct_orders,
    count(foi.order_item_id) as order_item_count,
    sum(foi.units_ordered * foi.unit_price) as gross_order_value
from join_lab.fact_order_item as foi
join supp_structure as ss
on ss.product_key = foi.product_key
group by ss.supplier_structure





