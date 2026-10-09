--Block A: Establish the mental model
-Drill 1: Overall average unit price
select
    round(avg(unit_price), 2) as overall_average_unit_price
from join_lab.fact_order_item;
--Table level summary grain/ scalar summary
--The result returns 1 row



--Drill 2: Orders priced above the overall average
select
    order_item_id,
    order_id,
    product_key,
    unit_price
from join_lab.fact_order_item
where unit_price > (
    select
        avg(unit_price)
    from join_lab.fact_order_item
);
--Scalar subquery refers to one value result from the inner query



--Drill 3: Compare every item with the global average
select
    order_item_id,
    unit_price,
    round((
        select
            avg(unit_price)
        from join_lab.fact_order_item
    ), 2) as overall_average,
    round(unit_price - (
        select
            avg(unit_price)
        from join_lab.fact_order_item
    ), 2) as price_difference
from join_lab.fact_order_item;



-- Block B: Multi-row subqueries
--Drill 4: Discover products in a category
    --Investigate table:
    select *
    from join_lab.dim_product;

select
    product_key,
    product_name,
    category
from (
    select
        *
    from join_lab.dim_product
    where category = 'Safety'
) as safety_category
    ;



--Drill 5: Fact rows belonging to those products
select
    foi.order_item_id,
    foi.order_id,
    foi.product_key,
    foi.units_ordered,
    foi.unit_price
from join_lab.fact_order_item as foi
where foi.product_key in (
    select
        product_key
    from join_lab.dim_product
    where category = 'Safety'
);
--  Using = in the subquery would be inappropriate because the subquery output is multirows
--whereas = expects a scalar(1 row 1 column) output.



--Block C: Subqueries in from
--Drill 6: Calculate revenue by order
--Expected grain: 1 row per order_id
select
    order_id,
    sum(units_ordered * unit_price) as order_revenue
from join_lab.fact_order_item
group by order_id;



--Drill 7: Average order value
select
    round(avg(order_revenue), 2) as average_order_revenue
from (
    select
        order_id,
        sum(units_ordered * unit_price) as order_revenue
    from join_lab.fact_order_item
    group by order_id
) as order_revenue
    ;
--Inner query grain: 1 row per order_id
--Outer query grain: one summary row for the complete derived result



--Drill 8: High-value orders
select
    order_id,
    sum(units_ordered * unit_price) as order_revenue
from join_lab.fact_order_item
group by order_id
having sum(units_ordered * unit_price) > (
    select
        avg(order_revenue) as average_order_revenue
    from (
        select
            order_id,
            sum(units_ordered * unit_price) as order_revenue
        from join_lab.fact_order_item
        group by order_id
    ) as order_totals
)


--Block D: Correlated subqueries
--Drill 9: Products that have been ordered
select
    product_key,
    product_name
from join_lab.dim_product as dp
where  exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.product_key = dp.product_key
);

--The risk of using the query design below is that where product_key from fact table returns
-- null, it will result to "unknown" value, in which case use of exists is encouraged
select
    product_key,
    product_name
from join_lab.dim_product as dp
where dp.product_key in (
    select
        foi.product_key
    from join_lab.fact_order_item as foi
);



--Drill 10: products never ordered
select
    product_key,
    product_name
from join_lab.dim_product as dp
where  not exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.product_key = dp.product_key
);



--Block E: Correlated aggregation
--Drill 11: Items priced above their product's average
select
    foi.order_item_id,
    foi.product_key,
    foi.unit_price,
    (
        select
            round(avg(f.unit_price), 2)
        from join_lab.fact_order_item as f
        where f.product_key = foi.product_key
    ) as product_average_unit_price
from join_lab.fact_order_item as foi
where foi.unit_price > (
    select
        round(avg(f.unit_price), 2)
    from join_lab.fact_order_item as f
    where f.product_key = foi.product_key
);



--Block F: Nested business logic
--Drill 12: Orders above average total revenue

--Stage 1
--Calculate revenue per order.

--Stage 2
--Calculate average revenue from those order-level results.

--Stage 3
--Return orders whose revenue exceeds that average.

select
    order_id,
    sum(units_ordered * unit_price) as order_revenue
from join_lab.fact_order_item
group by order_id
having sum(units_ordered * unit_price) > (
    select
        round(avg(order_revenue), 2) as average_order_revenue
    from (
        select
            order_id,
            sum(units_ordered * unit_price) as order_revenue
        from join_lab.fact_order_item
        group by order_id
    )
);



--Drill 13: Products used by multiple orders
select
    dp.product_key,
    dp.product_name
from join_lab.dim_product as dp
where dp.product_key in (
    select
        foi.product_key
    from join_lab.fact_order_item as foi
    group by foi.product_key
    having count(distinct foi.order_id) > 1
);

--Alternatively:
select
    dp.product_key,
    dp.product_name
from join_lab.dim_product as dp
where exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.product_key = dp.product_key
    group by foi.product_key
    having count(distinct foi.order_id) > 1
);



--Block G: Exists vs data retrieval
--Drill 14: Customers / entities with qualifying activity
    --Investigate fact table
    with customer_ordered_units as (
    select
        customer_key,
        sum(units_ordered) as units_ordered
    from join_lab.fact_order_item
    group by customer_key
    )
    select
        min(units_ordered) as min_units_ordered,
        max(units_ordered) as max_units_ordered,
        round(avg(units_ordered), 2) as avg_units_ordered
    from customer_ordered_units
        ;

select
    dc.customer_key,
    dc.customer_name,
    dc.customer_segment,
    dc.province
from join_lab.dim_customer as dc
where exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.customer_key = dc.customer_key
    having sum(foi.units_ordered) < 60
);

--  EXISTS evaluates whether the correlated subquery returns at least one row.
-- Values selected inside that subquery are not returned to the outer result.



--Block H: Anti-join reasoning
--Drill 15: Orphan-style detection
select
    ds.customer_key,
    ds.customer_name,
    ds.customer_segment
from join_lab.dim_customer as ds
where not exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.customer_key = ds.customer_key
)

-- Show me every customer for whom no order-item fact record exists.



--Block I: The "not in" null trap
--Drill 16A
select
    *
from join_lab.dim_product
where product_key not in (
    select
        foi.product_key
    from join_lab.fact_order_item as foi
);


--Drill 16B:
select
    *
from join_lab.dim_product as dp
where not exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.product_key = dp.product_key
);


--Drill 16C: Explain the mystery
--When subquery results is null, this can create problems as it will give back the result
--unknown unless the sql logic result for comparison is true or false. As a result of this,
--non-existance problems is always suitable to use not exists as opposed to not in.




--Block J: Diagnose the broken query.
--Drill 17:
        --Erroneous query
        SELECT
            order_item_id,
            product_key,
            unit_price
        FROM join_lab.fact_order_item
        WHERE product_key = (
            SELECT product_key
            FROM join_lab.dim_product
        );

--Explanations for the errors in the query.
--1. What does the outer query expect?
-- The outer query expects a scalar value
--2. What shape can the inner query return?
--The inner query returns multirow column
--3. Why are those incompatible?
--The outer query expects a scalar value whereas the inner query gives back multirow column
--Use of = expects a scalar value.
--4. What operator might be appropriate if the business requirement
--   is "products that exist in dim_product"?
--product_key avaliablity in the fact table

select
    order_item_id,
    product_key,
    unit_price
from join_lab.fact_order_item
where product_key in (
            select
                product_key
            from join_lab.dim_product
        );


--Block K: Choose the correct subquery type
--Drill 18:
--Scalar
--Brings back the overall average unit price which is a single value

--Drill 19:
--Multirow
--"In a selected category", meaning the output needed is a column, with multiple rows
--(fact items belonging to the selected category)


--Drill 20:
--table like
--The result of the inner query returns a single value for each order made from the main table
--Each order bring back a specific average order value using the condition
--where that compares orders from the main table to the inner query calculated orders


--Drill 21:
--Existence test
--Checks the qualification of products from the fact table by comparing to the orders
--from the dimension table


--Drill 22:
--Table like
--Brings back the average price of each order item calculated in the inner query



--Block L:
--Drill 23: Above average products with actual activity
select
    dp.product_key,
    dp.product_name,
    (
        select
            round(avg(unit_price), 2)
        from join_lab.fact_order_item as foi
        where foi.product_key = dp.product_key
    ) as product_avg_unit_price,
    (
        select
            round(avg(unit_price), 2)
        from join_lab.fact_order_item
    ) as overall_avg_unit_price
from join_lab.dim_product as dp
where exists (
    select
        1
    from join_lab.fact_order_item as foi
    where foi.product_key = dp.product_key
) and
(
    select
        avg(unit_price)
    from join_lab.fact_order_item as foi
    where foi.product_key = dp.product_key
) > (
    select
        avg(unit_price)
    from join_lab.fact_order_item
)
