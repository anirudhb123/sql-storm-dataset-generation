WITH SupplierSummary AS (
    SELECT s.n_nationkey, s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.n_nationkey, s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_nationkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
NationPerformance AS (
    SELECT n.n_nationkey, n.n_name, 
           COALESCE(SUM(s.total_available_qty), 0) AS total_available_qty,
           COALESCE(SUM(s.total_supply_value), 0) AS total_supply_value,
           COALESCE(SUM(c.order_count), 0) AS total_orders,
           COALESCE(SUM(c.total_order_value), 0) AS total_order_value
    FROM nation n
    LEFT JOIN SupplierSummary s ON n.n_nationkey = s.n_nationkey
    LEFT JOIN CustomerOrderSummary c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, 
       n.total_available_qty, 
       n.total_supply_value, 
       n.total_orders, 
       n.total_order_value,
       (CASE WHEN n.total_orders > 0 
             THEN n.total_order_value / n.total_orders 
             ELSE 0 END) AS average_order_value,
       (CASE WHEN n.total_available_qty > 0
             THEN n.total_supply_value / n.total_available_qty 
             ELSE 0 END) AS average_supply_value_per_qty
FROM NationPerformance n
ORDER BY n.n_name;
