WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal > sh.s_acctbal
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
TotalLineItemSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
)
SELECT COALESCE(n.n_name, 'Unknown') AS nation_name, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.total_sales) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedOrders o ON s.s_suppkey = o.o_orderkey
LEFT JOIN TotalLineItemSales l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
WHERE s.s_acctbal IS NOT NULL 
  AND (l.total_sales IS NOT NULL OR sp.ps_availqty IS NOT NULL)
GROUP BY n.n_name
HAVING SUM(l.total_sales) > 10000 OR COUNT(DISTINCT o.o_orderkey) > 50
ORDER BY total_revenue DESC, avg_supplier_acctbal ASC
WITH TIES;
