## Drill 78: Predict the rows manually

### **A.** What is the original order revenue?

add the order_items that make up the order = `500`

### **B.** How many rows result from:

`20 rows`

### **C.** What incorrect revenue would be produced by summing item revenue after that join?

`2500`

### **D.** How many rows result from the inner path:

`4 rows`

### **E.** Why are your answers for B and D different?

the order grain affects the number of rows, when the order grain is drilled down to order_items, which breaks down the orders into order items, it multiplys the number of rows in the join table.

### **F.** If your final analytical dataset must contain one row per item, to what grains should you summarize:

`order_item_id`

---

# Drill 79 — When NOT to aggregate

Don't aggregate a fact merely because you're joining it. Aggregate whichever source is too fine-grained for the target analytical grain.

## Drill 80 — Design the grain before writing SQL

### A. TARGET GRAIN:

`order_item_id`

### B. FACT_ORDER_ITEM GRAIN:

`order_item_id`

### C. FACT_SHIPMENT_EVENT GRAIN:

`shipment_event_id`

### D. FACT_RETURN GRAIN:

`return_id`; the best grain to use

Alternatively; `order_item_id`

### E. SHIPMENT TRANSFORMATION REQUIRED:

Transform the shipment fact table grain to order_id

### F. RETURN TRANSFORMATION REQUIRED:

Aggregate to order_item_id

### G. JOIN KEY:

fact_order_item → shipment_summary = `order_id`

JOIN KEY:
fact_order_item → return_summary = `order_item_id`

EXPECTED CARDINALITY:
order item → shipment summary = `many to 1`

EXPECTED CARDINALITY:

order item → return summary = `1 to 0 or 1`

MEASURES SAFE TO SUM AT FINAL GRAIN: `item_revenue, return_count`

MEASURES NOT SAFE TO SUM AT FINAL GRAIN: `shipment_event_count`
