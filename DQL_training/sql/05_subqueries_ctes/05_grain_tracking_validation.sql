--Objective:
--Detect grain violations, unexpected row multiplication and aggregation errors

--Drill 16: Establishing grain before transformation
Business scenario:
--You are operating to build an order-level revenue reporting pipeline

with source_grain as (
    select
        order_item_id,
        order_id,
        units_ordered,
        unit_price
    from join_lab.fact_order_item
),
order_revenue as (
    select
        order_id,
        sum(units_ordered * unit_price) as revenue
    from source_grain
    group by order_id
),
grain_validation as (
    select
        order_id,
        count(*) as grain_count
    from order_revenue
    group by order_id
)
select
    order_id
from grain_validation
where grain_count > 1;

--Engineering question:
--The table should return 0 rows if aggregation is correctly implemented

            --Investigative query
            select
                product_key,
                count(*) as row_count
            from join_lab.bridge_product_supplier
            group by product_key;

--Drill 17: Detecting revenue inflation
--Business scenario:
--An analyst joined the order_items directly to product-supplier relationships
--The resulting revenue is higher than the original revenue

with baseline_revenue as (
    select
        order_item_id,
        product_key,
        units_ordered,
        unit_price,
        (units_ordered * unit_price) as bl_revenue
    from join_lab.fact_order_item
),
joined_revenue as (
    select
        blr.order_item_id,
        blr.product_key,
        sum(blr.bl_revenue) as joined_revenue
    from baseline_revenue as blr
    left join join_lab.bridge_product_supplier as bps
    on bps.product_key = blr.product_key
    group by blr.order_item_id,
            blr.product_key
),
revenue_comparison as (
    select
        blr.order_item_id,
        blr.bl_revenue as base_revenue,
        jnr.joined_revenue,
        abs(blr.bl_revenue - jnr.joined_revenue) as revenue_difference,
        round(((jnr.joined_revenue - blr.bl_revenue) / nullif(
            blr.bl_revenue, 0
        )) * 100, 2) as revenue_inflation_pct
    from baseline_revenue as blr
    join joined_revenue as jnr
    on jnr.order_item_id = blr.order_item_id
)
select
    order_item_id,
    base_revenue,
    joined_revenue,
    revenue_difference,
    revenue_inflation_pct
from revenue_comparison;

--Engineering question:
--What caused the inflation?
--The bridge table has multiple supplier rows for some products.

--Why does a many to many relationship create the risk?
--Because the join changes the row cardinality. A fact row that originally appeared once may appear
--several times after the join.

--why is distinct necessarily a valid fix?
--Beacuse duplicate-looking rows may represent legitimate separate relationships



--Drill 18: Identifying fanned out order_items
--Business scenario: The data quality wants to find out which order_items generated multiple
--rows after joining to suppliers.

with order_supplier_matches as (
    select
        foi.order_item_id,
        bps.supplier_key
    from join_lab.fact_order_item as foi
    left join join_lab.bridge_product_supplier as bps
    on bps.product_key = foi.product_key
),
supplier_match_count as (
    select
        order_item_id,
        count(supplier_key) as supplier_matches
    from order_supplier_matches
    group by order_item_id
),
fanout_classification as (
    select
        order_item_id,
        supplier_matches,
        case
            when supplier_matches > 1 then 'Fan-out'
            when supplier_matches = 1 then 'No fan-out'
            else 'Unmatched'
        end as classification
    from supplier_match_count
),
order_item_count as (
    select
        classification,
        count(order_item_id) as order_item_count,
        sum(supplier_matches) as supplier_matches_count
    from fanout_classification
    group by classification
)
select
    classification,
    order_item_count,
    supplier_matches_count
from order_item_count;



--Drill 19: Validating order level aggregation
--Business scenario:
--Finance wants to proof that aggregating order items into orders does not change total revenue

with source_revenue as (
    select
        order_item_id,
        order_id,
        (units_ordered * unit_price) as fact_tbl_revenue
    from join_lab.fact_order_item
),
order_revenues_tbl as (
    select
        order_id,
        sum(fact_tbl_revenue) as order_revenue
    from source_revenue
    group by order_id
),
aggregated_fact_revenue as (
    select
        sum(fact_tbl_revenue) as fact_aggregated_revenue
    from source_revenue
),
aggregated_order_revenue as(
    select
        sum(order_revenue) as order_aggregated_revenue
    from order_revenues_tbl
),
validation_results as (
    select
        afr.fact_aggregated_revenue,
        aor.order_aggregated_revenue,
        (afr.fact_aggregated_revenue - aor.order_aggregated_revenue) as difference,
        case
            when afr.fact_aggregated_revenue = aor.order_aggregated_revenue then 'PASS'
            else 'FAIL'
        end as validation_status
    from aggregated_fact_revenue as afr
    cross join aggregated_order_revenue as aor
)
select
    fact_aggregated_revenue,
    order_aggregated_revenue,
    difference,
    validation_status
from validation_results;

--Engineering challenge
--The transformation from source revenue to order-level revenue did not preserve the revenue total



--Drill 20: Shipment event grain investigation
--Business scenario:
--Operations wants to understand shipment activity, one order may have multiple shipment events

            --
            select
                *
            FROM join_lab.fact_shipment_event;

with shipments_events_count as (
    select
        order_id,
        count(shipment_event_id) as shipments_count
    from join_lab.fact_shipment_event
    group by order_id
),
shipments_classification as (
    select
        order_id,
        shipments_count,
        case
            when shipments_count >= 4 then 'High activity'
            when shipments_count between 2 and 3 then 'Multiple events'
            else 'Single event'
        end as classification
    from shipments_events_count
),
shipment_summary as (
    select
        classification,
        count(order_id) as orders_count,
        sum(shipments_count) as total_shipments_count,
        avg(shipments_count) as avg_shipments_per_order
    from shipments_classification
    group by classification
)
select
    classification,
    orders_count,
    total_shipments_count,
    round(avg_shipments_per_order, 2) as avg_shipments_per_order
from shipment_summary;
