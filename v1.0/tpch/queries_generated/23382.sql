WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 
AggregatedLineitems AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_price
    FROM lineitem
    GROUP BY l_orderkey
), 
RankedOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS order_rank
    FROM orders
)
SELECT r.r_name, 
       SUM(p.ps_supplycost * pli.total_price) AS total_supplier_cost,
       COUNT(DISTINCT ch.c_custkey) AS unique_customers,
       STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', COALESCE(s.s_name, 'Unknown Supplier')), ', ') AS suppliers_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
JOIN AggregatedLineitems pli ON p.ps_partkey = pli.l_orderkey
JOIN Customer ch ON ch.c_nationkey = n.n_nationkey
JOIN RankedOrders o ON o.o_custkey = ch.c_custkey AND o.order_rank = 1
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(p.ps_supplycost * pli.total_price) > 5000
ORDER BY total_supplier_cost DESC
LIMIT 10;
