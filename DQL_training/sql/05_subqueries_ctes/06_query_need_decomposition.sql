--OBJECTIVE:
--Design and make decisions on:
    --How many CTEs are needed
    --What each CTE should accomplish
    --What grain each CTE should maintain
    --What aggregation shouldm occur
    --Which joins are safe
    --How to validate results

--Drill 21: Executive revenue dashboard
--Business request:
--Finance needs report showing customer purchasing performance, including total revenue,
--number of orders, average order value and revenue contribution percentage.

--Expected output grain: 1 row per customer_key
with order_item_values as (
    select
        order_item_id,
        order_id,
        customer_key,
        sum(units_ordered * unit_price) over() as source_revenue,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
),
customer_order_revenue as (
    select
        order_id,
        customer_key,
        sum(item_revenue) as revenue
    from order_item_values
    group by order_id,
            customer_key
),
customer_metrics as (
    select
        customer_key,
        count(distinct order_id) as order_count,
        sum(revenue) as customer_revenue,
        avg(revenue) as average_revenue
    from customer_order_revenue
    group by customer_key
),
total_revenue as (
    select
        customer_key,
        order_count,
        customer_revenue,
        average_revenue,
        sum(customer_revenue) over() as customer_total_revenue
    from customer_metrics
),
revenue_contribution as (
    select
        customer_key,
        order_count as total_orders,
        customer_revenue as total_revenue,
        average_revenue as average_order_value,
        customer_total_revenue,
        (customer_revenue / nullif(
            customer_total_revenue, 0
        ) * 100) as revenue_contribution_pct
    from total_revenue
)
select
    customer_key,
    total_orders,
    total_revenue,
    round(average_order_value, 2) as average_order_value,
    round(revenue_contribution_pct, 2) as revenue_contribution_pct
from revenue_contribution
order by total_revenue desc;

--Comment: source_revenue = customer_total_revenue(revenue after customer aggregation)



--Drill 22: Product performance dashboard
--Business request:
--Merchandising wants to identify products generating the most revenue and understand
--their contribution to total sales
--Expected output grain: 1 row per product

with source_values as (
    select
        order_item_id,
        order_id,
        product_key,
        units_ordered,
        sum(units_ordered * unit_price) over() as source_overall_revenue,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
),
order_product_revenue as (
    select
        order_id,
        product_key,
        sum(units_ordered) as units_sold,
        sum(item_revenue) as revenue
    from source_values
    group by order_id,
            product_key
),
product_metrics as (
    select
        product_key,
        sum(units_sold) as units_sold,
        count(distinct order_id) as order_count,
        sum(revenue) as product_revenue,
        avg(revenue) as average_revenue
    from order_product_revenue
    group by product_key
),
product_ranking as (
    select
        product_key,
        units_sold,
        order_count,
        product_revenue,
        average_revenue,
        row_number() over(order by product_revenue desc) as revenue_rank,
        sum(product_revenue) over(
            order by product_revenue desc rows between unbounded preceding
            and current row) as running_revenue_total,
        sum(product_revenue) over () as overall_revenue
    from product_metrics
),
product_revenue_contribution as (
    select
        product_key,
        units_sold,
        order_count,
        product_revenue,
        average_revenue,
        revenue_rank,
        (product_revenue / nullif(
            overall_revenue, 0
        )) * 100 as revenue_contribution_pct,
        (running_revenue_total / nullif(
            overall_revenue, 0
        )) * 100 as cumulutive_revenue_contribution_pct
    from product_ranking
)
select
    product_key,
    units_sold,
    order_count,
    product_revenue,
    round(average_revenue, 2) as average_revenue,
    revenue_rank,
    round(revenue_contribution_pct, 2) as revenue_contribution_pct,
    round(cumulutive_revenue_contribution_pct, 2) as cumulutive_revenue_contribution_pct
from product_revenue_contribution



--Drill 23: Customer_revenue segmentation
--Business request:
--Marketing wants to identify high-value customers and understand how much revenue each
--customer segment contributes

--Expected output grain: 1 row per customer segment

with order_item_values as (
    select
        order_item_id,
        order_id,
        customer_key,
        sum(units_ordered * unit_price) over() as source_overall_revenue,
        (units_ordered * unit_price) as item_revenue
    from join_lab.fact_order_item
),
customer_revenue as (
    select
        customer_key,
        count(distinct order_id) as order_count,
        sum(item_revenue) as customer_revenue
    from order_item_values
    group by customer_key
),
customer_segment as (
    select
        customer_key,
        customer_revenue,
        case
            when customer_revenue >= 15000 then 'Platinum'
            when customer_revenue >= 12000 then 'Gold'
            when customer_revenue >= 7000 then 'Silver'
            else 'Bronze'
        end as segment,
        sum(customer_revenue) over() as overall_revenue
    from customer_revenue
),
segment_metrics as (
    select
        segment,
        count(customer_key) as customers_count,
        sum(customer_revenue) as revenue,
        avg(customer_revenue) as average_revenue
    from customer_segment
    group by segment
),
segment_summary as (
    select
        segment,
        customers_count,
        revenue,
        average_revenue,
        sum(revenue) over() as company_revenue
    from segment_metrics
),
segment_contribution as (
    select
        segment,
        customers_count,
        revenue,
        average_revenue,
        (revenue / nullif(
            company_revenue, 0
        )) * 100 as pct_contribution
    from segment_summary
)
select
    segment,
    customers_count,
    revenue,
    round(average_revenue, 2) as average_revenue,
    round(pct_contribution, 2) as segment_contribution_pct
from segment_contribution;



--Drill 24: Supplier relationship risk analysis
--Business request:
--Procurement wants to understand which products depend on multiple suppliers and
--how much sales revenue is associated with those products

--Expected output grain: 1 row per product_key
        --Investigate bridge_product_supplier grain
        select
            product_key,
            supplier_key,
            count(*) as row_count
        from join_lab.bridge_product_supplier
        group by product_key,
                supplier_key;

        select *
        from join_lab.bridge_product_supplier;

        select
            product_key,
            count(*) as row_count
        from join_lab.bridge_product_supplier
        group by product_key;

        select
            product_key,
            supplier_key,
            count(*) as row_count
        from join_lab.bridge_product_supplier
        where preferred_supplier is True
        group by product_key,
                supplier_key;

        select
            foi.product_key,
            bps.supplier_key,
            bps.preferred_supplier,
            sum(foi.units_ordered * foi.unit_price) over () as overall_revenue
        from join_lab.fact_order_item as foi
        left join join_lab.bridge_product_supplier as bps
        on bps.product_key = foi.product_key
        and bps.preferred_supplier is True
        order by supplier_key;


--In this drill, i have  dilemma of joining the two tables without causing a fanout,
--when i make the join safe by using preferrd_suppliers to be true, then it negates
--a product having more than one supplier.

--The solution to this is to aggregate each business independently at the product grain,
--then join the already-aggregated results

with product_revenues as (
    select
        product_key,
        sum(units_ordered * unit_price) as revenue
    from join_lab.fact_order_item
    group by product_key
),
suppliers_count_tbl as (
    select
        product_key,
        count(distinct supplier_key) as supplier_count
    from join_lab.bridge_product_supplier
    group by product_key
),
product_supplier_join as (
    select
        pr.product_key,
        coalesce(sct.supplier_count, 0) as supplier_count,
        pr.revenue
    from product_revenues as pr
    left join suppliers_count_tbl as sct
    on sct.product_key = pr.product_key
),
supplier_classification as (
    select
        product_key,
        supplier_count,
        revenue,
        case
            when supplier_count >= 2 then 'Multiple suppliers'
            when supplier_count = 1 then 'Single supplier'
            else 'No supplier'
        end as classification
    from product_supplier_join
)
select
    product_key,
    supplier_count,
    revenue,
    classification
from supplier_classification
where classification = 'Multiple suppliers'
    ;



--Drill 25: Final CTE engineering challenge
--Business scenario:
--The executive team wants to understand customer purchasing performance and revenue concentration.
--The report must identify the highest-value customers, calculate purchasing frequency, and
--classify customers according to revenue contribution

with order_item_values as (
    select
        order_item_id,
        order_id,
        units_ordered,
        customer_key,
        (units_ordered * unit_price) as order_revenue
    from join_lab.fact_order_item
),
customer_order_revenues as (
    select
        order_id,
        customer_key,
        sum(order_revenue) as revenues,
        sum(units_ordered) as units
    from order_item_values
    group by order_id,
            customer_key
),
customer_metrics as (
    select
        customer_key,
        count(distinct order_id) as order_count,
        sum(units) as total_units,
        sum(revenues) as total_revenues,
        avg(revenues) as avg_order_values
    from customer_order_revenues
    group by customer_key
),
customer_ranking as (
    select
        customer_key,
        order_count,
        total_units,
        total_revenues,
        avg_order_values,
        row_number() over(order by total_revenues desc, customer_key) as ranking,
        sum(total_revenues) over(
            order by total_revenues desc, customer_key rows between unbounded preceding and
            current row) as running_rev_tot,
        sum(total_revenues) over() as overall_revenues
    from customer_metrics
),
customer_segment as (
    select
        customer_key,
        order_count,
        total_units,
        total_revenues,
        avg_order_values,
        ranking,
        running_rev_tot,
        overall_revenues,
        case
            when total_revenues >= 15000 then 'Platinum'
            when total_revenues >= 12000 then 'Gold'
            when total_revenues >= 7000 then 'Silver'
            else 'Bronze'
        end as customer_segment
    from customer_ranking
),
customer_summary as (
    select
        customer_key,
        order_count,
        total_units,
        total_revenues,
        avg_order_values,
        ranking,
        (total_revenues / nullif(
            overall_revenues, 0
        )) * 100 as revenue_contribution_pct,
        (running_rev_tot / nullif(
            overall_revenues, 0
        )) * 100 as cumulative_revenue_pct,
        customer_segment
    from customer_segment
)
select
    customer_key,
    order_count as total_orders,
    total_units,
    total_revenues,
    round(avg_order_values, 2) as avg_order_values,
    ranking as customer_ranking,
    round(revenue_contribution_pct, 2) as revenue_contribution_pct,
    round(cumulative_revenue_pct, 2) as cumulative_revenue_pct,
    customer_segment
from customer_summary
    ;

--
