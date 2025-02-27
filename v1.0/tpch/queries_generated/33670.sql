WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_aggregates AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           AVG(l.l_quantity) AS avg_quantity,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name,
       n.n_name,
       SUM(l.revenue) AS total_revenue,
       AVG(ss.total_supply_cost) AS avg_supply_cost,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       MAX(oh.level) AS max_order_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem_aggregates l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier_stats ss ON l.l_orderkey IN (SELECT distinct ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%Lubricant%'))
LEFT JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY r.r_name, n.n_name
HAVING total_orders > 50 AND total_revenue IS NOT NULL
ORDER BY total_revenue DESC, r.r_name ASC;
