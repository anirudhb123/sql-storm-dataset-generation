WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
)
SELECT n.n_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       MAX(s.s_acctbal) AS max_supplier_acctbal,
       COUNT(DISTINCT sh.s_suppkey) AS suppliers_in_hierarchy
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
WHERE o.o_orderstatus = 'O' 
  AND l.l_shipdate >= '2022-01-01'
  AND (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL) 
  AND n.n_comment IS NOT NULL
GROUP BY n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY total_revenue DESC
LIMIT 10;
