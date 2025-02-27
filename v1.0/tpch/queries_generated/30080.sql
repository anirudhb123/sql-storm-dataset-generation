WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
),
TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name,
    SUM(COALESCE(tv.total_value, 0)) AS sum_total_value,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    AVG(pd.avg_supply_cost) AS avg_supply_cost,
    STRING_AGG(pd.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN TotalOrderValue tv ON sh.s_suppkey = tv.o_orderkey
LEFT JOIN PartDetails pd ON pd.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_suppkey = sh.s_suppkey)
WHERE r.r_name IS NOT NULL
AND (sh.level > 1 OR s.s_nationkey IS NULL)
GROUP BY r.r_name
ORDER BY sum_total_value DESC, avg_supply_cost ASC;
