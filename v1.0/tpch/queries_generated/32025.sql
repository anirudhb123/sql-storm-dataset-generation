WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 25000
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
), DynamicPart AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, p.p_retailprice * ps.ps_availqty AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_brand = 'BrandX') 
    AND (ps.ps_availqty > 100 OR ps.ps_supplycost < 20)
)
SELECT 
    r.r_name,
    SUM(dp.total_value) AS total_part_value,
    AVG(coalesce(sh.s_acctbal, 0)) AS avg_supplier_acctbal,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN DynamicPart dp ON s.s_suppkey = dp.ps_suppkey
LEFT JOIN RankedOrders ro ON s.s_suppkey = ro.o_orderkey
WHERE r.r_comment IS NULL OR r.r_comment LIKE '%global%'
GROUP BY r.r_name
HAVING SUM(dp.total_value) > 1000000
ORDER BY total_part_value DESC;
