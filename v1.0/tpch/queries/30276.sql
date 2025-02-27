WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 10000
),
lineitem_analysis AS (
    SELECT l.l_orderkey, 
           COUNT(*) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' 
      AND l.l_shipdate <= '1997-12-31'
    GROUP BY l.l_orderkey
),
orders_with_status AS (
    SELECT o.o_orderkey, o.o_orderstatus, l.line_count, l.total_value
    FROM orders o
    JOIN lineitem_analysis l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT r.r_name,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(o.total_value) AS total_order_value,
       AVG(s.total_cost) AS avg_supplier_cost,
       MAX(l.line_count) AS max_line_count
FROM region r
LEFT JOIN nation_hierarchy nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN orders_with_status o ON nh.n_nationkey = o.o_orderkey
LEFT JOIN supplier_summary s ON o.o_orderkey = s.s_suppkey
LEFT JOIN lineitem_analysis l ON o.o_orderkey = l.l_orderkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_order_value DESC
LIMIT 10;