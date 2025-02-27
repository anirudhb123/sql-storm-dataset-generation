WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           s.s_nationkey,
           CAST(s.s_name AS varchar(100)) AS full_name,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT ps.suppkey, 
           sp.s_name, 
           sp.s_acctbal,
           sp.s_nationkey,
           CAST(CONCAT(sh.full_name, ' -> ', sp.s_name) AS varchar(100)) AS full_name,
           level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier sp ON ps.ps_partkey = sp.s_suppkey
    WHERE ps.ps_availqty > 50
),
SalesStats AS (
    SELECT c.c_nationkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_nationkey
),
RegionStats AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           SUM(ss.total_revenue) AS region_revenue,
           COUNT(DISTINCT ss.total_orders) AS region_orders
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN SalesStats ss ON n.n_nationkey = ss.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rh.s_name AS supplier_name,
       rh.full_name AS hierarchy,
       rs.r_name AS region_name,
       rs.region_revenue,
       COALESCE(rs.region_orders, 0) AS region_orders,
       CASE 
           WHEN rs.region_revenue > 1000000 THEN 'High' 
           WHEN rs.region_revenue IS NULL THEN 'No Revenue'
           ELSE 'Moderate' 
       END AS revenue_category
FROM SupplierHierarchy rh
JOIN RegionStats rs ON rh.s_nationkey = rs.r_regionkey
WHERE rh.level <= 3
ORDER BY rs.region_revenue DESC, rh.s_name;
