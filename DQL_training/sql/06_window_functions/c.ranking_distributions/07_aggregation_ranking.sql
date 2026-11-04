--PART 5: ADVANCED PARTITIONING ENGINEERING
--Combining aggregation with ranking while controlling the analytical grain.

--Drill 21: National warehouse inventory leaderboard
--Business scenario:
--Identify which warehouses cities collectively hold the largest quantities of
--available inventory.

with warehouse_aggregate as (
    select
        warehouse_city,
        sum(available_units) as tot_available_units,
        count(inventory_id) as inventory_record_count
    from ranking_lab.warehouse_inventory
    group by warehouse_city
)
select
    warehouse_city,
    tot_available_units,
    inventory_record_count,
    rank() over (
        order by tot_available_units desc nulls last) as warehouse_rank
from warehouse_aggregate
    ;
--The source record is not aggregated and the business q is asking for national ranking
--1 row per inventory_id
--1 row per warehouse_city


--Drill 22: Product-category inventory rankings
--Compare product categories across its warehouse network
with categories_aggregate as (
    select
        warehouse_city,
        category,
        sum(available_units) as tot_category_units
    from ranking_lab.warehouse_inventory
    group by warehouse_city,
            category
)
select
    warehouse_city,
    category,
    tot_category_units,
    dense_rank() over (
        partition by warehouse_city order by
        tot_category_units desc nulls last) as inventory_rank
from categories_aggregate
    ;



--Drill 23: Regional supplier performance averages
--Evaluate overall performance of each region across all reporting months.
--Management wants to rank regions based on their average supplier performance scores.
--Create regional performance report
with regional_performance as (
    select
        region,
        avg(performance_score) as avg_performance_score,
        count(record_id) as evaluated_records
    from ranking_lab.supplier_performance
    where performance_score is not null
    group by region
)
select
    region,
    round(avg_performance_score, 2) as avg_performance_score,
    evaluated_records,
    rank() over (order by avg_performance_score desc nulls last) as performance_rank
from regional_performance
    ;



        --Investigative query
        select
            depot,
            sum(completed_deliveries) as tot_completed_deliveries
        from ranking_lab.fleet_delivery_performance
        group by depot;

        SELECT
            depot,
            SUM(completed_deliveries) AS total_deliveries,
            AVG(on_time_pct) AS average_on_time_pct,
            COUNT(*) AS driver_records
        FROM ranking_lab.fleet_delivery_performance
        GROUP BY depot
        ORDER BY depot;

--Drill 24: Fleet depot performance leaderboard.
--Business scenario:
--Compare depot-level performance across the national fleet

with aggregated_fleet as (
    select
        depot,
        sum(completed_deliveries) as tot_completed_deliveries,
        avg(on_time_pct) as avg_on_time_pct
    from ranking_lab.fleet_delivery_performance
    group by depot
)
select
    depot,
    tot_completed_deliveries,
    round(avg_on_time_pct, 2) as avg_on_time_pct,
    rank() over (order by tot_completed_deliveries desc) as delivery_volume_rank,
    dense_rank() over (order by avg_on_time_pct desc) as on_time_performance_rank
from aggregated_fleet
    ;
--we have a challenge where both ranking are all the same


        --Investigative query:
        select *
        from ranking_lab.supplier_performance;

--Drill 25: Integrated ranking engineering challenge
--Comprehensive supplier performance report
--Evaluate suppliers across regions & reporting months, while also understanding
--regional performance averages

--THE FIRST SET OF CTE IS IMPERFECT::TAKE NOTE
--The error with the below CTE is how the regional_average score is calculated
--We need to first change the grain to region, find the average score then rank them
                with regional_average as (
                    select
                        record_id,
                        supplier_id,
                        region,
                        reporting_month,
                        performance_score,
                        rank() over (partition by region, reporting_month order by
                                    performance_score desc nulls last) as regional_monthly_rank,
                        rank() over (partition by reporting_month
                            order by performance_score desc nulls last) as company_monthly_rank,
                        avg(performance_score) over (
                            partition by region) as regional_average_score
                    from ranking_lab.supplier_performance
                ),
                regional_average_grain_check as (
                    select
                        record_id,
                        count(*) as row_count
                    from regional_average
                    group by record_id
                    having count(*) > 1
                ),
                regional_ranking as (
                select
                    record_id,
                    supplier_id,
                    region,
                    reporting_month,
                    performance_score,
                    regional_monthly_rank,
                    company_monthly_rank,
                    regional_average_score,
                    rank() over (order by regional_average_score desc) as regional_average_rank
                from regional_average
                ),
                regional_ranking_grain_check as (
                    select
                        record_id,
                        count(*) as row_count
                    from regional_ranking
                    group by record_id
                    having count(*) > 1
                )
                select
                    record_id,
                    supplier_id,
                    region,
                    reporting_month,
                    performance_score,
                    regional_monthly_rank,
                    company_monthly_rank,
                    round(regional_average_score, 2) as regional_average_score,
                    regional_average_rank
                from regional_ranking
                    ;
--1 row per record_id
--1 row per record_id

--THIS IS THE CORRECTED VERSION OF THE CTE
with regional_average as (
    select
        region,
        avg(performance_score) as regional_average_score
    from ranking_lab.supplier_performance
    group by region
),

regional_ranking as (
    select
        region,
        regional_average_score,
        rank() over (
            order by regional_average_score desc nulls last
        ) as regional_average_rank
    from regional_average
),

supplier_ranking as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,

        rank() over (
            partition by region, reporting_month
            order by performance_score desc nulls last
        ) as regional_monthly_rank,

        rank() over (
            partition by reporting_month
            order by performance_score desc nulls last
        ) as company_monthly_rank

    from ranking_lab.supplier_performance
)

select
    srk.record_id,
    srk.supplier_id,
    srk.region,
    srk.reporting_month,
    srk.performance_score,
    srk.regional_monthly_rank,
    srk.company_monthly_rank,

    round(
        rrk.regional_average_score, 2
    ) as regional_average_score,

    rrk.regional_average_rank

from supplier_ranking as srk
--Because regional_ranking contains only one record per region, the join should
--not multiply supplier records
left join regional_ranking as rrk
    ON srk.region = rrk.region

ORDER BY
    srk.region,
    srk.reporting_month,
    srk.regional_monthly_rank,
    srk.record_id;

