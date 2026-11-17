--Revision A: RTows vs Range
with supplier_data (
    supplier_id,
    record_id,
    reporting_month,
    performance_score
) as (
    values
        (101, 1, DATE '2026-01-01', 70),
        (101, 2, DATE '2026-02-01', 85),
        (101, 3, DATE '2026-02-01', 90),
        (101, 4, DATE '2026-03-01', 95)
)
select
    supplier_id,
    record_id,
    reporting_month,
    performance_score,
    last_value(performance_score) over (order by reporting_month
        rows between unbounded preceding and current row) as row_last_value,
    last_value(performance_score) over (order by reporting_month
        range between unbounded preceding and current row) as range_last_value,
    last_value(performance_score) over (order by reporting_month, record_id
        rows between unbounded preceding and current row) as rcd_row_last_value,
    last_value(performance_score) over (order by reporting_month, record_id
        range between unbounded preceding and current row) as rcd_range_last_value
from supplier_data;
--Both row order value columns would bring back the current row's value as the
--order by frame uses current row whereas both ranges bring back the last value of
--the frame


--Revision B: Revenue analytics: 2 different frames
with first_last_revenue as (
    select
        customer_id,
        reporting_month,
        net_revenue,
        first_value(net_revenue) over (partition by customer_id
            order by reporting_month
            rows between unbounded preceding and unbounded following) as first_revenue,
        last_value(net_revenue) over (partition by customer_id
            order by reporting_month
            rows between unbounded preceding and unbounded following) as last_revenue
    from ranking_lab.customer_order_metrics
)
select
    customer_id,
    reporting_month,
    net_revenue,
    first_revenue,
    net_revenue - first_revenue as revenue_minus_first,
    last_revenue,
    last_revenue - first_revenue as last_minus_first
from first_last_revenue
    ;

--Compare customer region firt and last revenue
with first_last_revenue as (
    select
        customer_id,
        market,
        reporting_month,
        net_revenue,
        first_value(net_revenue) over (partition by customer_id, market
            order by reporting_month
            rows between unbounded preceding and unbounded following) as first_revenue,
        last_value(net_revenue) over (partition by customer_id, market
            order by reporting_month
            rows between unbounded preceding and unbounded following) as last_revenue
    from ranking_lab.customer_order_metrics
)
select
    customer_id,
    market,
    reporting_month,
    net_revenue,
    first_revenue,
    net_revenue - first_revenue as revenue_minus_first,
    last_revenue,
    last_revenue - first_revenue as last_minus_first
from first_last_revenue
    ;
--This is per customer per region analysis


