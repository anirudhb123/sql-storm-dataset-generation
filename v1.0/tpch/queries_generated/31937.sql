WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.s_nationkey, s.s_acctbal + (sh.s_acctbal * 0.1) AS s_acctbal, level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal + (sh.s_acctbal * 0.1) > sh.s_acctbal
),
CombinedData AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity * (1 - l.l_discount)) AS total_revenue, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity * (1 - l.l_discount)) DESC) AS rn
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    n.n_name,
    SUM(COALESCE(cs.total_revenue, 0)) AS total_revenue,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    MAX(sh.s_acctbal) AS max_supplier_balance
FROM nation n
LEFT JOIN CombinedData cs ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.p_partkey % 1000) 
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING total_revenue > 10000
ORDER BY total_revenue DESC
LIMIT 10;
