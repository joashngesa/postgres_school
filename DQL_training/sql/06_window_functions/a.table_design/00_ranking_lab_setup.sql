-- Level 2 Ranking Engineering: synthetic, reproducible PostgreSQL lab
BEGIN;
CREATE SCHEMA IF NOT EXISTS ranking_lab;
DROP TABLE IF EXISTS ranking_lab.shipment_exceptions, ranking_lab.inventory_snapshots, ranking_lab.customer_order_metrics, ranking_lab.fleet_delivery_performance, ranking_lab.warehouse_inventory, ranking_lab.supplier_performance CASCADE;
CREATE TABLE ranking_lab.supplier_performance (record_id integer PRIMARY KEY, supplier_id text NOT NULL, region text NOT NULL, reporting_month date NOT NULL, performance_score numeric(5,2), on_time_rate numeric(5,2), UNIQUE(supplier_id,region,reporting_month));
CREATE TABLE ranking_lab.warehouse_inventory (inventory_id integer PRIMARY KEY, warehouse_city text NOT NULL, category text NOT NULL, sku text NOT NULL, available_units integer, reorder_point integer NOT NULL);
CREATE TABLE ranking_lab.fleet_delivery_performance (driver_id text PRIMARY KEY, depot text NOT NULL, completed_deliveries integer NOT NULL, on_time_pct numeric(5,2), avg_delay_minutes numeric(7,2));
CREATE TABLE ranking_lab.customer_order_metrics (customer_id text NOT NULL, market text NOT NULL, reporting_month date NOT NULL, order_count integer NOT NULL, net_revenue numeric(12,2) NOT NULL, PRIMARY KEY(customer_id,market,reporting_month));
CREATE TABLE ranking_lab.inventory_snapshots (snapshot_id integer PRIMARY KEY, warehouse_city text NOT NULL, sku text NOT NULL, observed_at timestamp NOT NULL, ingested_at timestamp NOT NULL, source_revision integer NOT NULL, available_units integer NOT NULL);
CREATE TABLE ranking_lab.shipment_exceptions (exception_id integer PRIMARY KEY, shipment_id text NOT NULL, region text NOT NULL, severity text NOT NULL CHECK (severity IN ('Low','Medium','High','Critical')), delay_hours integer, reported_at timestamp NOT NULL);
INSERT INTO ranking_lab.supplier_performance
SELECT 1000 + r*100 + m*20 + s, 'SUP-'||lpad(s::text,3,'0'), (ARRAY['West','Prairies','Central'])[r], make_date(2026,8+m,1), (ARRAY[96,96,92,88,88,75,65,NULL::integer])[((s+r+m-3)%8)+1], (ARRAY[99,99,95,91,91,85,80,NULL::integer])[((s+r+m-3)%8)+1]
FROM generate_series(1,3) r CROSS JOIN generate_series(0,1) m CROSS JOIN generate_series(1,8) s;
INSERT INTO ranking_lab.warehouse_inventory
SELECT r*100+s, (ARRAY['Edmonton','Calgary','Vancouver','Winnipeg','Toronto','Montreal'])[r], (ARRAY['Electronics','Food','Medical'])[((s-1)%3)+1], 'SKU-'||lpad(s::text,3,'0'), CASE WHEN s=9 AND r%2=0 THEN NULL ELSE (ARRAY[300,300,175,175,90,40,40,0,0,12,12,600])[((s+r-2)%12)+1] END, 75
FROM generate_series(1,6) r CROSS JOIN generate_series(1,12) s;
INSERT INTO ranking_lab.fleet_delivery_performance
SELECT 'DRV-'||lpad((r*100+s)::text,3,'0'), (ARRAY['Edmonton','Calgary','Vancouver','Winnipeg'])[r], 40+s*4, (ARRAY[100,98,98,95,95,95,90,85,85,80,70,70])[((s+r-2)%12)+1], (ARRAY[0,2,2,5,5,5,10,15,15,20,30,30])[((s+r-2)%12)+1]
FROM generate_series(1,4) r CROSS JOIN generate_series(1,12) s;
INSERT INTO ranking_lab.customer_order_metrics
SELECT 'CUS-'||lpad(s::text,3,'0'), (ARRAY['Canada West','Canada Central','US North'])[r], make_date(2026,8+m,1), 1+((s*3+r+m)%18), (ARRAY[15000,15000,12000,10000,10000,7500,6000,6000,4500,3000,2000,1000])[((s+r+m-2)%12)+1]
FROM generate_series(1,3) r CROSS JOIN generate_series(0,1) m CROSS JOIN generate_series(1,12) s;
INSERT INTO ranking_lab.inventory_snapshots
SELECT r*1000+s*10+v, (ARRAY['Edmonton','Calgary','Vancouver'])[r], 'SKU-'||lpad(s::text,3,'0'), timestamp '2026-10-15 08:00:00' + ((v-1)/2)*interval '1 hour', timestamp '2026-10-15 08:05:00' + (v-1)*interval '12 minutes', v, 100+r*10+s*3-v*2
FROM generate_series(1,3) r CROSS JOIN generate_series(1,6) s CROSS JOIN generate_series(1,4) v;
INSERT INTO ranking_lab.shipment_exceptions
SELECT r*100+s, 'SHIP-'||lpad((r*100+s)::text,4,'0'), (ARRAY['West','Prairies','Central'])[r], (ARRAY['Critical','High','High','Medium','Medium','Low'])[((s+r-2)%6)+1], (ARRAY[48,24,24,12,12,3])[((s+r-2)%6)+1], timestamp '2026-10-10 07:00:00' + s*interval '1 hour'
FROM generate_series(1,3) r CROSS JOIN generate_series(1,12) s;
COMMIT;
-- Validation: expect 48, 72, 48, 72, 72, 36 rows respectively.
SELECT
    'supplier_performance' AS table_name,
    count(*) AS rows
    FROM ranking_lab.supplier_performance
UNION ALL
SELECT
    'warehouse_inventory',
    count(*)
FROM ranking_lab.warehouse_inventory
UNION ALL
SELECT
    'fleet_delivery_performance',
    count(*)
FROM ranking_lab.fleet_delivery_performance
UNION ALL
SELECT
    'customer_order_metrics',
    count(*)
    FROM ranking_lab.customer_order_metrics
UNION ALL
SELECT
    'inventory_snapshots',
    count(*)
FROM ranking_lab.inventory_snapshots
UNION ALL
SELECT 'shipment_exceptions',
    count(*)
FROM ranking_lab.shipment_exceptions;
