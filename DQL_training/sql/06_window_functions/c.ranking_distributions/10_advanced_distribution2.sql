--Drill 42: Supplier risk classification
--classify supplier performance observations into three risk categories according
--to their regional standing

with cumulative_non_null as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        cume_dist() over (
            partition by region order by
            performance_score desc)::numeric as cumulative_distribution
    from ranking_lab.supplier_performance
    where performance_score is not null
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    round(cumulative_distribution * 100, 2) as cumulative_distribution,
    case
        when cumulative_distribution <= 0.25 then 'Low_risk'
        when cumulative_distribution <= 0.75 then 'Moderate risk'
        else 'High risk'
    end as risk_classification
from cumulative_non_null



--Drill 43: Regional supplier risk summary
--Distribution of supplier performance categories across region

with cumulative_non_null as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        cume_dist() over (
            partition by region order by
            performance_score desc)::numeric as cumulative_distribution
    from ranking_lab.supplier_performance
    where performance_score is not null
),
supplier_classification as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        round(cumulative_distribution * 100, 2) as cumulative_distribution,
        case
            when cumulative_distribution <= 0.35 then 'Low risk'
            when cumulative_distribution <= 0.75 then 'Moderate'
            else 'High risk'
        end as risk_classification
    from cumulative_non_null
),
regional_metrics as (
    select
        region,
        risk_classification,
        count(distinct supplier_id) as supplier_record_count,
        avg(performance_score) as avg_performance_score,
        count(*) as record_count
    from supplier_classification
    group by region,
            risk_classification
),
risk_pct as (
    select
        region,
        risk_classification,
        supplier_record_count,
        avg_performance_score,
        record_count,
        sum(record_count) over (partition by region) as regional_record_count,
        (record_count * 100.0 / nullif(
            sum(record_count) over (partition by region), 0
        )) as performance_pctg
    from regional_metrics
)
select
    region,
    risk_classification,
    supplier_record_count,
    round(avg_performance_score, 2) as avg_performance_score,
    record_count,
    round(performance_pctg, 2) as performance_pctg
from risk_pct
order by region,
        avg_performance_score
        ;
--West has the highest performing suppliers class
--Because each region calculates its own cumulative distribution, a region can have a
--high share of low-risk observations without having the highest absolute performance
--scores.



--Drill 44: Monthly regional performance segmentation
--Supplier performance classifications evaluated separately for every
--reporting month
with quartile_non_null as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over (
            partition by region, reporting_month order by
            performance_score desc) as quartile
    from ranking_lab.supplier_performance
    where performance_score is not null
),
classification_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        quartile,
        case
            when quartile = 1 then 'Excellent'
            when quartile = 2 then 'Good'
            when quartile = 3 then 'Needs improvement'
            when quartile = 4 then 'Critical'
        end as classification
    from quartile_non_null
),
month_regional_metrics as (
    select
        region,
        reporting_month,
        classification,
        count(*) as record_count,
        avg(performance_score) as avg_performance_score,
        min(performance_score) as min_performance_score,
        max(performance_score) as max_performance_score
    from classification_tbl
    group by region,
            reporting_month,
            classification
)
select
    region,
    reporting_month,
    classification,
    record_count,
    round(avg_performance_score, 2) as avg_performance_score,
    min_performance_score,
    max_performance_score
from month_regional_metrics
order by region,
        reporting_month,
        classification
        ;
--Q: Can the same supplier performance score receive different
--classifications in different reporting months?
--Because each region has it's own cumulative distribution, a region can have
--a higher share of low risk observations without having the highest absolute scores



--Drill 45: Advanced distribution engineering challenge
with non_null_values as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score
    from ranking_lab.supplier_performance
    where performance_score is not null
),
distribution_calculations as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over (partition by region, reporting_month
            order by performance_score desc) as regional_quartile,
        percent_rank() over (partition by region, reporting_month
        order by performance_score desc)::numeric * 100 as percent_ranking,
        cume_dist() over (
            partition by region, reporting_month
            order by performance_score desc)::numeric * 100 as cumulative_distro
    from non_null_values
),
quartile_classification as (
    select
        supplier_id,
        region,
        reporting_month,
        case
            when regional_quartile = 1 then 'Excellent'
            when regional_quartile = 2 then 'Good'
            when regional_quartile = 3 then 'Needs improvement'
            else 'Critical'
        end as classification,
        performance_score,
        regional_quartile,
        percent_ranking,
        cumulative_distro
    from distribution_calculations
),
null_values as (
    select
        supplier_id,
        region,
        reporting_month,
        'Non_rated' as classification,
        performance_score,
        null::integer as regional_quartile,
        null::numeric as percent_ranking,
        null::numeric as cumulative_distro
    from ranking_lab.supplier_performance
    where performance_score is null
),
    combined_tbl as (
    select
        supplier_id,
        region,
        performance_score,
        reporting_month,
        classification,
        regional_quartile,
        percent_ranking,
        cumulative_distro
    from quartile_classification
    union all
    select
        supplier_id,
        region,
        performance_score,
        reporting_month,
        classification,
        regional_quartile,
        percent_ranking,
        cumulative_distro
    from null_values
),
regional_monthly_summary as (
    select
        region,
        reporting_month,
        classification,
        count(*) as record_count,
        round(avg(performance_score), 2) as avg_performance_score,
        min(performance_score) as min_performance_score,
        max(performance_score) as max_performance_score
    from combined_tbl
    group by region,
            reporting_month,
            classification
),
quality_reporting as (
    select
        region,
        reporting_month,
        count(*) as total_records,
        count (*) filter (where performance_score is not null) as rated_records,
        count(*) filter (where performance_score is null) as non_rated_records,
        round(count(*) filter (
            where performance_score is null) * 100.0 / nullif(
                count(*), 0
            ), 2) as non_rated_pctg
    from combined_tbl
    group by region,
            reporting_month
),
quality_aggregate as (
    select
        source_count,
        combined_count,
        source_count - combined_count as record_difference
from (
    select
        (select count(*)
    from ranking_lab.supplier_performance) as source_count,

        (select count(*)
    from combined_tbl) as combined_count
)
)
select
    rms.region,
    rms.reporting_month,
    rms.classification,
    rms.record_count,
    rms.avg_performance_score,
    rms.min_performance_score,
    rms.max_performance_score,
    qrt.total_records,
    qrt.rated_records,
    qrt.non_rated_records
from regional_monthly_summary as rms
left join quality_reporting as qrt
    on qrt.region = rms.region
    and qrt.reporting_month = rms.reporting_month
order by rms.region,
        rms.reporting_month,
        rms.classification
    ;

    --Q: What is the grain of the detailed classified dataset?
--1 row per record_id
    --Q: What is the grain of the monthly summary?
--1 row per region per reported_month per classification
    --Q: Why should missing scores be excluded from distribution calculations?
--Because they distort thr results of distribution functions
    --Q: Why do we use UNION ALL instead of UNION?
--to preserve all null values from all subqueries
    --Q: Can suppliers with identical scores receive different quartile classifications?
--Classification were made from regional_quartile which might have occassions where
--identical performance_score might have different quartiles hence suppliers with
--identical performance_score can have different classifications
    --Q: How would you ensure deterministic quartile assignments?
--Using "desc" in the order by window function
    --Q: What limitations should management understand before interpreting relative
    --supplier classifications as absolute performance quality?
--Their might be cases where identical performance_score might still be in different
--class
