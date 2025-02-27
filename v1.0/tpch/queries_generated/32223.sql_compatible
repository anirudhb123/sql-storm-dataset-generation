
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, 
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           l.l_suppkey
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    AND l.l_shipdate > l.l_commitdate
)
SELECT 
    p.p_name,
    SUM(COALESCE(f.net_price, 0)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    r.r_name AS region_name
FROM part p
LEFT JOIN FilteredLineItems f ON p.p_partkey = f.l_partkey
LEFT JOIN RankedOrders o ON f.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON f.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > (
    SELECT AVG(p_sub.p_retailprice) FROM part p_sub WHERE p_sub.p_size < 20
)
AND (n.n_comment IS NULL OR n.n_comment LIKE '%important%')
GROUP BY p.p_name, r.r_name
HAVING SUM(COALESCE(f.net_price, 0)) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
