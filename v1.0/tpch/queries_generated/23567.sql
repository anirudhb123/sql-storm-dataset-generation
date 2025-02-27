WITH ranked_parts AS (
    SELECT p.p_partkey, p.p_name, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
), 
supplier_stats AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS total_parts, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
customer_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -12, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
)
SELECT ns.n_name, 
       SUM(ps.ps_availqty) AS total_available_qty, 
       MAX(o.total_lineitem_value) AS max_order_value,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       COALESCE(AVG(ss.total_supply_cost), 0) AS avg_supply_cost,
       STRING_AGG(DISTINCT r.r_name, ', ') AS region_names
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN customer c ON c.c_nationkey = ns.n_nationkey
LEFT JOIN customer_orders o ON o.o_custkey = c.c_custkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
WHERE ns.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%')
  AND (s.s_acctbal IS NOT NULL OR s.s_comment IS NULL)
GROUP BY ns.n_name
HAVING SUM(ps.ps_availqty) > (SELECT AVG(ps_availqty) FROM partsupp)
   OR COUNT(DISTINCT o.o_orderkey) = 0
ORDER BY total_available_qty DESC, unique_customers ASC 
OFFSET 5 ROWS;
