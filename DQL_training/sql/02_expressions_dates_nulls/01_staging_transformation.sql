--check the data
SELECT *
FROM training.supply_chain_orders_raw
--LIMIT 27;

--drill 4: check legitimate missing delivery_dates
SELECT
    order_item_id,
    order_id,
    shipment_status,
    promised_delivery_date,
    actual_delivery_date
FROM training.supply_chain_orders_raw
WHERE actual_delivery_date is NULL AND
        lower(shipment_status) <> 'cancelled'
ORDER BY shipment_status;

--inspect shipment_status to determine delivery_dates legitimacy
SELECT DISTINCT
    shipment_status
FROM training.supply_chain_orders_raw;


--drill 5: missing supplier names
SELECT
    order_item_id,
    supplier_id,
    supplier_name
FROM training.supply_chain_orders_raw
WHERE supplier_name is NULL;


--drill 6: supplier display value
SELECT
    supplier_name,
    coalesce(supplier_name, 'Unknown supplier') as supplier_display
FROM training.supply_chain_orders_raw
LIMIT 30;


--drill 7: preserve truth beside presentation
SELECT
    order_item_id,
    supplier_name,
    coalesce(supplier_name, 'Unknown supplier') as supplier_display
FROM training.supply_chain_orders_raw
WHERE supplier_name is NULL;
--coalesce did not repair the supplier_name, it just produced a different value


--drill 8: find empty supplier_names
SELECT
    order_item_id,
    supplier_id,
    supplier_name
FROM training.supply_chain_orders_raw
WHERE supplier_name = '';

--drill 9: find whitespaces only supplier_names
SELECT
    order_item_id,
    supplier_id,
    supplier_name
FROM training.supply_chain_orders_raw
WHERE trim(supplier_name) = '' AND
        length(supplier_name) > 0;


--drill 10 coalesce trap
SELECT
    supplier_name,
    coalesce(supplier_name, 'Unknown supplier')
FROM training.supply_chain_orders_raw;
--comment: coalesce only converts null values, the '' and '   ' remain the same,
--this is because coalesce checks for none_null values and returns the first none_null values
--if the value is null, it returns values selected in coalesce


--convert blanks into null
SELECT
    order_id,
    supplier_id,
    supplier_name,
    nullif(trim(supplier_name), '') as normalized_supplier
FROM training.supply_chain_orders_raw;


--drill 12: nullif & coalesce
SELECT
    order_id,
    supplier_id,
    supplier_name,
    coalesce(nullif(trim(supplier_name), ''), 'Unknown supplier') as normalized_supplier
FROM training.supply_chain_orders_raw;


--drill 13: clean customer names
--requirements
    --remove outer whitespace
    --convert to lowercase
SELECT
    customer_name,
    lower(trim(customer_name)) as clean_customer_name
FROM training.supply_chain_orders_raw;


--Drill 14: clean supplier names completely
SELECT
    supplier_name,
    lower(trim(COALESCE(NULLIF(supplier_name, ''), 'Uknown_supplier'))) as clean_supplier_name
FROM training.supply_chain_orders_raw;


--Drill 15: standardize customer segments
SELECT DISTINCT
    upper(TRIM(customer_segment)) as clean_customer_segment
FROM training.supply_chain_orders_raw;

    --distinct uncleaned values
    SELECT DISTINCT
        customer_segment
    FROM training.supply_chain_orders_raw;
--Comment: distinct uncleaned customer_segment appear to be more because same value with different
--         casing and or with whitespaces are counted as different values


--Drill 16: shipment_status profiling
SELECT DISTINCT
    shipment_status
FROM training.supply_chain_orders_raw;
    --compare with cleaned shipment_status
    SELECT DISTINCT
        upper(TRIM(shipment_status)) as cleaned_shipment_status
    FROM training.supply_chain_orders_raw;


--Drill 17: standardize seveeral fields simultaneously
SELECT
    order_item_id,
    trim(order_item_id) as cleaned_order_item,
    customer_segment,
    upper(trim(customer_segment)) as cleaned_customer_segment,
    sales_region,
    upper(trim(sales_region)) as cleaned_sales_region,
    shipment_status,
    upper(trim(shipment_status)) as cleaned_shipment_status,
    transport_mode,
    upper(trim(transport_mode)) as cleaned_transport_mode,
    order_priority,
    upper(trim(order_priority)) as cleaned_order_priority
FROM training.supply_chain_orders_raw;


--Drill 18: Length as a quality tool
SELECT
    supplier_name,
    length(supplier_name) as raw_length,
    trim(supplier_name) as cleaned_supplier_name,
    length(trim(supplier_name)) as cleaned_length
FROM training.supply_chain_orders_raw;
--Comment: The rows with differing values are caused by whitespaces;
--           that is why the trimmed values have lesser length


--Drill 19: Detect suspicious id
SELECT
    supplier_id,
    length(supplier_id) as supplier_id_length,
    customer_id,
    length(customer_id) as customer_id_length,
    product_id,
    length(product_id) as product_id_length,
    order_id,
    length(order_id) as order_id_length
FROM training.supply_chain_orders_raw;


--Drill 20: Find suspiciously short names
SELECT
    customer_name,
    length(customer_name) as customer_name_length,
    length(TRIM(customer_name)) as cleaned_customer_length,
    supplier_name,
    length(supplier_name) as supplier_name_length,
    length(trim(supplier_name)) as cleaned_supplier_length
FROM training.supply_chain_orders_raw;


--Drill 21
SELECT
    customer_id,
    substring(trim(customer_id), 1, 3) customer_id_prefix,
    product_id,
    substring(trim(product_id) FROM 5) as product_id_suffix,
    supplier_id,
    substring(trim(supplier_id) FROM 1 FOR 3) as supplier_id_prefix
FROM training.supply_chain_orders_raw;


--Drill 22: investigate prefix consistency
SELECT DISTINCT
    substring(trim(customer_id), 1, 3) customer_id_prefix,
    substring(trim(product_id) FROM 1 FOR 3) as product_id_prefix,
    substring(trim(supplier_id) FROM 1 FOR 3) as supplier_id_prefix
FROM training.supply_chain_orders_raw;
--Comment: the prefix reveal the design used to create the IDs egs all customer_id start with CUS


--Drill 23: Normalized product slug
SELECT
    product_id,
    product_name,
    product_category,
    REPLACE(lower(trim(product_category)), 'safety equipment', 'industrial_safety_equipment') as product_slug
FROM training.supply_chain_orders_raw;


--Drill 24: compact supplier_name
--supplier_name in the table is in the id format; supplier 0001


--Drill 25: supplier descriptor
SELECT
    supplier_id,
    supplier_name,
    (trim(supplier_id) || ' - ' || trim(supplier_name)) as supplier_descriptor
FROM training.supply_chain_orders_raw;
--alternatively..
SELECT
    supplier_id,
    supplier_name,
    concat(trim(supplier_id), ' - ', trim(supplier_name)) as supplier_descriptor
FROM training.supply_chain_orders_raw;


--Drill 26: operational record label
--ORDER_ID | CUSTOMER_NAME | PRODUCT_NAME
SELECT
    order_id,
    customer_name,
    product_name,
    concat(trim(order_id), ' | ', upper(trim(customer_name)), ' | ', upper(trim(product_name))) as operational_record_label
FROM training.supply_chain_orders_raw


--Drill 27: concat vs ||
SELECT
    (trim(supplier_id) || ' - ' || trim(supplier_name)) as double_pipe,
    concat(trim(supplier_id), ' - ', trim(supplier_name)) as concat
FROM training.supply_chain_orders_raw
WHERE supplier_name is null;
--comment: when using double pipe, where one of the values is null, it brings back null
--         but concat; brings back the value that is not null and remains blank in the null value


--Drill 28: split part
SELECT
    supplier_id,
    split_part(supplier_id, '-', 2) as supplier_component
FROM training.supply_chain_orders_raw;


--Drill 29: warehouse/ product composite
SELECT
    order_id,
    split_part(order_id, '-', 2) as order_component
FROM training.supply_chain_orders_raw;


