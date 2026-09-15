INSERT INTO training.supply_chain_orders (
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
    promised_delivery_date,
    actual_delivery_date,
    returned,
    order_priority,
    batch_id
)
SELECT
    'ORD-' || LPAD(series_number::TEXT, 7, '0'),

    DATE '2024-01-01'
        + ((series_number - 1) % 900)::INTEGER,

    'CUS-' || LPAD(((series_number - 1) % 2000 + 1)::TEXT, 5, '0'),

    'Customer '
        || LPAD(((series_number - 1) % 2000 + 1)::TEXT, 5, '0'),

    CASE series_number % 3
        WHEN 0 THEN 'Consumer'
        WHEN 1 THEN 'Corporate'
        ELSE 'Small Business'
    END,

    'PRD-' || LPAD(((series_number - 1) % 500 + 1)::TEXT, 4, '0'),

    CASE series_number % 8
        WHEN 0 THEN 'Industrial Fasteners'
        WHEN 1 THEN 'Safety Gloves'
        WHEN 2 THEN 'Packing Materials'
        WHEN 3 THEN 'Hydraulic Components'
        WHEN 4 THEN 'Electrical Cables'
        WHEN 5 THEN 'Warehouse Shelving'
        WHEN 6 THEN 'Machine Lubricant'
        ELSE 'Protective Helmets'
    END,

    CASE series_number % 5
        WHEN 0 THEN 'Industrial Supplies'
        WHEN 1 THEN 'Safety Equipment'
        WHEN 2 THEN 'Packaging'
        WHEN 3 THEN 'Mechanical Parts'
        ELSE 'Electrical'
    END,

    'SUP-' || LPAD(((series_number - 1) % 100 + 1)::TEXT, 4, '0'),

    'Supplier '
        || LPAD(((series_number - 1) % 100 + 1)::TEXT, 4, '0'),

    CASE series_number % 6
        WHEN 0 THEN 'Calgary'
        WHEN 1 THEN 'Edmonton'
        WHEN 2 THEN 'Vancouver'
        WHEN 3 THEN 'Toronto'
        WHEN 4 THEN 'Winnipeg'
        ELSE 'Montreal'
    END,

    CASE series_number % 4
        WHEN 0 THEN 'West'
        WHEN 1 THEN 'Prairies'
        WHEN 2 THEN 'Central'
        ELSE 'East'
    END,

    CASE series_number % 5
        WHEN 0 THEN 'Delivered'
        WHEN 1 THEN 'In Transit'
        WHEN 2 THEN 'Delayed'
        WHEN 3 THEN 'Processing'
        ELSE 'Cancelled'
    END,

    CASE series_number % 4
        WHEN 0 THEN 'Road'
        WHEN 1 THEN 'Rail'
        WHEN 2 THEN 'Air'
        ELSE 'Ocean'
    END,

    ((series_number * 7) % 100 + 1)::INTEGER,

    ROUND(
        (20 + ((series_number * 13) % 980))::NUMERIC,
        2
    ),

    ROUND(
        (10 + ((series_number * 9) % 650))::NUMERIC,
        2
    ),

    CASE series_number % 5
        WHEN 0 THEN 0.0000
        WHEN 1 THEN 0.0500
        WHEN 2 THEN 0.1000
        WHEN 3 THEN 0.1500
        ELSE 0.2000
    END,

    ROUND(
        (15 + ((series_number * 11) % 300))::NUMERIC,
        2
    ),

    DATE '2024-01-01'
        + ((series_number - 1) % 900)::INTEGER
        + 7,

    CASE
        WHEN series_number % 5 = 4 THEN NULL
        ELSE
            DATE '2024-01-01'
            + ((series_number - 1) % 900)::INTEGER
            + 5
            + (series_number % 8)::INTEGER
    END,

    series_number % 17 = 0,

    CASE series_number % 4
        WHEN 0 THEN 'Low'
        WHEN 1 THEN 'Medium'
        WHEN 2 THEN 'High'
        ELSE 'Urgent'
    END,

    'BATCH-'
        || TO_CHAR(
            DATE '2024-01-01'
            + ((series_number - 1) % 900)::INTEGER,
            'YYYYMM'
        )

FROM generate_series(1, 50000) AS generated(series_number);


SELECT *
FROM training.supply_chain_orders


--the table is created ONLY for practice in phase2(postgres)
--Load table for raw supply chain table for phase 2

INSERT INTO training.supply_chain_orders_raw (
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
    promised_delivery_date,
    actual_delivery_date,
    returned,
    order_priority,
    batch_id,
    loaded_at
)
SELECT
    order_item_id::TEXT,
    order_id,
    order_date::TEXT,
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
    units_ordered::TEXT,
    unit_price::TEXT,
    unit_cost::TEXT,
    discount_rate::TEXT,
    shipping_cost::TEXT,
    promised_delivery_date::TEXT,
    actual_delivery_date::TEXT,
    returned::TEXT,
    order_priority,
    batch_id,
    loaded_at::TEXT
FROM training.supply_chain_orders
ORDER BY order_item_id
LIMIT 100;

--loading erroneous customer_names
UPDATE training.supply_chain_orders_raw
SET customer_name =
    CASE
        WHEN order_item_id::INTEGER % 17 = 0 THEN NULL
        WHEN order_item_id::INTEGER % 13 = 0 THEN '   ' || customer_name || '   '
        WHEN order_item_id::INTEGER % 11 = 0 THEN UPPER(customer_name)
        WHEN order_item_id::INTEGER % 7 = 0 THEN LOWER(customer_name)
        ELSE customer_name
    END;

--load corrupted supplier_names
UPDATE training.supply_chain_orders_raw
SET supplier_name =
    CASE
        WHEN order_item_id::INTEGER % 19 = 0 THEN NULL
        WHEN order_item_id::INTEGER % 14 = 0 THEN ''
        WHEN order_item_id::INTEGER % 9 = 0 THEN '   ' || supplier_name || ' '
        WHEN order_item_id::INTEGER % 8 = 0 THEN LOWER(supplier_name)
        ELSE supplier_name
    END;

--Corrupt categorical strings
UPDATE training.supply_chain_orders_raw
SET
    customer_segment =
        CASE
            WHEN order_item_id::INTEGER % 6 = 0
                THEN LOWER(customer_segment)
            WHEN order_item_id::INTEGER % 10 = 0
                THEN '  ' || customer_segment || ' '
            ELSE customer_segment
        END,

    shipment_status =
        CASE
            WHEN order_item_id::INTEGER % 7 = 0
                THEN LOWER(shipment_status)
            WHEN order_item_id::INTEGER % 12 = 0
                THEN ' ' || UPPER(shipment_status) || ' '
            ELSE shipment_status
        END,

    sales_region =
        CASE
            WHEN order_item_id::INTEGER % 8 = 0
                THEN LOWER(sales_region)
            ELSE sales_region
        END;

--Introduce numeric problems
UPDATE training.supply_chain_orders_raw
SET units_ordered =
    CASE
        WHEN order_item_id::INTEGER % 23 = 0 THEN '0'
        WHEN order_item_id::INTEGER % 29 = 0
            THEN '-' || units_ordered
        WHEN order_item_id::INTEGER % 16 = 0
            THEN '  ' || units_ordered || '  '
        ELSE units_ordered
    END;

--Corrupt financial fields
UPDATE training.supply_chain_orders_raw
SET
    unit_cost =
        CASE
            WHEN order_item_id::INTEGER % 31 = 0
                THEN '-' || unit_cost
            WHEN order_item_id::INTEGER % 18 = 0
                THEN '  ' || unit_cost || ' '
            ELSE unit_cost
        END,

    shipping_cost =
        CASE
            WHEN order_item_id::INTEGER % 27 = 0
                THEN '-' || shipping_cost
            ELSE shipping_cost
        END;

--Introduce date related problems
UPDATE training.supply_chain_orders_raw
SET
    order_date =
        CASE
            WHEN order_item_id::INTEGER % 21 = 0
                THEN '  ' || order_date || ' '
            ELSE order_date
        END,

    promised_delivery_date =
        CASE
            WHEN order_item_id::INTEGER % 22 = 0
                THEN ' ' || promised_delivery_date || ' '
            ELSE promised_delivery_date
        END;

--Introduce boolean representation inconsistencies
UPDATE training.supply_chain_orders_raw
SET returned =
    CASE
        WHEN order_item_id::INTEGER % 9 = 0
            THEN UPPER(returned)
        WHEN order_item_id::INTEGER % 14 = 0
            THEN ' ' || returned || ' '
        ELSE returned
    END;

--Introduce blanks into batch_id
UPDATE training.supply_chain_orders_raw
SET batch_id =
    CASE
        WHEN order_item_id::INTEGER % 32 = 0 THEN NULL
        WHEN order_item_id::INTEGER % 26 = 0 THEN ''
        WHEN order_item_id::INTEGER % 15 = 0
            THEN '  ' || batch_id || ' '
        ELSE batch_id
    END;

--test the raw data
SELECT *
FROM training.supply_chain_orders_raw
ORDER BY order_item_id::INTEGER
limit 30;

SELECT DISTINCT shipment_status
FROM training.supply_chain_orders_raw
ORDER BY shipment_status;

SELECT DISTINCT customer_segment
FROM training.supply_chain_orders_raw
ORDER BY customer_segment;


SELECT *
FROM training.supply_chain_orders_raw
LIMIT 50;
