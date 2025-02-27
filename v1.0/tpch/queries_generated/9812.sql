WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_orders_value, 
           COUNT(o.o_orderkey) AS total_orders_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, 
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, 
       ss.s_name, 
       cs.c_name, 
       ss.total_available_qty, 
       ss.total_supply_cost, 
       cs.total_orders_value, 
       cs.total_orders_count
FROM nation_summary ns
JOIN supplier_summary ss ON ns.total_suppliers > 0 AND ss.s_nationkey = ns.n_nationkey
JOIN customer_orders cs ON ns.total_customers > 0 
WHERE ss.total_supply_cost > 10000 AND cs.total_orders_value > 5000
ORDER BY ns.n_name, ss.s_name, cs.c_name;
