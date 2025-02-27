WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT p.p_partkey, p.p_name, p.p_retailprice,
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE NULL END), 0) AS total_returned,
       MAX(CASE WHEN c.c_mktsegment = 'BUILDING' THEN o.o_totalprice ELSE NULL END) AS max_building_order,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       AVG(ps.ps_supplycost) AS avg_supply_cost,
       STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_retailprice > 100
  AND EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_suppkey = s.s_suppkey)
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
ORDER BY total_orders DESC, p.p_name
LIMIT 10;
