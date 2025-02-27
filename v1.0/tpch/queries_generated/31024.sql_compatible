
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
)

SELECT
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT supp.s_suppkey) AS num_suppliers,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    MAX(ps.ps_availqty) AS max_availqty,
    SUM(l.l_quantity * (1 - l.l_discount)) AS total_discounted_revenue,
    DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY AVG(ps.ps_supplycost) DESC) AS brand_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier supp ON ps.ps_suppkey = supp.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE p.p_size > 20
  AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
  AND l.l_returnflag IS NULL
  AND EXISTS (SELECT 1 FROM customer c WHERE c.c_nationkey = supp.s_nationkey AND c.c_acctbal > 1000)
GROUP BY p.p_partkey, p.p_name, p.p_brand
HAVING COUNT(DISTINCT supp.s_suppkey) > 0
ORDER BY total_discounted_revenue DESC
LIMIT 10;
