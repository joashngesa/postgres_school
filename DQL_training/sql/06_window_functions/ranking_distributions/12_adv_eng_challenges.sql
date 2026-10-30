--Drill 51: Supplier performamnce distribution audit
--Management wants evidence that supplier quartile assignments are valid & reproducible.
with quartile_tbl as (
    select
        record_id,
        supplier_id,
        region,
        performance_score,
        ntile(4) over (
            partition by region order by performance_score desc) as quartile
    from ranking_lab.supplier_performance
    where performance_score is not null
),
splits_tbl as (
    select
        region,
        performance_score
    from quartile_tbl
    group by region,
            performance_score
    having count(distinct quartile) > 1
)
select
    qtl.region,
    count(*) as rated_records,
    count(distinct qtl.performance_score) as distinct_scores,
    count(distinct qtl.quartile) as quartiles_present,
    count(distinct spt.performance_score) as split_ties_scores
from quartile_tbl as qtl
left join splits_tbl as spt
    on spt.region = qtl.region
    and spt.performance_score = qtl.performance_score
group by qtl.region
    ;
--it insinuates that identical performance score are assigned to different quartiles
--among the regions thus inspection is needed per region to observe the repeated
--times the performance score has appeared more than once among the regions in the table



--Drill 52: Supplier performance: Absolute vs relative measures
--Procurement wants to identify suppliers whose relative performance classification
--looks strong but whose absolute performance score is below an agreed threshold

with suppliers_quartile as (
    select
        supplier_id,
        region,
        performance_score,
        ntile(4) over (
            partition by region order by
            performance_score desc) as regional_quartile
    from ranking_lab.supplier_performance
    where performance_score is not null
)
select
    supplier_id,
    region,
    performance_score,
    regional_quartile
from suppliers_quartile
where regional_quartile = 1
    and performance_score <= 80
    ;
--A supplier can lead in regional partition but still fall back when compared
--against the whole population. Regional quartiles are compared per region
--thus the overall performance might be different.



--Drill 53: Distribution function selection
--The procurement department wants exactly 10 records per region whenever at least
--10 records exist.
--Performance department wants the 10 highest distinct performers_score ranks per
--region including ties
--Analytics department wants observations with cume_dist() < 0.10 in each region

with ranking_distribution_tbl as (
    select
        supplier_id,
        region,
        performance_score,
        row_number () over (
            partition by region order by supplier_id, record_id) as row_ranking,
        rank() over (
            partition by region order by
            performance_score desc) as ranking,
        cume_dist() over (partition by region order by
            performance_score desc) as cum_distribution
    from ranking_lab.supplier_performance
    where performance_score is not null
),
--needed only 10 existing records per region with no specification on performances
procurement_tbl as (
    select
        supplier_id,
        region,
        performance_score,
        row_ranking as regional_ranking
    from ranking_distribution_tbl
    where row_ranking <= 10
),
--used rank because of tied scores and need to rate the 10 best performers
performance_dpt as (
    select
        supplier_id,
        region,
        performance_score,
        ranking as performance_ranking
    from ranking_distribution_tbl
    where ranking <= 10
)
--Analytics table
--the is suitable to get the top tier performers
select
    supplier_id,
    region,
    performance_score,
    cum_distribution as cumulative_distribution
from ranking_distribution_tbl
where cum_distribution <= 0.10



--Drill 54: Regional supplier ranking quality dashboard
--Regional analytical quality report

with regional_tbl as (
    select
        region,
        count(*) as tot_records,
        count(*) filter (
            where performance_score is not null) as rated_records,
        count(*) filter (
            where performance_score is null) as unrated_records,
        avg(performance_score) as avg_performance_score,
        max(performance_score) as max_performance_score,
        min(performance_score) as min_performance_score,
        count(distinct supplier_id) filter (
            where performance_score is not null) as rated_suppliers_count
    from ranking_lab.supplier_performance
    group by region
)
select
    region,
    tot_records,
    rated_records,
    unrated_records,
    round(unrated_records * 100.0 / nullif(
        tot_records, 0), 2) as unrated_pctg,
    round(avg_performance_score, 2) as avg_performance_score,
    min_performance_score,
    max_performance_score,
    rated_suppliers_count
from regional_tbl
    ;
-- Q:Explain why a region with many missing performance scores might produce an apparently
-- strong average performance score
--When calculating the average, null values are excluded in the calculation, thus i do
--not understand why it affects the average score positevely, explain the answer



--Drill 55: Final engineering challenge
with source_data as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score
    from ranking_lab.supplier_performance
),
rated_suppliers as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score
    from source_data
    where performance_score is not null
),
ranking_calculations as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        row_number() over (partition by region, reporting_month
            order by performance_score desc, record_id) as row_number_rank,
        rank() over (partition by region, reporting_month
            order by performance_score desc) as rank_position,
        dense_rank() over (partition by region, reporting_month
            order by performance_score desc) as dense_rank_position,
        ntile(4) over (partition by region, reporting_month
            order by performance_score desc) as performance_quartile,
        percent_rank() over (partition by region, reporting_month
            order by performance_score desc) as percentile_ranking,
        cume_dist() over (partition by region, reporting_month
            order by performance_score desc) as cumulative_distribution
    from rated_suppliers
),
unrated_suppliers as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        null::integer as row_number_rank,
        null::integer as rank_position,
        null::integer as dense_rank_position,
        null::integer as performance_quartile,
        null::integer as percentile_ranking,
        null::integer as cumulative_distribution
    from source_data
    where performance_score is null
),
combined_tbl as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        row_number_rank,
        rank_position,
        dense_rank_position,
        performance_quartile,
        percentile_ranking,
        cumulative_distribution
    from ranking_calculations
    union all
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        row_number_rank,
        rank_position,
        dense_rank_position,
        performance_quartile,
        percentile_ranking,
        cumulative_distribution
    from unrated_suppliers
),
record_reconciliation as (
    select
        (select
            count(*)
        from ranking_lab.supplier_performance) as source_count,
        count(*) as transformed_count,
        count(distinct record_id) as unique_transformed_records
    from combined_tbl
),
supplier_classification as (
    select
        record_id,
        supplier_id,
        region,
        reporting_month,
        performance_score,
        row_number_rank,
        rank_position,
        dense_rank_position,
        performance_quartile,
        percentile_ranking,
        cumulative_distribution,
        case
            when performance_score is null then 'Non rated'
            when performance_quartile = 1 then 'Excellent'
            when performance_quartile = 2 then 'Good'
            when performance_quartile = 3 then 'Needs improvement'
            else 'Critical'
        end as classification
    from combined_tbl
),
regional_monthly_summary as (
    select
        region,
        reporting_month,
        classification,
        count(*) as record_count,
        avg(performance_score) as avg_performance_score,
        min(performance_score) as min_performance_score,
        max(performance_score) as max_performance_score
    from supplier_classification
    group by region,
            reporting_month,
            classification
),
quality_report as (
    select
        region,
        reporting_month,
        count(*) as tot_records,
        count(*) filter (where performance_score is not null) as rated_records,
        count(*) filter (where performance_score is null) as unrated_records,
        round(count(*) filter (
            where performance_score is null) * 100.0 / nullif(
                count(*), 0), 2) as unrated_pctg
    from supplier_classification
    group by region,
            reporting_month
)
select
    rms.region,
    rms.reporting_month,
    rms.classification,
    rms.record_count,
    round (rms.avg_performance_score, 2) as avg_performance_score,
    rms.min_performance_score,
    rms.max_performance_score,
    qrp.rated_records,
    case
        when rms.classification = 'Non rated' then qrp.unrated_records
        else 0
    end as unrated_records,
    case
        when rms.classification = 'Non rated' then qrp.unrated_pctg
        else 0
    end as unrated_pctg
from regional_monthly_summary as rms
join quality_report as qrp
    on qrp.region = rms.region
    and qrp.reporting_month = rms.reporting_month
order by region,
        reporting_month


