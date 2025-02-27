WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_suppkey
)
SELECT r.r_name,
       n.n_name,
       COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
       SUM(ps.ps_availqty) AS total_available_qty,
       AVG(l.l_extendedprice) AS avg_extended_price,
       MAX(l.l_discount) AS max_discount,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
WHERE l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
  AND (l.l_discount > 0.10 OR l.l_returnflag IS NULL)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5 
   AND SUM(ps.ps_availqty) > 1000
ORDER BY total_suppliers DESC, avg_extended_price DESC;