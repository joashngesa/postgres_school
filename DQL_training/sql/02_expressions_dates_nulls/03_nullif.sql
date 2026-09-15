SELECT *
FROM training.supply_chain_orders_raw;


--NULLIFS as defensive SQL
--Drill 46: locate zero quantities
SELECT
    units_ordered,
    NULLIF(units_ordered::INTEGER, 0) as cleaned_uits_ordered
FROM training.supply_chain_orders_raw;


--Drill 47: Dangerous division
SELECT
    order_item_id,
    shipping_cost,
    units_ordered,
    ROUND(shipping_cost::NUMERIC / NULLIF(units_ordered::NUMERIC, 0), 2) as shipping_cost_per_unit
FROM training.supply_chain_orders_raw;


--Drill 48: coalesce + nullif trap
SELECT
    order_item_id,
    shipping_cost,
    units_ordered,
    ROUND(COALESCE(shipping_cost::NUMERIC / NULLIF(units_ordered::NUMERIC, 0), 0), 2) as shipping_cost_per_unit
FROM training.supply_chain_orders_raw;
--comment: coalesce returns all null values as 0 which might give a misleading business meaning, egs
--          shipping_cost_per_unit being 0 means that their was 0 expense whereas the units ordered was 0

--CASE
--Drill 49: Quantity quality
SELECT
    units_ordered,
    case
        when units_ordered::INTEGER < 0 then 'invalid_cost'
        when units_ordered::INTEGER = 0 then 'zero_cost'
        else 'valid'
    end as quantity_quality
FROM training.supply_chain_orders_raw;


--Drill 50: Cost quality
SELECT
    unit_cost,
    case
        when unit_cost::NUMERIC < 0 then 'invalid cost'
        when unit_cost::NUMERIC = 0 then 'zero cost'
        else 'valid'
    end as cost_quality
FROM training.supply_chain_orders_raw;


--Drill 51: shipping cost quality
SELECT
    shipping_cost,
    case
        when shipping_cost::NUMERIC < 0 then 'invalid shipping cost'
        when shipping_cost::NUMERIC = 0 then 'no shipping cost'
        ELSE 'valid shipping cost'
    end as shipping_cost_quality
FROM training.supply_chain_orders_raw;



--Drill 52: supplier quality
SELECT
    supplier_id,
    supplier_name,
    CASE
        WHEN supplier_name is NULL or
            trim(supplier_name) = '' THEN 'missing supplier'
        ELSE 'valid supplier'
    end as supplier_quality
FROM training.supply_chain_orders_raw;


--Drill 53: case ordering
SELECT
    order_id,
    units_ordered,
    unit_price,
    units_ordered::INTEGER * unit_price::NUMERIC as gross_line_value,
    CASE
        WHEN units_ordered::INTEGER * unit_price::NUMERIC >= 50000 THEN 'very high'
        WHEN units_ordered::INTEGER * unit_price::NUMERIC >= 20000 THEN 'high'
        WHEN units_ordered::INTEGER * unit_price::NUMERIC >= 5000 THEN 'medium'
        WHEN units_ordered::INTEGER * unit_price::NUMERIC > 0 THEN 'standard'
        ELSE 'invalid'
    END AS order_value_band
FROM training.supply_chain_orders_raw;



--Drill 54:
    --  -> 0
    --  >= 5,000
    --  >= 20,000
    --  >= 50,000
SELECT
    order_id,
    units_ordered,
    unit_price,
    units_ordered::INTEGER * unit_price::NUMERIC as gross_line_value,
    CASE
        WHEN units_ordered::INTEGER * unit_price::NUMERIC > 0 THEN 'standard'
        WHEN units_ordered::INTEGER * unit_price::NUMERIC >= 5000 THEN 'medium'
        WHEN units_ordered::INTEGER * unit_price::NUMERIC >= 20000 THEN 'high'
        WHEN units_ordered::INTEGER * unit_price::NUMERIC >= 50000 THEN 'very high'
        ELSE 'invalid'
    END AS order_value_band
FROM training.supply_chain_orders_raw;
--comment: the order does not work because the first condition will; always be true thus that is what case will alsways pick.
--         that is the reason why the column will always read standard
