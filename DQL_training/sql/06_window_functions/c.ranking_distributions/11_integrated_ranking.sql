--Drill 46: Supplier_ranking _consistency
--Compare ranking methods to investigate how tied scores affect supply positions
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        row_number() over (partition by region
            order by performance_score desc) as row_number_ranking,
        rank() over (partition by region
            order by performance_score desc) as rank_ranking,
        dense_rank() over (partition by region
            order by performance_score desc) as ds_rank_ranking
    from ranking_lab.supplier_performance
    where performance_score is not null
    ;

--row_number ranking assigns different ranking to tied scores, whereas ranking & dense_ranking
--assign same ranking to tied scores. However, ranking skips the preceding value by the number
--of identical values whereas dense_ranking does not skip preceding ranking assigned.
--If our goal is to assign all identical scores to the same ranking, then dense_ranking
--/ ranking is most suitable



--Drill 47: Regional supplier top performance records
--Leaderboard of the 5 highest rank supplier performance observations in every region
--In the exercise below i gave different versions of the answer, combined & singular tables

with row_number_ranking as (
    select
        record_id,
        supplier_id,
        region,
        performance_score,
        row_number() over (
            partition by region order by
            performance_score desc, supplier_id) as rn_ranking
    from ranking_lab.supplier_performance
    where performance_score is not null
),
top_5_row_ranking as (
    select
        record_id,
        supplier_id,
        region,
        performance_score,
        rn_ranking
    from row_number_ranking
    where rn_ranking <= 5
),
dense_ranking_tbl as (
    select
        record_id,
        supplier_id,
        region,
        performance_score,
        dense_rank() over (
            partition by region order by
            performance_score desc) as dense_ranking
    from ranking_lab.supplier_performance
    where performance_score is not null
),
dense_top_5_tbl as (
    select
        record_id,
        supplier_id,
        region,
        performance_score,
        dense_ranking
    from dense_ranking_tbl
    where dense_ranking <= 5
)
select
    rnr.record_id,
    rnr.supplier_id,
    rnr.region,
    rnr.performance_score,
    rnr.rn_ranking,
    rnr.rn_ranking <= 5 as rn_ranking_selected,
    drt.dense_ranking,
    drt.dense_ranking <= 5 as dense_ranking_selected
from row_number_ranking as rnr
join dense_ranking_tbl as drt
    on rnr.record_id = drt.record_id
where rnr.rn_ranking <= 5
    or drt.dense_ranking <= 5
    ;
--Version A produces exactly top 5 suppliers whereas version B produces more than 5



--Drill 48: Warehouse inventory distribution
--Classify inventory records according to their available units
with non_null_values as (
    select
        inventory_id,
        warehouse_city,
        category,
        available_units
    from ranking_lab.warehouse_inventory
    where available_units is not null
)
select
    inventory_id,
    warehouse_city,
    category,
    available_units,
    ntile(4) over (
        partition by warehouse_city order by available_units desc) as inventory_quartile
from non_null_values
order by warehouse_city,
        category
        ;
--Create a CTE containing null values and later on combine it with the non_null table

--Quartile 1 indicates highest inventory volume which does not necessarily mean healthy
--inventory levels. Healthy levels are determined by available units vs demand.




--Drill 49: Warehouse inventory ranking by category
--Compare product-category inventory across its warehouse cities
with non_null_tbl as (
    select
        warehouse_city,
        category,
        sum(available_units) as tot_available_units
    from ranking_lab.warehouse_inventory
    where available_units is not null
    group by warehouse_city,
            category
    order by warehouse_city,
            category
)
select
    warehouse_city,
    category,
    tot_available_units,
    dense_rank() over (
        partition by warehouse_city order by
        tot_available_units desc) as units_available_dense_ranking,
    percent_rank() over (
        partition by warehouse_city order by
        tot_available_units desc) * 100.0 as units_percent_ranking
from non_null_tbl
    ;
--Ranking after aggregating category allows us to rank the category in the table,
--when individual values are used for ranking they will have different ranking
--as the values of individual records are different from aggregated records.

--When ranking individual records, the business meaning would change from category
--ranking partitions such as ranking for each warehouse to ranking of
--all records in all warehouses



--Drill 50: Global vs regional supplier classification
--Identify performance observations that appear relatively strong within their region
--but less competitive globally.
with non_null_values as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score
    from ranking_lab.supplier_performance
    where performance_score is not null
),
quartile_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        ntile(4) over (order by performance_score desc) as global_quartile,
        ntile(4) over (
            partition by region order by
            performance_score desc) as regional_quartile
    from non_null_values
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    global_quartile,
    global_quartile = 1 as glob_quartile_selected,
    regional_quartile,
    regional_quartile = 1 as reg_quartile_selected
from quartile_tbl
where global_quartile > 1
    and regional_quartile = 1
    ;
--Global quartile inform the management of the overall top performing suppliers across
--all the business population(all suppliers) whereas regional quartile inform of the topo
--performing suppliers in each region.

--The report should not be used to automatically penalize suppliers as sometimes identical
--performance score might be assigned to different quartiles, the quartile is based on
--relative positioning against the population and not individual value

