WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey AND s.s_acctbal > 500.00
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
high_value_orders AS (
    SELECT os.o_orderkey, os.total_revenue,
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM order_summary os
    WHERE os.total_revenue > 10000
)
SELECT p.p_partkey, p.p_name, p.p_type, p.p_retailprice, 
       COALESCE(SUM(CASE WHEN l.l_shipmode = 'TRUCK' THEN l.l_quantity END), 0) AS truck_quantity,
       COUNT(DISTINCT so.s_suppkey) AS distinct_suppliers,
       MAX(CASE WHEN so.level IS NOT NULL THEN so.level ELSE 0 END) AS max_supplier_level
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy so ON ps.ps_suppkey = so.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
INNER JOIN high_value_orders hvo ON hvo.o_orderkey = l.l_orderkey
GROUP BY p.p_partkey, p.p_name, p.p_type, p.p_retailprice
HAVING SUM(l.l_quantity) > 500
ORDER BY p.p_retailprice DESC
LIMIT 10;
