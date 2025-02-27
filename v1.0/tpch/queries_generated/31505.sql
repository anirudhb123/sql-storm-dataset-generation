WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (sh.level * 30000)
),
TotalOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
CustomerRegion AS (
    SELECT c.c_custkey, n.r_regionkey
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
AggregatedData AS (
    SELECT 
        cr.r_regionkey, 
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        SUM(oi.l_extendedprice * (1 - oi.l_discount)) AS total_revenue
    FROM CustomerRegion cr
    LEFT JOIN TotalOrders o ON cr.c_custkey = o.o_custkey
    LEFT JOIN lineitem oi ON o.o_orderkey = oi.l_orderkey
    GROUP BY cr.r_regionkey
)
SELECT 
    r.r_name, 
    ad.orders_count, 
    COALESCE(ad.total_revenue, 0) AS total_revenue,
    SUM(s.s_acctbal) OVER (PARTITION BY r.r_regionkey) AS total_supplier_acctbal,
    ROW_NUMBER() OVER (ORDER BY ad.total_revenue DESC) AS revenue_rank
FROM region r
LEFT JOIN AggregatedData ad ON r.r_regionkey = ad.r_regionkey
LEFT JOIN supplier s ON r.r_regionkey = s.s_nationkey
WHERE s.s_acctbal IS NOT NULL
ORDER BY ad.total_revenue DESC
LIMIT 10;
