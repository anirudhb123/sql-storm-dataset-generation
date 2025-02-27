WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, NULL::integer AS parent_suppkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, sh.s_suppkey AS parent_suppkey, sh.s_acctbal + ps.ps_supplycost AS s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
    WHERE sh.s_acctbal + ps.ps_supplycost > 2000
)
, total_sales AS (
    SELECT l.l_partkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY l.l_partkey
)
SELECT r.r_name, 
       COUNT(DISTINCT sh.s_suppkey) AS num_suppliers,
       COALESCE(SUM(ts.total_revenue), 0) AS total_revenue, 
       MAX(sh.level) AS max_level
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
LEFT JOIN total_sales ts ON ts.l_partkey IN (
    SELECT p.p_partkey
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
    AND (p.p_retailprice IS NOT NULL OR p.p_comment LIKE '%special%')
)
WHERE (sh.s_acctbal IS NULL OR sh.s_acctbal < 3000) 
AND (s.s_name LIKE 'Supplier%' OR s.s_name IS NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY r.r_name DESC;
