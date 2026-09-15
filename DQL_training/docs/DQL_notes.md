
COUNT(DISTINCT order_id)returned orders
─────────────── × 100
eligible orders

# DQL foundations: retrieving data

## Key things to note

1. when using `CASE` ,  it is advisable to start with *NULL* checks.

NULL / invalid
      ↓
special business states
      ↓
normal ranges
      ↓
ELSE

## Aggregation

### Grouping by derived expressions

```
SELECT
    CASE
        WHEN quantity >= 100 THEN 'High Volume'
        WHEN quantity >= 50 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_band,

    COUNT(*) AS order_count

FROM supply_chain_orders

GROUP BY
    CASE
        WHEN quantity >= 100 THEN 'High Volume'
        WHEN quantity >= 50 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END;
```

### Date period aggregation

```
SELECT
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(*) AS order_count
FROM supply_chain_orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month;
```

### Average order value

```
SUM(revenue)
/ COUNT(DISTINCT order_id)
```

### KPI Return rate

`Concept:`

```
returned orders
─────────────── × 100
eligible orders
```

the business requires:

```
COUNT(DISTINCT order_id)
```
