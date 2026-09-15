# Relationship reconnaisance

## Determine the grain of every table

### bridge_product_supplier

* The grain of bridge_product_supplier grain is one row per `product_key` & `supplier_key`
* The table composite key are `product_key` & `supplier_key`

### dim_customer

* The grain of dim_customer table is one row per `customer_key`.
* `customer_key` is the primary_key

### dim_date

* The grain of dim-date is one row per full_date
* `full-date` & `date_key` are the primary_key(unique columns)

### dim_product

* The grain is one row per product dimension record
* `product_key` is the primary key

### dim_supplier

* The grain is one row per `supplier_key`
* `supplier_key` is the primary_key

### dim_warehouse

* The grain is one row per `warehouse_key`
* `warehouse_key` is primary key

### fact_order_item

* The grain is one row per order_item
* `order_item_id` is the primary key

### fact_return

* The grain is one row per return transaction
* `return_id` is the primary key

### fact_shipment_event

* The grain is one row per shipment_event
* `shipment_event_id` is the primary key

### stg_order_line

* The grain is one row per `staging_row_id`
* ``staging_row_id`` is the primary key

### product-supplier cardinality

* Many to many relationship since one product can be sourced by more than one supplier and one supplier can provide more than one product

### orders per customers cardinality

* One is to many relationship meaning one customer can makes more than one order

### shipment event per order cardinality

one order can have more than one shipment event event making the relationship one to many relationship.
