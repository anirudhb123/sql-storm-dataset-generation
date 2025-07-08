
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           s.s_nationkey,
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           s.s_nationkey,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
)
SELECT c.c_name,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(l.l_quantity) AS avg_quantity,
       MAX(s.s_acctbal) AS max_supplier_acctbal,
       LISTAGG(DISTINCT s.s_name, ', ') WITHIN GROUP (ORDER BY s.s_name) AS supplier_names
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE o.o_orderstatus = 'O'
AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY c.c_name
HAVING SUM(l.l_extendedprice) > 100000
ORDER BY total_revenue DESC
LIMIT 10;
