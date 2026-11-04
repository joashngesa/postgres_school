--Drill 36: Identify the top 25% of supplier records
--Identify the highest performing 25% of supplier performance observations
with quartile_data as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over (order by performance_score desc) as quartile
from ranking_lab.supplier_performance
where performance_score is not null
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    quartile
from quartile_data
where quartile = 1
    ;
--Selecting quartile 1 returns 25% of the population.
--When the data is not divisible by four, the early values will have one added value
--more than the rest



--Drill 37: Regional bottom quartile investigation
--Identify the lowest ranked quartile of supplier performance observations within
--each region
with regional_quartile as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over (
            partition by region order by
            performance_score desc) as quartile
    from ranking_lab.supplier_performance
    where performance_score is not null
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    quartile
from regional_quartile
where quartile = 4
order by region,
        performance_score
    ;
--The quartile are created using desc thus the 4th quartile represent values with
--least performance_score(the suppliers with the lowest performance_score group)



--Drill 38: Regional performance distribution summary
--Regional dashboard showing how supplier performance records are distributed across
--quartiles
with performance_quartile as (
    select
        supplier_id,
        region,
        performance_score,
        ntile(4) over (
            partition by region order by
            performance_score desc) as quartile
    from ranking_lab.supplier_performance
    where performance_score is not null
),
regional_metrics as (
    select
        region,
        quartile,
        count(*) as record_count
    from performance_quartile
    group by region,
            quartile
),
quartile_aggregate as (
    select
        region,
        quartile,
        record_count,
        sum(record_count) over (partition by region) as regional_record_count
    from regional_metrics
),
region_pct as (
    select
        region,
        quartile,
        record_count,
        regional_record_count,
        (record_count * 100.0 / nullif(
            regional_record_count, 0)) as pct_of_region
    from quartile_aggregate
),
quartile_pct_approval as (
    select
        region,
        sum(pct_of_region) as pct_sum
    from region_pct
    group by region
)
select
    region,
    quartile,
    record_count,
    regional_record_count,
    round(pct_of_region, 2) as pct_of_region
from region_pct
    ;
--we used the regional population as the deniminator as we are finding the percentage
--in each region separately.



--Drill 39: Supplier performance threshold investigation
--Identify performance observations belonging to the highest ranked 20% of the
--supplier network, using a percentile-rank cutoff rather than quartiles
with non_null_values as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score
    from ranking_lab.supplier_performance
    where performance_score is not null
),
percentile_rank as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        (percent_rank() over (
            order by performance_score
            desc))::numeric * 100 as percent_ranking
    from non_null_values
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    round(percent_ranking, 2) as percent_ranking
from percentile_rank
where percent_ranking <= 20
    ;
--Drill 36 brings back the a quartile of the population (25%) while the above drill
--brings back 20% percentile of the top performance score suppliers



--Drill 40: Regional cumulative performance distribution
--cumulative distribution of supplier performance within each region
with non_null_values as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score
    from ranking_lab.supplier_performance
    where performance_score is not null
),
cumulative_distribution as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        (cume_dist() over (partition by region order by
            performance_score desc))::numeric as cumulative_distro,
        ntile(2) over (
            partition by region order by performance_score desc) as regional_quartile
    from non_null_values
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    round(cumulative_distro, 2) as cumulative_distro,
    cumulative_distro <= 0.50 as selected_cumulative_distro,
    regional_quartile,
    regional_quartile = 2 as selected_ntile
from cumulative_distribution
order by region, performance_score desc
    ;
--'ntile(4)' divides records into approximately equal proportions even in cases where
--tied scores cross quartiles. Whereas 'cume_dist' preserve ties and includes entire
--peer group in its cumulative calculation



--Drill 41: Compare regional distribution metrics
--Compare 3 measures of supplier performance distribuition
with non_null_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score
    from ranking_lab.supplier_performance
    where performance_score is not null
),
distribution_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over (
            partition by region order by
            performance_score desc) as quartile,
        (percent_rank() over (
            partition by region order by
            performance_score desc))::numeric * 100 as percent_ranking,
        (cume_dist() over (
            partition by region order by
            performance_score desc))::numeric * 100 as cumulative_ranking
    from non_null_tbl
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    quartile,
    quartile = 1 as selected_by_ntile,
    round(percent_ranking, 2) as percent_ranking,
    percent_ranking < 25 as selected_by_percent_rank,
    round(cumulative_ranking, 2) as cumulative_ranking,
    cumulative_ranking <= 25 as selected_by_cume_dist
from distribution_tbl
where quartile = 1
    or percent_ranking < 25
    or cumulative_ranking < 25
    ;
