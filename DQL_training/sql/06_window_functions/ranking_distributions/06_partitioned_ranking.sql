--LEVEL 2 : BLOCK B
--PARTITIONED RANKING ENGINEERING

--Mission Objective:
--Become confident ranking operational records across multiple business dimensions
--while preserving the correct analytical grain.

--Drill 11: Warehouse inventory ranking
--Scenario: A national distribution company operates warehouses across Canada. We need
--to identify which warehouses hold the greatest quantity of stock
select *
from ranking_lab.warehouse_inventory;

--Task:
--Rank inventory records according to quantity_on_hand, highest first.
--The column product_id does not exist in the table, i have used inventory_id instead
select
    inventory_id,
    warehouse_city,
    category as product_category,
    available_units as quantity_on_hand,
    rank() over (partition by warehouse_city order by
            available_units desc nulls last) as inventory_rank
from ranking_lab.warehouse_inventory
    ;
--This query ranks inventory units in each warehouse separately, focussing on
--inventory units ranking in each respective warehouse

--This query does not focuss on the total national inventory levels, it ranks inventory
--units within each warehouse


--Drill 12: Product category ranking within warehouses
--Scenario: Warehouse managers want to understand which products carry the highest
--inventory quantities within their respective product categories
--They want comparisons within the same warehouse and category.
select
    inventory_id,
    warehouse_city,
    category as product_category,
    available_units as quantity_on_hand,
    dense_rank() over (partition by warehouse_city, category order by
                available_units desc nulls last) as dense_ranking
from ranking_lab.warehouse_inventory
    ;
--Partition by warehouse_city only ranks the available units based on warehouse_city
--whereas adding category ranks the inventory units levels according to each warehouse_city
-- & the category.

--Adding category aids replenishment decisions as it informs which city and the categories
--that need urgent replenishments


        --Investigative query
        select *
        from ranking_lab.fleet_delivery_performance;
--Drill 13: Fleet delivery performance ranking
--Scenario:
--A national logistics company wants to evaluate driver performance across its
--distribution depots
--The company's operations team uses an on-time delivery percentage to compare drivers
select
    driver_id,
    depot,
    on_time_pct,
    rank() over (partition by depot order by on_time_pct desc nulls last) as ranking
from ranking_lab.fleet_delivery_performance
    ;
--They will still get the same rating because the ranking was solely based on on_time_pct

            --Investigative query:
            select
                customer_id,
                count(*) as row_count
            from ranking_lab.customer_order_metrics
            group by customer_id;

--Drill 14: Customer spending ranking
--Scenario:
--The commercial analytics team wants customer revenue leaderboards for each market
--Rank customers within their markets based on the total revenue
select
    customer_id,
    market,
    net_revenue,
    dense_rank() over (partition by market order by net_revenue desc) as dense_ranking
from ranking_lab.customer_order_metrics
    ;
--If customers in different markets have identical revenue, should they receive the same rank?
--They will have different ranking as the ranking is within each market
--B. What happens to ranking values when the market changes?
--Ranking starts off from 1
--C. Would using PARTITION BY customer_id answer the business requirement?
--This ranks each customer spending within each customer, the ranking would be based on
--individual customer spending


--Drill 15: Warehouse inventory: Comparing ranking functions
--Scenario: The national inventory director wants to investigate how different ranking methods
--classify product inventory records
        --Investigative query
        select *
        from ranking_lab.warehouse_inventory;

select
    warehouse_city,
    category,
    inventory_id,
    available_units as quantity_on_hand,
    row_number() over (partition by warehouse_city, category order by
                available_units desc nulls last,
                inventory_id asc) as row_number_ranking,
    rank() over (partition by warehouse_city, category order by
                available_units desc nulls last) as rank_ranking,
    dense_rank() over (partition by warehouse_city, category order by
                available_units desc nulls last) as dense_ranking
from ranking_lab.warehouse_inventory
order by
    warehouse_city,
    category,
    row_number_ranking
    ;



--PART 3: Business Grain Engineering
--Drill 16: Monthly supplier performance leaderboard
--Scenario:
--The procurement department wants a monthly performance leaderboard for suppliers
--operating across different regions.
            --Investigative query
            select *
            from ranking_lab.supplier_performance;

--Each supplier should be compared only against suppliers in the same geographical
--region during the same reporting month
select
    region,
    reporting_month,
    supplier_id,
    performance_score,
    rank() over (partition by region, reporting_month order by
                performance_score desc nulls last) as supplier_rank
from ranking_lab.supplier_performance
order by region,
        reporting_month
    ;
--Without reporting_month in PARTITION BY, supplier performance records from different
--months compete within the same regional ranking.


            select *
            from ranking_lab.fleet_delivery_performance;
--Drill 17: Fleet performance across reporting periods
--Scenario:
--A logistics company wants to evaluate driver performance separately for every depot
--and reporting period
--Drivers should compete only against other drivers from the same depot during the same
--reporting period
select
    driver_id,
    depot,
    completed_deliveries,
    on_time_pct,
    dense_rank() over (partition by depot order by on_time_pct desc) as ranking
from ranking_lab.fleet_delivery_performance
    ;
--Their is no reporting period in the table. This limits the scope of query result
--by limiting the ranking among drivers only within depots.



--Drill 18: Customer revenue ranking by market and segment
--Scenario: The commercial analytics wants to identify its highest revenue customers.
--Customers should be compared against other customers in the same market and customer
--segment
            select *
            from ranking_lab.customer_order_metrics;
select
    customer_id,
    market,
    net_revenue as revenue,
    dense_rank() over (partition by market order by net_revenue desc) as ranking
from ranking_lab.customer_order_metrics
    ;
--The table does not have a segment column



--Drill 19: Warehouse inventory ranking investigation
            select *
            from ranking_lab.warehouse_inventory;
select
    inventory_id,
    warehouse_city,
    category,
    available_units,
    rank() over (partition by warehouse_city, category order by
                available_units desc nulls last) as inventory_rank
from ranking_lab.warehouse_inventory
    ;
--The first query was comparing inventory records separately within each warehouse
--whereas the corrected query compares inventory records withihn each category at
--every warehouse.


--Drill 20: Multi-function partitioning challenge.
--Scenario:
--The procurement department wants a detailed monthly supplier ranking report.
with source_tbl as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        on_time_rate
    from ranking_lab.supplier_performance
),
regional_monthly_ranking as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        rank() over (partition by region, reporting_month order by
                performance_score desc nulls last) as regional_monthly_rank
    from source_tbl
),
company_monthly_rank as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        regional_monthly_rank,
        rank() over (partition by reporting_month order by
                performance_score desc nulls last) as company_monthly_ranking
    from regional_monthly_ranking
),
overall_ranking as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        regional_monthly_rank,
        company_monthly_ranking,
        rank() over (
            order by performance_score desc nulls last) as overall_rank
    from company_monthly_rank
)
select
    record_id,
    supplier_id,
    region,
    reporting_month,
    performance_score,
    regional_monthly_rank,
    company_monthly_ranking,
    overall_rank
from overall_ranking
    ;
--The supplier performance is ranked within each month report at every region, the
--other ranks supplier performance within each month, the third ranks supplier
--performance across all records.

--Overall ranking as it ranks all suppliers across the entire company

--regional monthly ranking as it ranks suppliers within each region in each month.

--No, it does not need any partitioning as the ranking is done across the entire
--suppliers records.


