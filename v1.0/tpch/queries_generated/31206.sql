WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.order_level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT l.l_orderkey, COUNT(l.l_linenumber) AS total_lines, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(ss.total_supply_cost) AS avg_supply_cost,
    SUM(ls.total_revenue) AS total_revenue,
    MAX(ls.total_lines) AS max_lines,
    MIN(oh.order_level) AS min_order_level,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
FULL OUTER JOIN Customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
INNER JOIN LineItemStats ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
RIGHT JOIN OrderHierarchy oh ON oh.o_orderkey = ls.l_orderkey
WHERE r.r_name IS NOT NULL
  AND n.n_name IS NOT NULL
  AND p.p_retailprice >= 100
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_revenue DESC;
