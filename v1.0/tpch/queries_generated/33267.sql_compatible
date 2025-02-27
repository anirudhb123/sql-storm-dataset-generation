
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
HighRevenueSuppliers AS (
    SELECT sph.s_suppkey, sph.s_name, SUM(os.total_revenue) AS combined_revenue
    FROM SupplierHierarchy sph
    JOIN OrderStatistics os ON sph.s_suppkey = os.o_orderkey
    GROUP BY sph.s_suppkey, sph.s_name
    HAVING SUM(os.total_revenue) > 5000
)
SELECT s.s_name, 
       COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS return_quantity,
       COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
       AVG(l.l_extendedprice) AS avg_price_per_item,
       COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM supplier s
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
GROUP BY s.s_name
HAVING COALESCE(SUM(l.l_quantity), 0) > 10000
ORDER BY total_orders DESC;
