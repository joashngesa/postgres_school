--Drill 30: Convert order_item_id
SELECT
    order_item_id,
    order_item_id::INTEGER as converted_order_item_id
FROM training.supply_chain_orders_raw;
--use cast
SELECT
    order_item_id,
    cast(order_item_id as INTEGER) as converted_order_item_id
FROM training.supply_chain_orders_raw;


--Drill 31: convert quantity
SELECT
    units_ordered,
    trim(units_ordered)::INTEGER as converted_units_ordered
FROM training.supply_chain_orders_raw;



--Drill 32: convert numeric financial columns
SELECT
    unit_price,
    cast(trim(unit_price) as NUMERIC) as converted_unit_price,
    unit_cost,
    cast(trim(unit_cost) as NUMERIC) as converted_unit_cost,
    discount_rate,
    cast(trim(discount_rate) as NUMERIC) as converted_discount_rate,
    shipping_cost,
    cast(trim(shipping_cost) as NUMERIC) as converted_shipping_cost
FROM training.supply_chain_orders_raw;



--Drill 33: convert order_date
SELECT
    order_date,
    trim(order_date)::DATE as converted_order_date
FROM training.supply_chain_orders_raw;



--Drill 34: convert delivery_dates
SELECT
    promised_delivery_date,
    cast(trim(promised_delivery_date) as DATE) as converted_promised_delivery_date,
    actual_delivery_date,
    trim(actual_delivery_date)::DATE as converted_actual_delivery_date
FROM training.supply_chain_orders_raw;
--Comment: casting dates where the value is null brings back null



--Drill 35: boolean conversion
SELECT
    returned,
    trim(returned)::BOOLEAN as returned_boolean
FROM training.supply_chain_orders_raw;



--Drill 36: timestamp conversion
SELECT
    loaded_at,
    cast(trim(loaded_at) as TIMESTAMPTZ) as loaded_timestamp
FROM training.supply_chain_orders_raw;


--Drill 37: Gross order_line value
SELECT
    units_ordered,
    unit_price,
    (units_ordered::INTEGER * unit_price::NUMERIC) as gross_line_value
FROM training.supply_chain_orders_raw;


Drill 38: gross margin amount
SELECT
    unit_price,
    unit_cost,
    (unit_price::numeric - unit_cost::numeric) as unit_margin,
    units_ordered,
    (unit_price::numeric - unit_cost::numeric) * units_ordered::INTEGER as line_margin
FROM training.supply_chain_orders_raw;


--Drill 39: discount amount
SELECT
    unit_price,
    units_ordered,
    ((unit_price::NUMERIC * units_ordered::INTEGER) * discount_rate::NUMERIC ) as discount_amount
FROM training.supply_chain_orders_raw;



--Drill 40: net merchandize value
SELECT
    units_ordered,
    unit_price,
    discount_rate,
    (units_ordered::INTEGER * unit_price::NUMERIC) - ((unit_price::NUMERIC * units_ordered::INTEGER) * discount_rate::NUMERIC ) as net_merchandize_value
FROM training.supply_chain_orders_raw;


--Drill 41:landed/order_line_cost
SELECT
    order_id,
    unit_price,
    unit_cost,
    discount_rate,
    shipping_cost,
    units_ordered,
    ((unit_price::NUMERIC * units_ordered::INTEGER) -
        ((unit_price::NUMERIC * units_ordered::INTEGER) * discount_rate::NUMERIC ) -
            (shipping_cost::NUMERIC + (unit_cost::NUMERIC * units_ordered::INTEGER))) as profit_margin
FROM training.supply_chain_orders_raw;
--Comment: total income minus total expenses to calculate profit margin



--Drill 42: Round
SELECT
    unit_price,
    ROUND(unit_price::NUMERIC, 1) as rounded_unit_price,
    unit_cost,
    ROUND(unit_cost::NUMERIC,1) as rounded_unit_cost
FROM training.supply_chain_orders_raw


--Drill 43: ceil operational exercise
SELECT
    units_ordered,
    ceil(units_ordered::INTEGER / 25.0) as containers_required
FROM training.supply_chain_orders_raw;


--Drill 44: floor operational exercise
--Any remainder does not form another complete pallet.
SELECT
    units_ordered,
    floor(units_ordered::INTEGER / 40.0) as pallets_required
FROM training.supply_chain_orders_raw;


--Drill 45: ABS investigation
SELECT
    units_ordered,
    abs(units_ordered::INTEGER) as absolute_units_ordered
FROM training.supply_chain_orders_raw;


--Bonus
SELECT
    units_ordered,
    units_ordered::INTEGER as converted_quantity,
    CAST(units_ordered as INTEGER) as quantity_cast
FROM training.supply_chain_orders_raw;

SELECT
    actual_delivery_date,
    actual_delivery_date::DATE as double_piped,
    CAST(actual_delivery_date as date) as CAST
FROM training.supply_chain_orders_raw;

SELECT * FROM training.supply_chain_orders_raw;
