--STAGE C3: Multi Stage Analytics
--Drill 16: Customer revenue development classification
--The commercial department wants to classify customers according to the evolution of
--their recorded revenue.
select * from ranking_lab.customer_order_metrics order by customer_id, reporting_month

with revenue_records_tbl as (
    select
        customer_id,
        reporting_month,
        net_revenue,
        first_value(net_revenue) over (partition by customer_id order by
            reporting_month) as first_revenue,
        last_value(net_revenue) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as last_revenue,
        last_value(net_revenue) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) -
                    first_value(net_revenue) over (partition by customer_id order by
            reporting_month) as revenue_change
    from ranking_lab.customer_order_metrics
),
revenue_classification_tbl as (
    select
        customer_id,
        reporting_month,
        net_revenue,
        first_revenue,
        last_revenue,
        revenue_change,
        case
            when revenue_change is null then 'Insufficient data'
            when revenue_change > 0 then 'Growing'
            when revenue_change = 0 then 'Stable'
            when revenue_change < 0 then 'Declining'
        end as classification
    from revenue_records_tbl
)
select
    customer_id,
    reporting_month,
    net_revenue,
    first_revenue,
    last_revenue,
    revenue_change,
    classification
from revenue_classification_tbl
order by customer_id,
        reporting_month
    ;



--Drill 17: Depot level driver performance investigation
--Transportation management wants to compare the first and latest average on-time
--performance of its operating depots

with depot_tbl as (
    select
        depot,
        reporting_month,
        avg(on_time_pct) as avg_on_time_pct
    from ranking_lab.fleet_delivery_performance_history
    group by depot,
            reporting_month
),
window_function_depo_tbl as (
    select
        depot,
        reporting_month,
        first_value(reporting_month) over (partition by depot order by
            reporting_month) as first_reporting_month,
        last_value(reporting_month) over (partition by depot order by
            reporting_month rows between unbounded preceding
                and unbounded following) as latest_reporting_month,
        first_value(avg_on_time_pct) over (partition by depot order by
            reporting_month) as first_avg_on_time_pct,
        last_value(avg_on_time_pct) over (partition by depot order by
            reporting_month rows between unbounded preceding
                and unbounded following) as last_avg_on_time_pct
    from depot_tbl
)
select distinct
    depot,
    first_reporting_month,
    latest_reporting_month,
    round(first_avg_on_time_pct, 2) as first_avg_on_time_pct,
    round(last_avg_on_time_pct, 2) as latest_avg_on_time_pct,
    round(last_avg_on_time_pct - first_avg_on_time_pct, 2) as performance_change
from window_function_depo_tbl
    ;
--The aim is to get the earliest average first value of on_time_pct, getting first_value
--(on_time_pct) gets the on_time_pct of the table in the first position of the partition
--selected

--1 row per depot & reporting_month

--add distinct to the final table and drop the reported month column



--Drill 18: Supplier improvement leaderboard
--The procurement director wants to identify suppliers showing the greatest improvement
--between their earliest and latest recorded performance evaluations.
--Preserve the distinction between missing performance values and valid scores of zero

--Suppliers whose first or latest scores are NULL must be excluded from the
--improvement ranking, but retained in the report as unranked suppliers
        --Investigate table
        select
            count(*) as row_count,
            count(distinct record_id) as record_id_count,
            count(distinct supplier_id) as supplier_count
        from ranking_lab.supplier_performance;

with performance_score_ranking as (
    select
        supplier_id,
        reporting_month,
        performance_score,
        count(*) over (partition by supplier_id) as valid_observation_counts,
        first_value(performance_score) over (partition by supplier_id order by
            reporting_month) as first_performance_score,
        last_value(performance_score) over (partition by supplier_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as latest_performance_score
    from ranking_lab.supplier_performance
),
supplier_improvement_tbl as (
    select distinct
        supplier_id,
        first_performance_score,
        latest_performance_score,
        case
            when valid_observation_counts > 1 then
            latest_performance_score - first_performance_score
            else null
        end as performance_change
    from performance_score_ranking
),
valid_supplier_ranking as (
    select
        supplier_id,
        first_performance_score,
        latest_performance_score,
        performance_change,
        dense_rank() over (order by performance_change desc) as improvement_rank
    from supplier_improvement_tbl
    where performance_change is not null
)
select
    sit.supplier_id,
    sit.first_performance_score,
    sit.latest_performance_score,
    sit.performance_change,
    vsr.improvement_rank
from supplier_improvement_tbl as sit
left join valid_supplier_ranking as vsr
    on vsr.supplier_id = sit.supplier_id
    ;
--row_number ranks the suppliers with identical scores differently whereas our instruction
--was to give the same ranking to suppliers with identical scores

--because we want to rank the suppliers in the table against each other

--yes beacuse if desc is included in the order by frame in the window function the scores
--will be arranged from top to least making the null values positioned first which alters
--the intended business meaning




--Drill 19: Fleet performance consistency investigation
--The transportation analytics department wants to determine whether drivers are
--improving consistently or showing signs of performance deterioration.

        --Investigate table
        select
            count(*) as row_count,
            driver_id,
            reporting_month
        from ranking_lab.fleet_delivery_performance_history
        group by driver_id,
                reporting_month
        having count(*) > 1 ;

with on_time_pct_metrics as (
    select
        driver_id,
        depot,
        on_time_pct,
        count(*) over (partition by driver_id) as driver_count,
        first_value(on_time_pct) over (partition by driver_id order by
            reporting_month) as first_on_time_pct,
        nth_value(on_time_pct, 2) over (partition by driver_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as second_on_time_pct,
        nth_value(on_time_pct, 3) over (partition by driver_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as third_on_time_pct,
        last_value(on_time_pct) over (partition by driver_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as latest_on_time_pct,
        last_value(on_time_pct) over (partition by driver_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) - first_value(
                    on_time_pct) over (partition by driver_id order by
                        reporting_month) as total_change
    from ranking_lab.fleet_delivery_performance_history
),
classification_tbl as (
    select distinct
        driver_id,
        depot,
        first_on_time_pct,
        second_on_time_pct,
        third_on_time_pct,
        latest_on_time_pct,
        total_change,
        case
            when driver_count < 4 then 'Insufficient data'
            when first_on_time_pct is null then 'Insufficient data'
            when second_on_time_pct is null then 'Insufficient data'
            when third_on_time_pct is null then 'Insufficient data'
            when latest_on_time_pct is null then 'Insufficient data'
            when first_on_time_pct < second_on_time_pct and
                second_on_time_pct < third_on_time_pct and
                third_on_time_pct < latest_on_time_pct then 'Consistent improvement'
            when first_on_time_pct > second_on_time_pct and
                second_on_time_pct > third_on_time_pct and
                third_on_time_pct > latest_on_time_pct then 'Consitetent deterioration'
            when first_on_time_pct = second_on_time_pct and
                second_on_time_pct = third_on_time_pct and
                third_on_time_pct = latest_on_time_pct then 'Stable'
            else 'Fluctuating'
        end as performance_pattern
    from on_time_pct_metrics
)
select
    performance_pattern,
    count(distinct driver_id) as driver_count,
    count(*) as class_count
from classification_tbl
group by performance_pattern
    ;
--All the drivers have consistent improvement because in all records their is a
--constant increase between all the on_time_pct columns from the first to latest



--Drill 20: Customer revenue lifecycle analysis
--Business scenario:
--The commercial analytics director wants a customer lifecycle report.

--The objective is to understand how customers progress from their first recorded
--revenue observation through subsequent reporting periods.

--The report will support customer retention analysis and revenue development
--monitoring

        --Investigate table
        select * from ranking_lab.customer_order_metrics;

        select
            count(*) as row_count,
            count(distinct customer_id) as customer_count,
            count(distinct reporting_month) as months_count
        from ranking_lab.customer_order_metrics;

        select
            customer_id,
            reporting_month,
            market,
            count(*) as row_count
        from ranking_lab.customer_order_metrics
        group by customer_id,
                reporting_month,
                market
        having count(*) > 1;

with table_calculations as (
    select
        customer_id,
        net_revenue,
        first_value(reporting_month) over (partition by customer_id order by
            reporting_month) as first_month,
        last_value(reporting_month) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as latest_month,
        first_value(net_revenue) over (partition by customer_id order by
            reporting_month) as first_revenue,
        nth_value(net_revenue, 2) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as second_revenue,
        nth_value(net_revenue, 3) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as third_revenue,
        last_value(net_revenue) over (partition by customer_id order by
            reporting_month rows between unbounded preceding
                and unbounded following) as latest_revenue,
        count(*) over (partition by customer_id) as customers_count
    from ranking_lab.customer_order_metrics
),
growth_pct as (
    select distinct
        customer_id,
        first_month,
        latest_month,
        first_revenue,
        second_revenue,
        third_revenue,
        latest_revenue,
        customers_count,
        latest_revenue - first_revenue as absolute_growth,
        round(100.00 * (latest_revenue - first_revenue) / nullif(
            first_revenue, 0), 2) as growth_pct
    from table_calculations
),
classification_tbl as (
    select
        customer_id,
        first_month,
        latest_month,
        first_revenue,
        second_revenue,
        third_revenue,
        latest_revenue,
        customers_count,
        absolute_growth,
        growth_pct,
        case
            when customers_count < 3 then 'Early lifecycle'
            when first_revenue is null or
                latest_revenue is null then 'Insufficient data'
            when growth_pct >= 50 then 'High growth'
            when growth_pct > 0 then 'Moderate growth'
            when growth_pct = 0 then 'Stable'
            when growth_pct < 0 then 'Declining'
            else 'Unclassified'
        end as classification
    from growth_pct
),
source_count_tbl as (
    select
        count(distinct customer_id) as source_customers
    from ranking_lab.customer_order_metrics
),
report_count_tbl as (
    select
        count(*) as final_rows,
        count(distinct customer_id) as final_customers
    from classification_tbl
),
count_summary_tbl as (
    select
        source_customers,
        final_rows,
        final_customers,
        source_customers = final_rows as row_count_matches,
        source_customers = final_customers as customer_count_matches
    from source_count_tbl
    cross join report_count_tbl
),
classification_coverage_tbl as (
    select
        classification,
        count(*) as customer_count
    from classification_tbl
    group by classification
)
select
    customer_id,
    first_month,
    latest_month,
    first_revenue,
    second_revenue,
    third_revenue,
    latest_revenue,
    customers_count,
    absolute_growth,
    growth_pct,
    classification
from classification_tbl
order by customer_id
    ;
--1. Why must the source observation grain be preserved until after the positional
--window calculations?
--Collapsing the grain into more granular grain of the table will distort the meaning
--of the window functions

--2. What would happen if you grouped by customer before calculating NTH_VALUE()?
--each customer will be represented once and measurements aggregated thus finding the
--nth value becomes impossible

--3. Why is COUNT(*) OVER (PARTITION BY customer_id) useful in this analysis?
--It tells the total number of each customer's observations, showing the number of
--transactions for each customer

--4. Could a customer have positive absolute growth but an undefined growth percentage?
--yes, when the first revenue is 0, the absolute growth will be positive even though
--the growth percentage is undefined.

--5. What validation would demonstrate that the final report has not introduced
--duplicate customers?
--When the distinct number of customers count in the source table is same as
--customers count in the final table

--6. How would your approach change if the requirement were to produce one row per
--customer-market rather than one row per customer?
--Add market to the window function partition
