WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000.00 AND sh.level < 5
),
order_performance AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
customers_with_orders AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(op.order_total), 0) AS total_orders
    FROM customer c
    LEFT JOIN order_performance op ON c.c_custkey = op.o_orderkey
    WHERE c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
    GROUP BY c.c_custkey, c.c_name
),
supplier_region AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT ch.c_name, ch.total_orders, sr.region_name, sr.supplier_count, sh.level
FROM customers_with_orders ch
JOIN supplier_region sr ON sr.region_name = 'AMERICA'
LEFT JOIN supplier_hierarchy sh ON ch.c_custkey = sh.s_suppkey
WHERE ch.total_orders > 0
AND (sh.level IS NULL OR sh.level < 3)
ORDER BY ch.total_orders DESC, sr.supplier_count ASC
LIMIT 10;
