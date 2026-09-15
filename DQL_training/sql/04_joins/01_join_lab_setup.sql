--Creating schema for the topic

DROP SCHEMA IF EXISTS join_lab CASCADE;
CREATE SCHEMA join_lab;

--Creating dim_customer table
CREATE TABLE join_lab.dim_customer (
    customer_key    INTEGER PRIMARY KEY,
    customer_id     TEXT NOT NULL,
    customer_name   TEXT NOT NULL,
    customer_segment TEXT NOT NULL,
    province        TEXT,
    active_flag     BOOLEAN NOT NULL
);

--Loading dim_customer table
INSERT INTO join_lab.dim_customer (
    customer_key,
    customer_id,
    customer_name,
    customer_segment,
    province,
    active_flag
)
VALUES
    (1,  'CUST-001', 'North Peak Foods',       'Enterprise', 'Alberta',              TRUE),
    (2,  'CUST-002', 'Prairie Health Group',   'Enterprise', 'Alberta',              TRUE),
    (3,  'CUST-003', 'Summit Retail',           'Retail',     'British Columbia',     TRUE),
    (4,  'CUST-004', 'Northern Build Co',       'Industrial', 'Alberta',              TRUE),
    (5,  'CUST-005', 'Aurora Hospitality',      'Hospitality','Saskatchewan',         TRUE),
    (6,  'CUST-006', 'Blue River Markets',      'Retail',     'Alberta',              TRUE),
    (7,  'CUST-007', 'Frontier Energy',         'Industrial', 'Alberta',              FALSE),
    (8,  'CUST-008', 'Westline Pharmacy',       'Retail',     'British Columbia',     TRUE),
    (9,  'CUST-009', 'Polar Logistics',         'Enterprise', 'Manitoba',             TRUE),
    (10, 'CUST-010', 'Rocky Mountain Resorts',  'Hospitality','Alberta',              TRUE),
    (11, 'CUST-011', 'Evergreen Grocers',       'Retail',     'Saskatchewan',         TRUE),
    (12, 'CUST-012', 'Keystone Manufacturing',  'Industrial', 'Alberta',              TRUE),
    (13, 'CUST-013', 'Northern Schools',        'Public',     'Alberta',              TRUE),
    (14, 'CUST-014', 'Prairie Tech Systems',    'Enterprise', 'Saskatchewan',         TRUE),
    (15, 'CUST-015', 'Silverline Construction', 'Industrial', 'British Columbia',     TRUE),

    -- Intentional duplicate business key.
    (16, 'CUST-007', 'Frontier Energy Ltd',     'Industrial', 'Alberta',              TRUE);


--Create dim_product
CREATE TABLE join_lab.dim_product (
    product_key     INTEGER PRIMARY KEY,
    sku             TEXT NOT NULL,
    product_name    TEXT NOT NULL,
    category        TEXT NOT NULL,
    unit_cost       NUMERIC(10,2) NOT NULL,
    active_flag     BOOLEAN NOT NULL
);

--Load dim_product table
INSERT INTO join_lab.dim_product (
    product_key,
    sku,
    product_name,
    category,
    unit_cost,
    active_flag
)
VALUES
    (1,  'SKU-001', 'Industrial Gloves',      'Safety',       8.50,   TRUE),
    (2,  'SKU-002', 'Safety Helmet',          'Safety',       24.00,  TRUE),
    (3,  'SKU-003', 'Steel Toe Boots',        'Safety',       62.00,  TRUE),

    (4,  'SKU-004', 'Cordless Drill',         'Tools',        84.00,  TRUE),
    (5,  'SKU-005', 'Impact Driver',          'Tools',        96.00,  TRUE),
    (6,  'SKU-006', 'Legacy Torque Wrench',   'Tools',        72.00,  FALSE),

    (7,  'SKU-007', 'Pallet Wrap',            'Packaging',    13.00,  TRUE),
    (8,  'SKU-008', 'Shipping Carton',        'Packaging',    4.50,   TRUE),
    (9,  'SKU-009', 'Insulated Container',    'Packaging',    46.00,  TRUE),

    (10, 'SKU-010', 'Barcode Scanner',        'Electronics',  138.00, TRUE),
    (11, 'SKU-011', 'Warehouse Tablet',       'Electronics',  310.00, TRUE),
    (12, 'SKU-012', 'RFID Reader',            'Electronics',  225.00, TRUE),

    (13, 'SKU-013', 'Hydraulic Hose',         'Maintenance',  38.00,  TRUE),
    (14, 'SKU-014', 'Industrial Lubricant',   'Maintenance',  18.00,  TRUE),
    (15, 'SKU-015', 'Bearing Kit',            'Maintenance',  42.00,  TRUE),

    (16, 'SKU-016', 'Cold Chain Sensor',      'Cold Chain',   67.00,  TRUE),
    (17, 'SKU-017', 'Temperature Logger',     'Cold Chain',   91.00,  TRUE),
    (18, 'SKU-018', 'Insulated Pallet Cover', 'Cold Chain',   58.00,  TRUE),

    -- Intentional second version of SKU-006.
    (19, 'SKU-006', 'Digital Torque Wrench',  'Tools',        109.00, TRUE);



--Create dim_warehouse table
CREATE TABLE join_lab.dim_warehouse (
    warehouse_key   INTEGER PRIMARY KEY,
    warehouse_code  TEXT UNIQUE NOT NULL,
    warehouse_city  TEXT NOT NULL,
    province        TEXT NOT NULL,
    capacity_class  TEXT NOT NULL
);

-- Load dim_warehouse_table
INSERT INTO join_lab.dim_warehouse (
    warehouse_key,
    warehouse_code,
    warehouse_city,
    province,
    capacity_class
)
VALUES
    (1, 'WH-CGY', 'Calgary',       'Alberta', 'Large'),
    (2, 'WH-EDM', 'Edmonton',      'Alberta', 'Large'),
    (3, 'WH-RDR', 'Red Deer',      'Alberta', 'Medium'),
    (4, 'WH-LEH', 'Lethbridge',    'Alberta', 'Medium'),
    (5, 'WH-YMM', 'Fort McMurray', 'Alberta', 'Small');



--Create supplier_dimension table
CREATE TABLE join_lab.dim_supplier (
    supplier_key      INTEGER PRIMARY KEY,
    supplier_code     TEXT UNIQUE NOT NULL,
    supplier_name     TEXT NOT NULL,
    supplier_country  TEXT NOT NULL,
    reliability_band  TEXT NOT NULL
);

--Load supplier_dimension table
INSERT INTO join_lab.dim_supplier (
    supplier_key,
    supplier_code,
    supplier_name,
    supplier_country,
    reliability_band
)
VALUES
    (1, 'SUP-001', 'Prairie Industrial Supply', 'Canada',        'High'),
    (2, 'SUP-002', 'Pacific Tool Works',         'Canada',        'Medium'),
    (3, 'SUP-003', 'NorthStar Packaging',        'Canada',        'High'),
    (4, 'SUP-004', 'Alpine Electronics',         'Germany',       'High'),
    (5, 'SUP-005', 'Midwest Components',         'United States', 'Medium'),
    (6, 'SUP-006', 'Polar Cold Systems',         'Canada',        'High'),
    (7, 'SUP-007', 'Atlantic Maintenance',       'Canada',        'Low'),
    (8, 'SUP-008', 'Global Industrial Partners', 'China',         'Medium');



--Create product_supplier bridge table
CREATE TABLE join_lab.bridge_product_supplier (
    product_key   INTEGER NOT NULL,
    supplier_key  INTEGER NOT NULL,
    preferred_supplier BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (product_key, supplier_key)
);

--Load product_supplier bridge tables
INSERT INTO join_lab.bridge_product_supplier (
    product_key,
    supplier_key,
    preferred_supplier
)
VALUES
    (1, 1, TRUE),
    (1, 8, FALSE),

    (2, 1, TRUE),
    (2, 5, FALSE),

    (3, 1, TRUE),

    (4, 2, TRUE),
    (4, 8, FALSE),

    (5, 2, TRUE),
    (5, 5, FALSE),

    (6, 2, FALSE),

    (7, 3, TRUE),
    (7, 8, FALSE),

    (8, 3, TRUE),

    (9, 3, TRUE),
    (9, 6, FALSE),

    (10, 4, TRUE),
    (10, 8, FALSE),

    (11, 4, TRUE),
    (11, 5, FALSE),

    (12, 4, TRUE),

    (13, 7, TRUE),
    (13, 5, FALSE),

    (14, 7, TRUE),

    (15, 5, TRUE),
    (15, 7, FALSE),

    (16, 6, TRUE),
    (16, 4, FALSE),

    (17, 6, TRUE),

    (18, 6, TRUE),
    (18, 3, FALSE),

    (19, 2, TRUE);



--Create date_dimension table
CREATE TABLE join_lab.dim_date (
    date_key       INTEGER PRIMARY KEY,
    full_date      DATE UNIQUE NOT NULL,
    year_number    INTEGER NOT NULL,
    quarter_number INTEGER NOT NULL,
    month_number   INTEGER NOT NULL,
    month_name     TEXT NOT NULL,
    day_of_month   INTEGER NOT NULL,
    day_name       TEXT NOT NULL,
    is_weekend     BOOLEAN NOT NULL
);

--Load date_dimension table
INSERT INTO join_lab.dim_date (
    date_key,
    full_date,
    year_number,
    quarter_number,
    month_number,
    month_name,
    day_of_month,
    day_name,
    is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER,
    d,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TO_CHAR(d, 'FMMonth'),
    EXTRACT(DAY FROM d)::INTEGER,
    TO_CHAR(d, 'FMDay'),
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series(
    DATE '2026-01-01',
    DATE '2026-12-31',
    INTERVAL '1 day'
) AS gs(d);


--Create fact_order_item table
CREATE TABLE join_lab.fact_order_item (
    order_item_id     INTEGER PRIMARY KEY,
    order_id          TEXT NOT NULL,
    order_date_key    INTEGER NOT NULL,
    customer_key      INTEGER NOT NULL,
    product_key       INTEGER NOT NULL,
    warehouse_key     INTEGER NOT NULL,
    units_ordered     INTEGER NOT NULL,
    unit_price        NUMERIC(10,2) NOT NULL,
    discount_rate     NUMERIC(5,4) NOT NULL,
    shipping_cost     NUMERIC(10,2) NOT NULL,
    order_status      TEXT NOT NULL,
    returned          BOOLEAN NOT NULL
);

--Load fact_order_items table
WITH generated AS (
    SELECT
        g AS order_item_id,
        ((g - 1) / 3) AS order_seq,

        DATE '2026-01-01'
            + (((g - 1) / 3) * 3 % 180) AS order_date
    FROM generate_series(1, 180) AS gs(g)
)
INSERT INTO join_lab.fact_order_item (
    order_item_id,
    order_id,
    order_date_key,
    customer_key,
    product_key,
    warehouse_key,
    units_ordered,
    unit_price,
    discount_rate,
    shipping_cost,
    order_status,
    returned
)
SELECT
    order_item_id,

    'ORD-' || LPAD((1001 + order_seq)::TEXT, 4, '0'),

    TO_CHAR(order_date, 'YYYYMMDD')::INTEGER,

    CASE
        WHEN order_seq % 29 = 0
            AND order_seq > 0
            THEN 999

        ELSE (order_seq % 15) + 1
    END,

    CASE
        WHEN order_item_id % 47 = 0
            THEN 999

        ELSE ((order_item_id * 5 - 1) % 18) + 1
    END,

    CASE
        WHEN order_seq = 41
            THEN 999

        ELSE (order_seq % 5) + 1
    END,

    ((order_item_id * 7) % 12) + 1,

    ROUND(
        (
            25
            + ((order_item_id * 17) % 260)
            + ((order_item_id % 5) * 0.95)
        )::NUMERIC,
        2
    ),

    CASE
        WHEN order_item_id % 17 = 0 THEN 0.20
        WHEN order_item_id % 11 = 0 THEN 0.15
        WHEN order_item_id % 7  = 0 THEN 0.10
        WHEN order_item_id % 5  = 0 THEN 0.05
        ELSE 0.00
    END,

    ROUND(
        (
            6
            + ((order_item_id * 3) % 25)
            + ((order_seq % 4) * 2.25)
        )::NUMERIC,
        2
    ),

    CASE
        WHEN order_seq % 17 = 0 THEN 'Cancelled'
        WHEN order_seq % 9  = 0 THEN 'Delayed'
        WHEN order_seq % 5  = 0 THEN 'Processing'
        ELSE 'Completed'
    END,

    order_item_id % 13 = 0

FROM generated;


--Create shipment_event_fact table
CREATE TABLE join_lab.fact_shipment_event (
    shipment_event_id INTEGER PRIMARY KEY,
    order_id          TEXT NOT NULL,
    event_sequence    INTEGER NOT NULL,
    event_type        TEXT NOT NULL,
    carrier           TEXT NOT NULL,
    event_date        DATE NOT NULL,
    shipping_cost     NUMERIC(10,2) NOT NULL
);

--Load shipment_event_fact table
WITH orders AS (
    SELECT
        s AS order_seq,
        'ORD-' || LPAD((1001 + s)::TEXT, 4, '0') AS order_id,
        DATE '2026-01-01' + ((s * 3) % 180) AS order_date
    FROM generate_series(0, 59) AS gs(s)
),
events AS (
    SELECT
        o.*,
        e AS event_sequence
    FROM orders AS o
    CROSS JOIN LATERAL generate_series(
        1,
        2 + (o.order_seq % 3)
    ) AS gs(e)
)
INSERT INTO join_lab.fact_shipment_event (
    shipment_event_id,
    order_id,
    event_sequence,
    event_type,
    carrier,
    event_date,
    shipping_cost
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY order_seq, event_sequence
    )::INTEGER,

    order_id,

    event_sequence,

    CASE
        WHEN event_sequence = 1 THEN 'Picked'
        WHEN event_sequence = 2 THEN 'Shipped'
        WHEN event_sequence = 3 THEN 'In Transit'
        WHEN event_sequence = 4
            AND order_seq % 7 = 0
            THEN 'Delivery Exception'
        WHEN event_sequence = 4
            THEN 'Delivered'
        ELSE 'Unknown'
    END,

    CASE order_seq % 4
        WHEN 0 THEN 'NorthLine Freight'
        WHEN 1 THEN 'Prairie Express'
        WHEN 2 THEN 'Rocky Logistics'
        ELSE 'Polar Transport'
    END,

    order_date + event_sequence,

    ROUND(
        (
            4
            + (event_sequence * 3.75)
            + (order_seq % 8)
        )::NUMERIC,
        2
    )

FROM events;


--Create return_facts_table
CREATE TABLE join_lab.fact_return (
    return_id        INTEGER PRIMARY KEY,
    order_item_id    INTEGER NOT NULL,
    return_date      DATE NOT NULL,
    return_quantity  INTEGER NOT NULL,
    return_reason    TEXT NOT NULL,
    refund_amount    NUMERIC(10,2) NOT NULL
);

--Load return_facts_table
INSERT INTO join_lab.fact_return (
    return_id,
    order_item_id,
    return_date,
    return_quantity,
    return_reason,
    refund_amount
)
SELECT
    g,

    1 + ((g * 11) % 180),

    DATE '2026-04-01' + ((g * 5) % 120),

    1 + (g % 3),

    CASE g % 5
        WHEN 0 THEN 'Damaged'
        WHEN 1 THEN 'Wrong Item'
        WHEN 2 THEN 'Customer Changed Mind'
        WHEN 3 THEN 'Quality Issue'
        ELSE 'Late Delivery'
    END,

    ROUND(
        (
            20
            + ((g * 17) % 180)
        )::NUMERIC,
        2
    )

FROM generate_series(1, 30) AS gs(g);


--Create stg_order_line
CREATE TABLE join_lab.stg_order_line (
    staging_row_id INTEGER PRIMARY KEY,
    source_order_id TEXT NOT NULL,
    customer_id     TEXT,
    sku             TEXT,
    warehouse_code  TEXT,
    units_ordered   INTEGER NOT NULL
);

--Load stg_order_line
INSERT INTO join_lab.stg_order_line (
    staging_row_id,
    source_order_id,
    customer_id,
    sku,
    warehouse_code,
    units_ordered
)
SELECT
    g,

    'SRC-' || LPAD(g::TEXT, 4, '0'),

    CASE
        WHEN g % 19 = 0 THEN NULL
        WHEN g % 17 = 0 THEN 'CUST-999'
        ELSE 'CUST-' || LPAD((((g - 1) % 15) + 1)::TEXT, 3, '0')
    END,

    CASE
        WHEN g % 23 = 0 THEN NULL
        WHEN g % 21 = 0 THEN 'SKU-999'
        ELSE 'SKU-' || LPAD((((g * 5 - 1) % 18) + 1)::TEXT, 3, '0')
    END,

    CASE
        WHEN g % 27 = 0 THEN NULL
        WHEN g % 22 = 0 THEN 'WH-UNKNOWN'

        WHEN g % 5 = 0 THEN 'WH-CGY'
        WHEN g % 5 = 1 THEN 'WH-EDM'
        WHEN g % 5 = 2 THEN 'WH-RDR'
        WHEN g % 5 = 3 THEN 'WH-LEH'
        ELSE 'WH-YMM'
    END,

    ((g * 3) % 10) + 1

FROM generate_series(1, 80) AS gs(g);


