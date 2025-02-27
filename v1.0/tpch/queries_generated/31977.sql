WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
    WHERE sh.level < 5
), 
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count,
           ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), 
CustomerRegion AS (
    SELECT c.c_custkey, 
           r.r_name AS region_name,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled_orders,
           COALESCE(SUM(o.o_totalprice), 0) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY c.c_custkey, r.r_name
)
SELECT 
    r.region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(cs.total_filled_orders) AS avg_filled_orders,
    SUM(ob.total_revenue) AS total_revenue
FROM CustomerRegion cs
LEFT JOIN OrderSummary ob ON cs.total_orders > 0
JOIN region r ON cs.region_name = r.r_name
WHERE cs.total_filled_orders IS NOT NULL
GROUP BY r.region_name
HAVING AVG(cs.total_filled_orders) > 500
ORDER BY total_revenue DESC;
