WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           0 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal > 500.00 AND sh.level < 5
),
TopRegions AS (
    SELECT r.r_name, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
    HAVING SUM(s.s_acctbal) > 10000
),
ImportantOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT s.s_name, s.s_acctbal, r.r_name, 
       o.o_orderkey, o.o_orderdate, o_totalprice,
       CASE 
           WHEN o.o_orderdate < CURRENT_DATE - INTERVAL '30 days' 
           THEN 'Archived' 
           ELSE 'Active' 
       END AS order_status,
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue,
       STRING_AGG(DISTINCT p.p_name, ', ') AS parts_provided
FROM SupplierHierarchy sh
LEFT JOIN supplier s ON sh.s_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN ImportantOrders o ON l.l_orderkey = o.o_orderkey
JOIN TopRegions r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
GROUP BY s.s_name, s.s_acctbal, r.r_name, o.o_orderkey, o.o_orderdate
HAVING SUM(l.l_quantity) > 100
ORDER BY net_revenue DESC, s.s_acctbal DESC;
