--Drill 26: Global supplier quartiles
--Business scenario:
--Divide a supplier performance records into four approximately equal groups.
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    ntile(4) over(
        order by performance_score desc nulls last) as performance_quartile
from ranking_lab.supplier_performance
order by performance_quartile,
        performance_score desc nulls last
    ;
--The 1 quartile represents the highest performing suppliers because of use of desc

--Q: Does NTILE(4) guarantee that every supplier in the same quartile has an identical
--performance score?
--A: No it guarantees they are in the same bucket, same proportion based on the bucket


--Drill 27: Investigate quartile population
--Business scenario
--How many records fall into each quartile
with suppliers_buckets as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over(
            order by performance_score desc nulls last) as performance_quartile
from ranking_lab.supplier_performance
)
select
    performance_quartile,
    count(*) as record_count
from suppliers_buckets
group by performance_quartile
order by performance_quartile
    ;
--The buckets contains equal number of rows in each quartile

--When the number of records is not divisible by four, the extra number of rows is
--distributed by making the earlier quartile 1 larger than the rest of the quartile

--We use a CTE to first obtain the quartile/buckets then we use the result to obtain
--the number of records in each quartile


--Drill 28: Regional supplier quartiles
--Business scenario
--Procurement wants to evaluate supplier performance within each region, rather than
--across the entire supplier network
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    ntile(4) over (
        partition by region order by
        performance_score desc nulls last) as regional_quartile
from ranking_lab.supplier_performance
    ;
--Q: Can a supplier belong to global quartile 2 but regional quartile 1?
--A: Yes , a supplier can have the global quartile of 2 and a regional quartile of 1
--where each region has its own quartile distribution compared to where the quartile
--distribution is obtained against all suppliers


--Drill 29: Regional & monthly distribution
--Business scenario
--Evaluate supplier performance separately for every reporting month in each region
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    row_number() over (
        partition by region, reporting_month
        order by performance_score desc nulls last) as monthly_regional_ranking,
    ntile(3) over (
        partition by region, reporting_month
        order by performance_score desc nulls last) as performance_tercile
from ranking_lab.supplier_performance
    ;


--Drill 30: Investigate ties in ntile()
with supplier_quartiles as (
    select
        supplier_id,
        performance_score,
        ntile(4) over (
            order by performance_score desc nulls last
        ) as quartile
    from ranking_lab.supplier_performance
),
tie_investigation as (
    select
        performance_score,
        count(*) as record_count,
        count(distinct quartile) as distinct_quartiles,
        min(quartile) as min_quartile,
        max(quartile) as max_quartile
    from supplier_quartiles
    group by performance_score
)
select
    *
from tie_investigation
where distinct_quartiles > 1
order by performance_score desc nulls last;
--Their was no supplier with identical performance_score with different quartile assignments


--Drill 31: Global supplier percentile ranking
--Business scenario
--Measure where each performance record stands relative to the entire supplier
--performance population
with performance_percent_rank as (
    select
        supplier_id,
        region,
        performance_score,
        (percent_rank() over (
            order by performance_score desc nulls last)) * 100 as performance_percent_rank
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    performance_score,
    round(performance_percent_rank::numeric, 2) as performance_percent_rank
from performance_percent_rank
    ;
--Lowest performance_percent_rank shows the top performing suppliers where it represents
--the top tier performance(best performers with 0 percentile_rank) whereas the highest
--performance_percent_rank represents the lowest performers with 93.62% of all suppliers
--performing better / having a higher performance score than the current row(lowest supplier)



--Drill 32: Regional percentile ranking
--Business scenario
--Procurement wants percentile comparisons within individual regions
with regional_percentile_rank as (
    select
        supplier_id,
        region,
        performance_score,
        (percent_rank() over (
            partition by region order by
            performance_score desc nulls last)) * 100 as regional_pct_rank
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    performance_score,
    round(regional_pct_rank::numeric, 2) as regional_pct_rank
from regional_percentile_rank
    ;
--Yes, each region has its own percentile ranking thus identical performance score
--might still result to different percentile ranking



--Drill 33: Cumulative supplier distribution
--Business scenario
--What proportion of supplier  performance records have scored at least as high as
--a particular record
with supplier_cum_distribution as (
    select
        supplier_id,
        region,
        performance_score,
        cume_dist() over (
            order by performance_score desc nulls last) as cumulative_distribution
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    performance_score,
    round(cumulative_distribution::numeric * 100, 2) as cumulative_distribution_pct
from supplier_cum_distribution
    ;
--A row with a cumulative_distribution_pct of 75% means that 75% of all the values
--have a higher or equal performance score compared to the current row or value



--Drill 34: Compare three distribution functions
--Compare how different window functions represnt supplier performance
with supplier_metrics as (
    select
        supplier_id,
        region,
        performance_score,
        ntile(4) over (
            order by performance_score desc nulls last) as supplier_quartiles,
        percent_rank() over (
            order by performance_score desc nulls last) * 100 as percent_ranking,
        cume_dist() over (
            order by performance_score desc nulls last) * 100 as cumulative_distribution
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    performance_score,
    supplier_quartiles as supplier_quartiles,
    round(percent_ranking::numeric, 2) as percent_ranking,
    round(cumulative_distribution::numeric, 2) as cumulative_distribution
from supplier_metrics
    ;
--records with identical performance_score will not necessarily have the same value of
--all the three functions(quartiles, percent_ranking & cumulative distribution)


--Drill 35: Distribution engineering challenge
with distribution_calculations as (
    select
        supplier_id,
        region,
        performance_score,
        ntile(4) over (partition by region
            order by performance_score desc nulls last) as regional_quartile
    from ranking_lab.supplier_performance
),
supplier_classifications as (
    select
        supplier_id,
        region,
        performance_score,
        regional_quartile,
        case
            when performance_score is null then 'Non_rated'
            when regional_quartile = 1 then 'Excellent'
            when regional_quartile = 2 then 'Good'
            when regional_quartile = 3 then 'Needs improvement'
            else 'Critical'
        end as classification
    from distribution_calculations
),
regional_summary as (
    select
        region,
        classification,
        regional_quartile,
        count(supplier_id) as records_count,
        avg(performance_score) as avg_performance_score,
        min(performance_score) as min_performance_score,
        max(performance_score) as max_performance_score
    from supplier_classifications
    group by region,
            classification,
            regional_quartile
)
select
    region,
    classification,
    records_count,
    round(avg_performance_score,2) as avg_performance_score,
    min_performance_score,
    max_performance_score
from regional_summary
order by region,
        regional_quartile
        ;
--The classification sheds light on how the suppliers perform where we can compare the
--classification metrics of each region against each other

--We have given null values a classification to assess the number of records with
--null values from the dataset



with non_null_values as (
    select
        supplier_id,
        region,
        performance_score
    from ranking_lab.supplier_performance
    where performance_score is not null
),
distribution_calculations as (
    select
        supplier_id,
        region,
        performance_score,
        ntile(4) over (partition by region
            order by performance_score desc) as regional_quartile
    from non_null_values
),
supplier_classifications as (
    select
        supplier_id,
        region,
        performance_score,
        regional_quartile,
        case
            when regional_quartile = 1 then 'Excellent'
            when regional_quartile = 2 then 'Good'
            when regional_quartile = 3 then 'Needs improvement'
            else 'Critical'
        end as classification
    from distribution_calculations
),
null_values as (
    select
        supplier_id,
        region,
        performance_score,
        null::integer as regional_quartile,
        'Non_rated' as classification
    from ranking_lab.supplier_performance
    where performance_score is null
),
combined_values as (
    select
        supplier_id,
        region,
        performance_score,
        regional_quartile,
        classification
    from supplier_classifications
    union all
    select
        supplier_id,
        region,
        performance_score,
        null::integer as regional_quartile,
        classification
    from null_values
),
regional_summary as (
    select
        region,
        classification,
        regional_quartile,
        count(supplier_id) as records_count,
        avg(performance_score) as avg_performance_score,
        min(performance_score) as min_performance_score,
        max(performance_score) as max_performance_score
    from combined_values
    group by region,
            classification,
            regional_quartile
)
select
    region,
    classification,
    regional_quartile,
    records_count,
    round(avg_performance_score,2) as avg_performance_score,
    min_performance_score,
    max_performance_score
from regional_summary
order by region,
        regional_quartile
        ;
