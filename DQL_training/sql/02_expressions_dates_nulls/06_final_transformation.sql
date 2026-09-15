--RAW -> STAGING TRANSFORMATION
--Inspect raw file
-- Select all rows from'
SELECT * FROM training.supply_chain_orders_raw;
--Transform file
WITH converted_table as (
SELECT
    order_item_id::INTEGER,
    trim(order_id) as order_id,
    order_date::DATE as order_date,
    TRIM(customer_id) as customer_id,
    COALESCE(TRIM(lower(customer_name)), 'Unknown customer') as customer_name,
    TRIM(upper(customer_segment)) as customer_segment,
    TRIM(product_id) as product_id,
    TRIM(product_name) as product_name,
    TRIM(upper(product_category)) as product_category,
    TRIM(supplier_id) as supplier_id,
    COALESCE(TRIM(lower(supplier_name)), 'Unknown supplier') as supplier_name,
    trim(upper(warehouse_city)) as warehouse_city,
    TRIM(upper(sales_region)) as sales_region,
    trim(upper(shipment_status)) as shipment_status,
    TRIM(lower(transport_mode)) as transport_mode,
    units_ordered::INTEGER as units_ordered,
    unit_price::NUMERIC as unit_price,
    unit_cost::NUMERIC as unit_cost,
    discount_rate::NUMERIC as discount_rate,
    shipping_cost::NUMERIC as shipping_cost,
    promised_delivery_date::DATE as promised_delivery_date,
    actual_delivery_date::DATE as actual_delivery_date,
    returned::BOOLEAN as returned,
    trim(upper(order_priority)) as order_priority,
    NULLIF(TRIM(batch_id), '') as batch_id,
    loaded_at::timestamptz
FROM training.supply_chain_orders_raw
),
transformed_tbl as (
SELECT
    order_item_id,
    order_id,
    order_date,
    customer_id,
    customer_name,
    customer_segment,
    product_id,
    product_name,
    product_category,
    supplier_id,
    supplier_name,
    warehouse_city,
    sales_region,
    shipment_status,
    transport_mode,
    units_ordered,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    ROUND(unit_price * units_ordered, 2) as gross_sales,
    ROUND((unit_price * units_ordered) * discount_rate, 2) as discount_amount,
    ROUND((unit_price * units_ordered) - (unit_price * units_ordered) * discount_rate, 2) as net_sales,
    ROUND((unit_cost * units_ordered) + shipping_cost, 2) as cost_of_goods,
    ROUND(COALESCE(shipping_cost / NULLIF(units_ordered, 0)), 0) as shipping_cost_per_unit,
    promised_delivery_date,
    actual_delivery_date,
    promised_delivery_date - order_date as promised_lead_days,
    actual_delivery_date - order_date as actual_lead_days,
    promised_delivery_date - actual_delivery_date as delivery_variance_days
FROM converted_table
)
SELECT
    order_item_id,
    order_id,
    order_date,
    customer_id,
    customer_name,
    customer_segment,
    product_id,
    product_name,
    product_category,
    supplier_id,
    supplier_name,
    warehouse_city,
    sales_region,
    shipment_status,
    transport_mode,
    units_ordered,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    gross_sales,
    discount_amount,
    net_sales,
    cost_of_goods,
    round(((net_sales - cost_of_goods) / NULLIF(net_sales, 0) * 100), 2) as gross_margin,
    shipping_cost_per_unit,
    promised_delivery_date,
    actual_delivery_date,
    promised_lead_days,
    actual_lead_days,
    delivery_variance_days,
    CASE
        WHEN actual_delivery_date is NULL THEN 'Pending'
        WHEN promised_delivery_date - actual_delivery_date > 0 THEN 'Early'
        WHEN promised_delivery_date = actual_delivery_date THEN 'On time'
        WHEN actual_delivery_date - promised_delivery_date BETWEEN 1 AND 2 THEN 'Slight delay'
        ELSE 'Late'
    end as delivery_performance
FROM transformed_tbl;
