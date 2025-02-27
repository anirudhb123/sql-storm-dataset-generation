WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE s2.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
NationRevenue AS (
    SELECT n.n_name, SUM(os.total_revenue) AS total_region_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY n.n_name
),
SupplierRanked AS (
    SELECT sh.s_suppkey, sh.s_name, n.n_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY sh.level DESC) AS region_rank
    FROM SupplierHierarchy sh
    JOIN nation n ON sh.s_nationkey = n.n_nationkey
)
SELECT sr.s_name, sr.n_name, nr.total_region_revenue,
       CASE WHEN nr.total_region_revenue IS NULL THEN 'No Revenue' ELSE 'Revenue Exists' END AS revenue_status
FROM SupplierRanked sr
LEFT JOIN NationRevenue nr ON sr.n_name = nr.n_name
WHERE sr.region_rank <= 5
ORDER BY nr.total_region_revenue DESC, sr.n_name;
