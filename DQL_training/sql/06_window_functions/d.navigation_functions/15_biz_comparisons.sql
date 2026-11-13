--Drill 11: Customer revenue change
--Measure the change in customer revenue between successive recorded reporting months
with previous_revenue as (
    select
        customer_id,
        market,
        reporting_month,
        net_revenue,
        lag(net_revenue) over (
            order by reporting_month, customer_id) as previous_revenue
    from ranking_lab.customer_order_metrics
)
select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    previous_revenue,
    net_revenue - previous_revenue as revenue_change
from previous_revenue
    ;
--Q1: What does a negative revenue_change indicate?
-- When previous_revenue is more than the current revenue

--Q2. Can we confidently describe every comparison as month-over-month growth?
-- No, the output we get in the table is dependent in what is reported, it does not
--necessarily represent consecutive month order

--Q3. Why should we retain records where previous_revenue is NULL?
--The first previous record value will always be null as their is no previous record


12: Customer revenue % change
--Measure customer revenue growth as a % of the preceding recorded revenue
with revenue_change as (
    select
        customer_id,
        market,
        reporting_month,
        net_revenue,
        lag(net_revenue) over (
            order by reporting_month, customer_id) as previous_revenue,
        net_revenue - lag(net_revenue) over (
            order by reporting_month, customer_id) as revenue_change
    from ranking_lab.customer_order_metrics
)
select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    previous_revenue,
    revenue_change,
    round(100.0 * (revenue_change) / nullif (
        previous_revenue, 0), 2) as revenue_change_pct
from revenue_change
    ;
--Q1. What happens when previous revenue equals zero?
-- Use of nullif allows it to bring back null

--Q2. Is a revenue change of +500 necessarily more impressive than a change of +100?
-- Not necessarily, sometimes it can be reflected due to record adjustments, record
--changes, or other reasons that could cause changes in records

--Q3. Why might the percentage change be NULL even when the current revenue is not null?
-- when the preceding value is the first current_revenue or the preceding value is null
--or zero


select * from ranking_lab.supplier_performance order by performance_score;
--Drill 13: Supplier performance classification
--Classify suppliers based on changes in their performance scores
with performance_change as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        lag(performance_score) over (partition by region
            order by performance_score) as previous_score_performance,
        (performance_score - lag(performance_score) over (partition by region
            order by performance_score))::numeric as score_change
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    previous_score_performance,
    score_change,
    case
        when score_change is null then 'Not comparable'
        when previous_score_performance  is null then 'Not comparable'
        when score_change > 0 then 'Improved'
        when score_change < 0 then 'Declined'
        when (performance_score = previous_score_performance) then 'Unchanged'
    end as classification
from performance_change
    ;
--Q1. Why should missing previous scores not automatically be classified as declines?
--Missing scores indicate scores that are not available for recording hence should not
--conclude as a decline
--Q2. Q2. What happens if the previous score exists but is NULL?
--record as not comparable as the value does not provide value we can measure or calculate
--against
--Q3. How does the business interpretation differ between score_change = 0 and
--score_change IS NULL?
--0 explains that their is no difference between previous and current value while null
--indicates that of one or both of the values has no available number to calculate against

select * from ranking_lab.inventory_snapshots;

    select
        snapshot_id,
        count(*) as row_number
    from ranking_lab.inventory_snapshots
    group by snapshot_id
    having count(*) > 1;



--Drill 14: Inventory change between observations
--The warehouse operations team wants to compare inventory quantities between successive
--observation timestamps.
--Construct a query that compares inventory quantities between successive observation
--timestamps for each warehouse-SKU combination.

with ranked_snapshot as (
    select
        snapshot_id,
        sku,
        warehouse_city,
        observed_at,
        source_revision,
        available_units,
        row_number() over (partition by warehouse_city, sku, observed_at
            order by source_revision desc, snapshot_id desc) as ranking
    from ranking_lab.inventory_snapshots
),
highest_source_revision as (
    select
        warehouse_city,
        sku,
        observed_at,
        source_revision,
        available_units,
        ranking
    from ranked_snapshot
    where ranking = 1
)
select
    warehouse_city,
    sku,
    observed_at,
    source_revision,
    available_units,
    lag(available_units) over (partition by warehouse_city, sku
        order by observed_at asc) as previous_observation_units,
    available_units - lag(available_units) over (partition by warehouse_city, sku
        order by observed_at asc) as units_change
from highest_source_revision
    ;
--Q1. Why would directly applying LAG() to the raw snapshot table potentially produce
--misleading results?
--It would include all rows as opposed to only returning highest source_revision
--Q2. What is the grain after selecting the latest revision?
--still the same as the raw table, 1 row per snapshot_id
--Q3. Can a negative units_change establish that products were sold or shipped?
--Not necessarily, this are the latest records, the reason for the change might defer


--Drill 15: Identify customer revenue declines
--Customer retention team wants a list of customer_market reporting records where
--revenue declined compared with the preceding recorded observation.
with revenue_change as (
    select
        customer_id,
        market,
        reporting_month,
        net_revenue,
        lag(net_revenue) over (partition by market
            order by reporting_month, customer_id) as previous_revenue,
        (lag(net_revenue) over (partition by market
            order by reporting_month, customer_id)) - net_revenue as revenue_change
    from ranking_lab.customer_order_metrics
),
improved_customer_tbl as (
    select
        customer_id,
        market,
        reporting_month,
        net_revenue,
        previous_revenue,
        revenue_change
    from revenue_change
    where net_revenue < previous_revenue
)
select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    previous_revenue,
    revenue_change,
    round((100.00 * revenue_change) / nullif (
        previous_revenue, 0), 2) as revenue_change_pct
from improved_customer_tbl
order by net_revenue desc
    ;
--Q1. Why can filtering the input table before computing LAG() produce incorrect results?
--We need the previous_revenue to calculate the filter
--Q2. Should a customer with no previous revenue be included?
--No, because we are examining customer retention
--Q3. Is the largest absolute revenue decline necessarily the largest percentage decline?
--No, the difference between current & previous might be small compared to the absolute value



--Drill 16: Consecutive supplier performance declines
--Investigate sustained performance deterioration
--Identify supplier_region reporting records where the performance score is lower than
--both of the two preceding recording recorded scores
with previous_scores_tbl as (
    select
        supplier_id,
        region,
        reporting_month,
        performance_score,
        lag(performance_score, 2) over (partition by supplier_id, region order by
            reporting_month, supplier_id) as score_two_records_ago,
        lag(performance_score) over (partition by supplier_id, region order by
            reporting_month, supplier_id) as previous_score
    from ranking_lab.supplier_performance
)
select
    supplier_id,
    region,
    reporting_month,
    performance_score,
    score_two_records_ago,
    previous_score
from previous_scores_tbl
where score_two_records_ago is not null
    and previous_score is not null
    and score_two_records_ago > previous_score
    and previous_score > performance_score
    ;
--Q1. How many recorded observations are required to establish two consecutive declines?
--3, the current & and the two preceding observations
--Q2. Would the following scores qualify?  90 → 85 → 85
--No, the last two observations are identical, no reduction experienced
--No null values would qualify
--No, we can not conclude decline in consecutive months



--Drill 17: Fleet delivery performance comparison
--Compare delivery performance between adjacent fleet records within each depot
    select * from ranking_lab.fleet_delivery_performance;

with comparison_tbl as (
select
    driver_id,
    depot,
    completed_deliveries,
    on_time_pct,
    lag(on_time_pct) over (
        partition by depot order by
        on_time_pct desc) as previous_on_time_pct,
    lag(completed_deliveries) over (
        partition by depot order by
        completed_deliveries desc) as previous_completed_delivery
from ranking_lab.fleet_delivery_performance
)
select
    driver_id,
    depot,
    completed_deliveries,
    on_time_pct,
    previous_on_time_pct,
    (on_time_pct - previous_on_time_pct) as on_time_pct_change,
    previous_completed_delivery,
    (completed_deliveries - previous_completed_delivery) as completed_deliveries_change
from comparison_tbl
    ;
    --we are evaluating on_time_pct performance between depot and completed_deliveries
    --among the depot. The higher the on_time_pct the better the performance, ordering
    --consequently with completed deliveries, the higher it is the better the performance



--Drill 18: Customer reporting gap detection
--Identify records immidiately following a gap in monthly reporting
select * from ranking_lab.customer_order_metrics;

with reporting_month_tbl as (
    select
        customer_id,
        market,
        reporting_month,
        lag(reporting_month) over (partition by market, customer_id
            order by reporting_month) as previous_reporting_month
    from ranking_lab.customer_order_metrics
),
missing_months_tbl as (
    select
        customer_id,
        market,
        reporting_month,
        previous_reporting_month,
        case
            when previous_reporting_month is null then null
            else (extract(year from age(
                reporting_month, previous_reporting_month
            )) * 12 +
            extract(month from age(
                reporting_month, previous_reporting_month
            )) - 1)
        end as missing_months
    from reporting_month_tbl
)
select
    customer_id,
    market,
    reporting_month,
    previous_reporting_month,
    missing_months
from missing_months_tbl
where missing_months > 0
    ;
    --


--Drill 19: Inventory change classification
--Classify inventory changes between successive observations.
--Use latest revision for each warehouse SKU observation combination

with revision_tbl as (
    select
        warehouse_city,
        sku,
        observed_at,
        available_units,
        source_revision,
        row_number() over (partition by warehouse_city, sku, observed_at
            order by source_revision desc, snapshot_id desc) as ranking
    from ranking_lab.inventory_snapshots
),
highest_revision_tbl as (
    select
        warehouse_city,
        sku,
        observed_at,
        available_units,
        source_revision,
        ranking
    from revision_tbl
    where ranking = 1
),
previous_observations as (
    select
        warehouse_city,
        sku,
        observed_at,
        available_units,
        source_revision,
        lag(available_units) over (partition by warehouse_city, sku order by
            observed_at asc) as previous_observation_units,
        available_units - lag(available_units) over (partition by warehouse_city, sku order by
            observed_at asc) as units_change
    from highest_revision_tbl
)
select
    warehouse_city,
    sku,
    observed_at,
    available_units,
    source_revision,
    previous_observation_units,
    units_change,
    case
        when previous_observation_units is null then 'Not comparable'
        when available_units is null then 'Not comparable'
        when previous_observation_units = available_units then 'Unchanged'
        when units_change > 0 then 'Increased'
        else 'Decreased'
    end as classification
from previous_observations
    ;
--Q1. What is the difference between a revised observation and a new observation?
--A revised observation is another version or correction of an observation referring
--to the same business observation timestamp. A new observation refers to a different
--business observation timestamp.
--Q2. Why must revision selection happen before computing the previous observation's
--inventory?
--So that we can always check the previous record within the selected values
--Q3. Could a decrease in recorded available units represent a data correction rather
-- than a physical inventory movement?
--yes.


select * from ranking_lab.shipment_exceptions;
--Drill 20: Independent supply chain investigation
--Repeated shipment exceptions. Investigate the available exception records & develop
--a meaningful comparison using navigation functions
        --Inspect table
        select
            count(*) as tot_row_count,
            count(distinct exception_id) as exception_id_count,
            count(distinct shipment_id) as shipment_id_count,
            min(reported_at) as earliest_report_time,
            max(reported_at) as latest_report_time
        from ranking_lab.shipment_exceptions;

with previous_report as (
    select
        shipment_id,
        region,
        delay_hours,
        reported_at,
        lag(delay_hours) over (partition by region order by
            reported_at, exception_id) as previous_delay_hours,
        delay_hours - lag(delay_hours) over (partition by region order by
            reported_at, exception_id) as delay_hours_change
    from ranking_lab.shipment_exceptions
),
delay_class_tbl as (
    select
        shipment_id,
        region,
        delay_hours,
        reported_at,
        previous_delay_hours,
        delay_hours_change,
        case
            when previous_delay_hours is null then 'Not comparable'
            when delay_hours is null then 'Not comparable'
            when previous_delay_hours = delay_hours then 'Unchanged'
            when delay_hours_change > 0 then 'Increased delay hours'
            when delay_hours_change < 0 then 'Decreased delay hours'
        end as delay_classification
    from previous_report
),
summary_counts as (
    select
        sum(
            case when delay_classification = 'Not comparable'
            then 1 else 0 end) as not_comparable_count,
        sum(
            case when delay_classification = 'Unchanged'
            then 1 else 0 end) as unchanged_count,
        sum(
            case when delay_classification = 'Increased delay hours'
            then 1 else 0 end) as increased_count,
        sum(
            case when delay_classification = 'Decreased delay hours'
            then 1 else 0 end) as decreased_count,
        count(*) as total_navigated_records
    from delay_class_tbl
)
select
    not_comparable_count,
    unchanged_count,
    increased_count,
    decreased_count,
    (not_comparable_count + unchanged_count + increased_count + decreased_count) as sum_of_classifications,
    total_navigated_records,
    case
        when (
            not_comparable_count + unchanged_count +
            increased_count + decreased_count) = total_navigated_records
        then 'MATCH: Valid row reconciliation'
        else 'MISMATCH: Overlapping or missing classifications'
    end as reconciliation_status
from summary_counts;
    ;
--A. Business objective: What question does your analysis answer?
--The regions average delay hours and the shipments counts. It analyzes the delay hours
--metrics experienced in every region
--B. Grain: What does each output row represent?
--raw data grain is one row per exception_id or shipment_id. Final table grain is
--1 row per region & delay classification
--C. Partition: Why did you choose those columns?
--region, find the previous delay hours within each region
--D. Ordering: What establishes the event sequence?
--The time reported_at and where their is a tie, use snapshot_id
--E. Validation: How did you establish that your query behaves as intended?
--The total sum of shipment_count is same as as the total number of distinct shipments in
--the raw data
--F. Limitations: What conclusions cannot be supported by the available data?
