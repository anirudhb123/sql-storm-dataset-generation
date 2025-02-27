WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 1000
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
AvailableParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SubQueryResults AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey AND l.l_shipdate >= '2022-01-01'
    GROUP BY p.p_partkey
)
SELECT r.r_name, 
       SUM(rp.total_revenue) AS total_revenue,
       AVG(CASE WHEN sh.level IS NOT NULL THEN sh.s_acctbal ELSE 0 END) AS avg_supplier_acctbal
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
JOIN SubQueryResults rp ON EXISTS (
    SELECT 1
    FROM orders o
    JOIN RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    WHERE ro.order_rank = 1 AND o.o_totalprice > 1000
)
WHERE sh.s_acctbal IS NOT NULL OR rp.total_revenue > 0
GROUP BY r.r_name
HAVING SUM(rp.total_revenue) > 5000
ORDER BY r.r_name;
