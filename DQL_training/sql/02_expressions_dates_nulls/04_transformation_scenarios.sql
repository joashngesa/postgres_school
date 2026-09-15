--DATE ARITHMETIC
--Check the data
SELECT  *
FROM training.supply_chain_orders_raw;

--Drill 55: Delivery duration
--Only retrieve rows where actual delivery exists.
SELECT
    order_date,
    actual_delivery_date,
    actual_delivery_date:: DATE - order_date::DATE as total_delivery_date
FROM training.supply_chain_orders_raw
WHERE actual_delivery_date is not NULL;


--Drill 56: Promised lead time
SELECT
    order_date,
    promised_delivery_date,
    promised_delivery_date::DATE - order_date::DATE as promised_lead_days
FROM training.supply_chain_orders_raw;


--Drill 57: Delivery variance
SELECT
    actual_delivery_date,
    promised_delivery_date,
    actual_delivery_date::DATE - promised_delivery_date::DATE as delivery_variance_days,
    CASE
        WHEN actual_delivery_date::DATE - promised_delivery_date::DATE < 0 THEN 'Early delivery'
        WHEN actual_delivery_date::DATE - promised_delivery_date::DATE = 0 THEN 'Punctual'
        WHEN actual_delivery_date::DATE is NULL THEN 'Awaiting'
        ELSE 'Late delivery'
    end as delivery_category
FROM training.supply_chain_orders_raw;


--Dril 58: Delivery performance case
SELECT
    order_date,
    actual_delivery_date,
    promised_delivery_date,
    actual_delivery_date::DATE - promised_delivery_date::DATE as delivery_variance_days,
    CASE
        WHEN actual_delivery_date is NULL THEN 'Pending'
        WHEN actual_delivery_date::DATE - promised_delivery_date::DATE < 0 THEN 'Early'
        WHEN actual_delivery_date::DATE - promised_delivery_date::DATE = 0 THEN 'On time'
        WHEN actual_delivery_date::DATE - promised_delivery_date::DATE BETWEEN 1 and 2 THEN 'Slight delay'
        ELSE 'Late'
    end as delivery_performance
FROM training.supply_chain_orders_raw;


--CURRENT_DATE & CURRENT_TIMESTAMP
SELECT
    order_item_id,
    current_date as processing_date,
    CURRENT_TIMESTAMP as processed_at
FROM training.supply_chain_orders_raw
LIMIT 10
--Comment: the values repeat because current_date & current_timestamp give one value from the time when the query was executed


--Drill 60: Source timestamp vs processing timestamp
--loaded_at -> records the time when the raw data was ingested from the source
--clean_loaded_at -> records time when the data passed through validation
--current_timestamp -> may represent the time data is transformed


--EXTRACT
--Drill 61: order calender components
SELECT
    order_date,
    extract(YEAR FROM order_date::DATE) as order_year,
    extract(MONTH FROM order_date::DATE)as order_month,
    extract(day FROM order_date::DATE)as order_day_of_month,
    extract(dow FROM order_date::DATE)as order_day_of_week
FROM training.supply_chain_orders_raw;


--DATE_PART
--Drill 62:
SELECT
    order_date,
    date_part('year', order_date::DATE) as order_year,
    date_part('month', order_date::DATE) as order_month,
    date_part('day', order_date::DATE) as order_day_of_month,
    date_part('dow', order_date::DATE) as order_day_of_week
FROM training.supply_chain_orders_raw;


--Drill 63 Delivery calender components
SELECT
    actual_delivery_date,
    extract(YEAR FROM actual_delivery_date::DATE) as delivery_year,
    extract(MONTH FROM actual_delivery_date::DATE) as delivery_month
FROM training.supply_chain_orders_raw
WHERE actual_delivery_date is not NULL;


--DATE_TRUNC
--Drill 64
SELECT
    order_id,
    trim(order_date),
    date_trunc('month', order_date::DATE) as order_month
FROM training.supply_chain_orders_raw;


--Drill 65: Compare date_trunc with extract
SELECT
    trim(order_date),
    EXTRACT(MONTH FROM order_date::DATE) as order_date_month_extract,
    date_trunc('month', order_date::DATE) as order_date_month_trunc
FROM training.supply_chain_orders_raw;
--comment: extract brings back the month from the date column whereas
--         date_trunc resets the date value at the beginning of the month


--Drill 66-Analytical thinking
SELECT
    order_date,
    date_trunc('week', order_date::DATE) as order_week,
    date_trunc('month', order_date::DATE) as order_month,
    date_trunc('quarter', order_date::DATE) as order_quarter,
    date_trunc('year', order_date::DATE) as order_year
FROM training.supply_chain_orders_raw;


--Drill 67: Interval
SELECT
    trim(order_date),
    order_date::DATE + interval '2 days' as processed_sla_date
FROM training.supply_chain_orders_raw;


--Drill 68-Recent load threshold
SELECT
    CURRENT_TIMESTAMP as loaded_at,
    CURRENT_TIMESTAMP - interval '24 hours' as previous_load
FROM training.supply_chain_orders_raw;


--Drill 69_Delivery extension scenario
SELECT
    promised_delivery_date,
    promised_delivery_date::DATE + INTERVAL '2 days' as revised_promise_date
FROM training.supply_chain_orders_raw;


--AGE
--Drill 70_ age of order
SELECT
    order_date,
    age(CURRENT_DATE, order_date::DATE) as order_age
FROM training.supply_chain_orders_raw;


--Drill 71: Age vs direct subtraction
SELECT
    trim(order_date),
    current_date - order_date::DATE as order_age
FROM training.supply_chain_orders_raw;
--Comment: age gives back value in years, month & days format whereas
--         direct subtraction give back value in days


