--LEVEL 2: BLOCK A: RANKING FUNDAMENTALS
--Drills 1-10: Understanding ranking behaviour.
--Business scenario:
--You are a data engineer working for a multinational logistics company. The procurement
--department needs a supplier performance leaderboard.

select *
from ranking_lab.supplier_performance;

--Drill 1: Basic supplier row numbering
--Write a query that assigns a unique sequential number to every supplier performance record

select
    supplier_id,
    region,
    performance_score,
    row_number() over (order by performance_score desc) as row_number
from ranking_lab.supplier_performance
    ;
--suppliers with identical score recieve different row_numbers


--Drill 2: Supplier ranking with gaps
select
    supplier_id,
    region,
    performance_score,
    rank() over (order by performance_score desc nulls last) as ranking
from ranking_lab.supplier_performance
    ;
--When suppliers tie, they share the same ranking and the next supplier is ranked
--by a number that skips all the identical supplier


--Drill 3: Supplier ranking without gaps
select
    supplier_id,
    region,
    performance_score,
    dense_rank() over (order by performance_score desc nulls last) as ranking
from ranking_lab.supplier_performance
    ;
--When suppliers tie, they share the same ranking and the next supplier is ranked
--based on the subsequent ranking number


--Drill 4: Compare three ranking functions
select
    supplier_id,
    region,
    performance_score,
    row_number() over (order by performance_score desc nulls last) as row_number,
    rank() over (order by performance_score desc nulls last) as supplier_rank,
    dense_rank() over (order by performance_score desc nulls last) as supplier_dense_rank
from ranking_lab.supplier_performance
    ;

--The difference in results is caused by difference in performance score


--Drill 5: Understand the effect of null values
--Investigate how PostgreSQL ranks suppliers whose performance score is null
select
    supplier_id,
    region,
    performance_score,
    rank() over (order by performance_score desc) as ranking
from ranking_lab.supplier_performance
    ;
--1. Nulls appear at the beginning of the table
--2. NO, Nulls appear at the top when using desc, which arranges the data from top
--ranking to the least
--3. We can place nulls last by using "nulls last" after desc in the window function
--4. This is crucial because if nulls are not places last, they will be ranked first


--Drill 6: Regional supplier ranking
--Compare suppliers within their respective regions, not across the entire company
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    rank() over (
        partition by region order by performance_score desc nulls last) as ranking
from ranking_lab.supplier_performance
    ;
--When a supplier appears in multiple reporting months, they are ranked based on the
--each region
--Does this query answer a monthly supplier ranking question correctly?
--No, the partition used for the query is region



--Drill 7: Monthly regional ranking
--Correct the business grain issue identified in grain 6
select
    region,
    reporting_month,
    supplier_id,
    performance_score,
    dense_rank() over(
        partition by region, reporting_month order by performance_score desc nulls last) as ranking
from ranking_lab.supplier_performance
    ;
--The result is more suitable for monthly regional report as it groups the ranking based
-- on regional & monthly records.



--Drill 8: Ranking ties investigations
--Identify all supplier performance records that share a performance score with another
--supplier within the same region and reporting month.
with identical_suppliers as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        count(*) over (
            partition by region, reporting_month,
            performance_score) as identical_metrics_count
    from ranking_lab.supplier_performance
    where performance_score is not null
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    identical_metrics_count
from identical_suppliers
where identical_metrics_count > 1
order by region,
        reporting_month,
        performance_score desc,
        supplier_id
    ;


--Drill 9: Deterministic row numbering
--The procurement department wants a reproducible ordering of supplier records
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    row_number() over (
        partition by region, reporting_month order by
        performance_score desc nulls last, supplier_id desc) as ranking
from ranking_lab.supplier_performance
order by region,
        reporting_month,
        ranking asc
        ;
--A secondary ordering column makes ROW_NUMBER() deterministic only when the complete
--ordering expression uniquely identifies the rows within the partition.


--Drill 10: The ranking comparison challenge
select
    region,
    reporting_month,
    supplier_id,
    performance_score,
    row_number() over (partition by region, reporting_month
            order by performance_score desc nulls last,
            supplier_id asc) as row_number_ranking,
    rank() over (partition by region, reporting_month
            order by performance_score desc nulls last) as rank_ranking,
    dense_rank() over (partition by region, reporting_month
            order by performance_score desc nulls last) as dense_rank_ranking
from ranking_lab.supplier_performance
    ;
--Row_number() does not need supplier_id additional column to preserve business ties
--because the ranking does not skip ranking number as rank() & desnse_rank() does.


--Drill 10a: Deterministic ranking
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    row_number() over (
        partition by region, reporting_month order by
        performance_score desc nulls last, supplier_id asc) as ranking
from ranking_lab.supplier_performance
    ;
--the window ordering can use a secondary column such as supplier_id to enforce
--deterministic row_numbering where performance score are identical


--Drill 10b: Preserving business ties.
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    rank() over (partition by region, reporting_month order by
            performance_score desc nulls last) as rank_ranking,
    dense_rank() over (partition by region, reporting_month order by
            performance_score desc nulls last) as dense_ranking
from ranking_lab.supplier_performance
    ;
--using supplier_id nullifies preserving business ties where the ranking is identical


--Drill 10c: Business tie investigation
with identical_suppliers as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        count(*) over (
            partition by region, reporting_month,
            performance_score) as tie_count
    from ranking_lab.supplier_performance
    where performance_score is not null
)
select
    region,
    reporting_month,
    supplier_id,
    performance_score,
    tie_count
from identical_suppliers
where tie_count > 1
order by region,
        reporting_month,
        performance_score desc,
        supplier_id
    ;
--Using count preserves the individual supplier records whereas group alone would
--change the grain of the table to the columns included in the group
