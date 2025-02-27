WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE sh.level < 10
),
TotalOrder AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemAnalytics AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_orderkey
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(AVG(ts.total_spent), 0) AS avg_order_spent,
    COALESCE(SUM(la.revenue), 0) AS total_revenue,
    COALESCE(MAX(ph.ps_supplycost), 0) AS max_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS status
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN TotalOrder ts ON c.c_custkey = ts.c_custkey
LEFT JOIN LineItemAnalytics la ON ts.c_custkey = la.l_orderkey  
LEFT JOIN PartSupplier ph ON ph.rn = 1
WHERE n.n_name LIKE '%ia%' 
GROUP BY n.n_name
ORDER BY customer_count DESC;