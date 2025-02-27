
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
    WHERE s.s_acctbal > 30000
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
PartSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 20 AND 30
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    sh.s_name AS supplier_name,
    ro.o_orderkey,
    ps.p_name,
    ps.total_available,
    ps.avg_cost,
    ro.o_totalprice,
    CASE 
        WHEN ro.order_rank <= 5 THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_category,
    COALESCE(n.n_name, 'Unknown') AS nation_name
FROM SupplierHierarchy sh
FULL OUTER JOIN RankedOrders ro ON sh.s_suppkey = ro.o_orderkey
JOIN PartSummary ps ON ps.total_available > 100 AND ps.avg_cost < 50
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
WHERE sh.s_acctbal IS NOT NULL
  AND ps.total_available IS NOT NULL
ORDER BY supplier_name, ro.o_orderkey;
