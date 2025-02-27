WITH RECURSIVE top_customers AS (
    SELECT c_custkey, c_name, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, tc.level + 1
    FROM top_customers tc
    JOIN customer c ON tc.c_acctbal < c.c_acctbal
    WHERE tc.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
high_value_orders AS (
    SELECT os.o_orderkey, os.revenue, COUNT(l.l_orderkey) AS line_items
    FROM order_summary os
    JOIN lineitem l ON os.o_orderkey = l.l_orderkey
    WHERE os.revenue > 100000
    GROUP BY os.o_orderkey, os.revenue
)
SELECT c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(os.revenue) AS total_revenue,
       COALESCE(SUM(sd.total_supply_cost), 0) AS total_supply_cost,
       MAX(tc.level) AS customer_level
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN order_summary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN supplier_details sd ON os.o_orderkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
)
LEFT JOIN top_customers tc ON c.c_custkey = tc.c_custkey
WHERE c.c_mktsegment = 'BUILDING'
GROUP BY c.c_name
HAVING total_revenue > 50000
ORDER BY total_revenue DESC;
