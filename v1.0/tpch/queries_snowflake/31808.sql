
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RankedOrders AS (
    SELECT o.*, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank,
           SUM(o.o_totalprice) OVER (PARTITION BY o.o_custkey) AS total_spent
    FROM orders o
),
CustomerMetrics AS (
    SELECT c.c_custkey, 
           c.c_name,
           COALESCE(SUM(co.total_spent), 0) AS total_spent, 
           COUNT(co.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN RankedOrders co ON c.c_custkey = co.o_custkey
    LEFT JOIN (
        SELECT l_orderkey, 
               SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM lineitem
        WHERE l_shipdate >= '1996-01-01'
        GROUP BY l_orderkey
    ) AS l ON co.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
EnhancedSupplier AS (
    SELECT sh.s_suppkey, 
           sh.s_name, 
           r.r_name AS region_name, 
           SUM(CASE WHEN cm.total_orders > 0 THEN cm.total_spent ELSE 0 END) AS contributed_revenue,
           COUNT(DISTINCT cm.c_custkey) AS customer_count
    FROM SupplierHierarchy sh
    LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN CustomerMetrics cm ON sh.s_suppkey = cm.c_custkey
    GROUP BY sh.s_suppkey, sh.s_name, r.r_name
)
SELECT es.s_suppkey, 
       es.s_name, 
       es.region_name, 
       es.contributed_revenue,
       es.customer_count,
       CASE 
           WHEN es.contributed_revenue IS NULL THEN 'No Contribution'
           WHEN es.contributed_revenue > 10000 THEN 'High Contribution'
           ELSE 'Moderate Contribution'
       END AS contribution_level
FROM EnhancedSupplier es
ORDER BY es.contributed_revenue DESC, es.customer_count DESC;
