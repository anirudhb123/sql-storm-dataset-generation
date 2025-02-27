WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, 
           CONCAT(sh.hierarchy_path, ' -> ', s.s_name)
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_order_count AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
biggest_customers AS (
    SELECT c.c_custkey, c.c_name, cc.order_count
    FROM customer c
    JOIN customer_order_count cc ON c.c_custkey = cc.c_custkey
    WHERE cc.order_count > (
        SELECT AVG(order_count) FROM customer_order_count
    )
),
nation_supplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT r.r_name, ns.supplier_count, COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
       STRING_AGG(DISTINCT h.o_orderkey::text, ', ') AS high_value_order_keys
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy h ON n.n_nationkey = h.s_suppkey
LEFT JOIN nation_supplier ns ON n.n_name = ns.n_name
WHERE ns.supplier_count IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM biggest_customers b 
      WHERE b.c_custkey IN (
          SELECT o.o_custkey FROM orders o 
          WHERE o.o_totalprice > 1000
      )
  )
GROUP BY r.r_name, ns.supplier_count
ORDER BY r.r_name;
