WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.total_revenue) AS nation_revenue
    FROM nation n
    LEFT JOIN OrderStats o ON n.n_nationkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
RegionsWithNations AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    sh.s_name AS supplier_name,
    n.n_name AS nation_name,
    COALESCE(nr.nation_revenue, 0) AS revenue,
    rc.rank AS customer_rank,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COALESCE(nr.nation_revenue, 0) DESC) AS regional_rank
FROM RegionsWithNations r
JOIN SupplierHierarchy sh ON sh.s_nationkey = r.r_regionkey
LEFT JOIN NationRevenue nr ON nr.n_nationkey = sh.s_nationkey
JOIN CustomerRanked rc ON rc.c_custkey = sh.s_suppkey
ORDER BY r.r_name, revenue DESC;
