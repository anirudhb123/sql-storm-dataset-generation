WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate > '2022-01-01' AND o.o_totalprice / NULLIF(o.o_shippriority, 0) > 1000
),
LineitemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(*) AS line_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipmode IN ('AIR', 'GROUND')
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(CASE 
           WHEN (o.o_totalprice > (SELECT AVG(fo2.o_totalprice) FROM FilteredOrders fo2 WHERE fo2.rn <= 10)
                 AND EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = n.n_nationkey))
           THEN l.revenue 
           ELSE 0 END) AS total_revenue,
       MAX(l.line_count) AS max_lines_spent
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN LineitemStats l ON l.l_orderkey = o.o_orderkey
WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
   AND SUM(l.revenue) IS NOT NULL
ORDER BY total_revenue DESC;
