--data check
SELECT  *
FROM training.supply_chain_orders_raw
;

--Drill 72: customer staging representation
SELECT
    customer_id,
    customer_name as customer_name_raw,
    COALESCE(TRIM(lower(customer_name)), 'Unknown customer') as customer_name_clean,
    TRIM(upper(customer_segment)) as customer_segment_clean
FROM training.supply_chain_orders_raw;


--Drill 73: Supplier staging representation
SELECT
    supplier_id,
    supplier_name as supplier_name_raw,
    COALESCE(TRIM(lower(supplier_name)), 'Unknown supplier') as supplier_name_clean,
    CASE
        WHEN supplier_name is NULL or TRIM(supplier_name) = '' THEN 'Missing'
        ELSE 'Present'
    end as supplier_quality
FROM training.supply_chain_orders_raw;


--Drill 74: Combined financial translation
WITH base_metrics as (
SELECT
    order_item_id,
    units_ordered,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    ROUND(units_ordered::INTEGER * unit_price::NUMERIC, 2) as gross_sales,
    ROUND((units_ordered::INTEGER * unit_price::NUMERIC) * discount_rate::NUMERIC, 2) as discount_amount,
    ROUND((units_ordered::INTEGER * unit_price::NUMERIC) -
            ((units_ordered::INTEGER * unit_price::NUMERIC) * discount_rate::NUMERIC ), 2) as net_sales,
    ROUND((unit_cost::NUMERIC * units_ordered::INTEGER) + shipping_cost::NUMERIC, 2) as cost_of_goods
FROM training.supply_chain_orders_raw
)
SELECT
    order_item_id,
    units_ordered,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    gross_sales,
    discount_amount,
    net_sales,
    cost_of_goods,
    coalesce(ROUND(((net_sales -cost_of_goods) / NULLIF(net_sales, 0)) * 100, 2), 0) as gross_margin
FROM base_metrics;


--Drill 75; Financial quality flag
SELECT
    discount_rate
FROM training.supply_chain_orders_raw;
--Comment: i don't know what criteria i should use to define invalid discount_rate, some products have 0 discount, generally valid
--         somem have 20% discount, relatively high but valid still in business, help me understand this question
WITH base_metrics as (
SELECT
    order_item_id,
    units_ordered,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    ROUND(units_ordered::INTEGER * unit_price::NUMERIC, 2) as gross_sales,
    ROUND((units_ordered::INTEGER * unit_price::NUMERIC) * discount_rate::NUMERIC, 2) as discount_amount,
    ROUND((units_ordered::INTEGER * unit_price::NUMERIC) -
            ((units_ordered::INTEGER * unit_price::NUMERIC) * discount_rate::NUMERIC ), 2) as net_sales,
    ROUND((unit_cost::NUMERIC * units_ordered::INTEGER) + shipping_cost::NUMERIC, 2) as cost_of_goods
FROM training.supply_chain_orders_raw
)
SELECT
    order_item_id,
    units_ordered,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    gross_sales,
    discount_amount,
    net_sales,
    cost_of_goods,
    coalesce(ROUND(((net_sales -cost_of_goods) / NULLIF(net_sales, 0)) * 100, 2), 0) as gross_margin,
    CASE
        WHEN units_ordered::INTEGER < 0 THEN 'invalid_units_ordered'
        WHEN unit_price::NUMERIC < 0 THEN 'invalid_unit_price'
        WHEN unit_cost::NUMERIC < 0 THEN 'invalid_unit_cost'
        WHEN shipping_cost::NUMERIC < 0 THEN 'invalid_shipping_cost'
        ELSE 'valid'
    end as financial_quality
FROM base_metrics;


--Drill 76; Multi-rule record quality
SELECT
    trim(customer_name),
    trim(supplier_name),
    units_ordered::INTEGER as quantity,
    unit_price::NUMERIC,
    unit_cost::NUMERIC,
    shipping_cost::NUMERIC,
    trim(order_date) as order_date,
    trim(promised_delivery_date) as promised_delivery_date,
    CASE
        WHEN customer_name is NULL or customer_name = '' THEN 'missing customer'
        WHEN supplier_name is NULL or supplier_name = '' THEN 'missing supplier'
        WHEN units_ordered::INTEGER < 0 THEN 'invalid quantity'
        WHEN unit_price::NUMERIC < 0 THEN 'invalid unit_price'
        WHEN unit_cost::NUMERIC < 0 THEN 'invalid unit_cost'
        WHEN shipping_cost::NUMERIC < 0 THEN 'invalid shipping_cost'
        WHEN order_date::DATE > promised_delivery_date::DATE THEN 'invalid order_date'
        ELSE 'valid'
    end as record_quality
FROM training.supply_chain_orders_raw;


--Drill 78: Actual delivery null semantics
SELECT
    shipment_status,
    actual_delivery_date,
    CASE
        WHEN actual_delivery_date::DATE is NULL AND lower(TRIM(shipment_status)) <> 'cancelled' THEN 'invalid_delivery_record'
        ELSE 'valid_delivery_record'
    end as delivery_record_state
FROM training.supply_chain_orders_raw;


--Drill 79: Suspicious delivery records
--status inspection
SELECT DISTINCT
    lower(trim(shipment_status)) as shipment_status
FROM training.supply_chain_orders_raw;
SELECT
    shipment_status,
    actual_delivery_date,
    CASE
        WHEN actual_delivery_date is NULL AND lower(trim(shipment_status)) = 'delivered' THEN 'invalid_delivery_record'
        ELSE 'valid'
    end as delivery_record_validity
FROM training.supply_chain_orders_raw;


--Drill 80
SELECT
    units_ordered,
    abs(units_ordered::INTEGER) as abs_units_ordered,
    CASE
        WHEN units_ordered::INTEGER < 0 THEN 'invalid negative units_ordered'
        ELSE 'valid units_ordered'
    end as units_ordered_quality_flag,
    shipping_cost,
    abs(shipping_cost::NUMERIC) as abs_shipping_cost,
    CASE
        WHEN shipping_cost::NUMERIC < 0 THEN 'invalid negative shipping_cost'
        ELSE 'valid shipping_cost'
    end as shipping_cost_quality_flag
FROM training.supply_chain_orders_raw;


--Drill 81: Full raw profiling challenge
SELECT
    order_item_id,
    customer_name as customer_name_raw,
    TRIM(customer_name) as customer_name,
    supplier_name as supplier_name_raw,
    TRIM(supplier_name) as supplier_name,
    customer_segment as customer_segment_raw,
    TRIM(customer_segment) as customer_segment,
    shipment_status as shipment_status_raw,
    TRIM(shipment_status) as shipment_status,
    units_ordered as units_ordered_raw,
    units_ordered::INTEGER,
    order_date as order_date_raw,
    order_date::DATE,
    actual_delivery_date as actual_delivery_date_raw,
    actual_delivery_date::DATE,
    batch_id as batch_id_raw,
    TRIM(batch_id) as batch_id
FROM training.supply_chain_orders_raw;
