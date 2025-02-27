WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, 
           0 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, s.s_comment, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
RankedOrders AS (
    SELECT os.o_custkey, os.order_count, os.total_revenue,
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
)
SELECT rh.s_name, COUNT(DISTINCT ro.o_custkey) AS customer_count,
       SUM(COALESCE(ro.total_revenue, 0)) AS total_order_revenue,
       MAX(ro.order_count) AS max_orders
FROM SupplierHierarchy rh
LEFT JOIN RankedOrders ro ON rh.s_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ro.o_custkey)
GROUP BY rh.s_name
ORDER BY total_order_revenue DESC
LIMIT 10;
