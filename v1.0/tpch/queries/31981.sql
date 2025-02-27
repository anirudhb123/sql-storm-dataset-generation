
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal AND sh.depth < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_partkey, p.p_name, p.p_retailprice, 
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS rank,
       (SELECT COUNT(*) FROM SupplierHierarchy) AS total_suppliers,
       r.r_name AS region
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey 
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice BETWEEN 100 AND 500
AND l.l_shipdate >= DATE '1997-01-01'
AND l.l_returnflag = 'N'
GROUP BY p.p_partkey, p.p_name, p.p_retailprice, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_orders DESC, total_revenue DESC;
