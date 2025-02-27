WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
)
SELECT COALESCE(r.r_name, 'Unknown Region') AS region_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       (SELECT COUNT(*) FROM orders o WHERE o.o_orderstatus = 'F') AS finalized_orders,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_nationkey, ')'), ', ') AS suppliers
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN region r ON (SELECT n.r_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey) = r.r_regionkey
JOIN PartSupplierInfo psi ON l.l_partkey = psi.p_partkey AND psi.rn = 1
LEFT JOIN SupplierHierarchy sh ON psi.s_nationkey = sh.s_nationkey
WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY r.r_name
ORDER BY total_revenue DESC;
