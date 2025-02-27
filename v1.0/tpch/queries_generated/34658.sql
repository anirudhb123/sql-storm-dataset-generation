WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500.00 AND sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT p.p_name, 
       COUNT(DISTINCT lo.l_orderkey) AS total_orders, 
       SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
       AVG(lo.l_quantity) AS avg_quantity,
       MAX(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_quantity ELSE NULL END) AS max_returned_quantity,
       r.r_name AS region_name,
       COALESCE(SH.level, 0) AS supplier_level
FROM part p
LEFT JOIN lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN orders o ON lo.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy SH ON n.n_nationkey = SH.s_nationkey
WHERE p.p_retailprice IS NOT NULL
  AND o.o_orderdate >= '2022-01-01'
  AND (p.p_size BETWEEN 1 AND 20 OR p.p_mfgr LIKE 'Manufacturer%')
GROUP BY p.p_name, r.r_name, SH.level
HAVING SUM(lo.l_extendedprice) > 10000.00
ORDER BY total_revenue DESC
LIMIT 10;
