SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'supply_chain_orders'
ORDER BY ordinal_position;


SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'training'
AND table_name = 'supply_chain_orders'
ORDER BY ordinal_position;


