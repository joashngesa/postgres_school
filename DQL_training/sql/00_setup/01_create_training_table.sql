CREATE SCHEMA IF NOT EXISTS training;

DROP TABLE IF EXISTS training.supply_chain_orders;

CREATE TABLE training.supply_chain_orders (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    customer_id VARCHAR(20) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_segment VARCHAR(30) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    supplier_id VARCHAR(20) NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    warehouse_city VARCHAR(50) NOT NULL,
    sales_region VARCHAR(30) NOT NULL,
    shipment_status VARCHAR(30) NOT NULL,
    transport_mode VARCHAR(30) NOT NULL,
    units_ordered INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    unit_cost NUMERIC(10, 2) NOT NULL,
    discount_rate NUMERIC(5, 4) NOT NULL DEFAULT 0,
    shipping_cost NUMERIC(10, 2) NOT NULL,
    promised_delivery_date DATE NOT NULL,
    actual_delivery_date DATE,
    returned BOOLEAN NOT NULL DEFAULT FALSE,
    order_priority VARCHAR(20) NOT NULL,
    batch_id VARCHAR(30) NOT NULL,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--Creating table for raw data for phase 2
DROP TABLE IF EXISTS training.supply_chain_orders_raw;

CREATE TABLE training.supply_chain_orders_raw (
    order_item_id            VARCHAR,
    order_id                 VARCHAR,
    order_date               VARCHAR,

    customer_id              VARCHAR,
    customer_name            VARCHAR,
    customer_segment         VARCHAR,

    product_id               VARCHAR,
    product_name             VARCHAR,
    product_category         VARCHAR,

    supplier_id              VARCHAR,
    supplier_name            VARCHAR,

    warehouse_city           VARCHAR,
    sales_region             VARCHAR,
    shipment_status          VARCHAR,
    transport_mode           VARCHAR,

    units_ordered            VARCHAR,
    unit_price               VARCHAR,
    unit_cost                VARCHAR,
    discount_rate            VARCHAR,
    shipping_cost            VARCHAR,

    promised_delivery_date   VARCHAR,
    actual_delivery_date     VARCHAR,

    returned                 VARCHAR,
    order_priority           VARCHAR,
    batch_id                 VARCHAR,
    loaded_at                VARCHAR
);
