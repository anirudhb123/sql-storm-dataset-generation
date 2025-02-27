WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS VARCHAR(100)) AS hierarchy
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, CAST(CONCAT(rh.hierarchy, ' -> ', s.s_name) AS VARCHAR(100))
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierHierarchy rh ON rh.s_suppkey = ps.ps_partkey
),
TotalSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
),
RegionSales AS (
    SELECT r.r_name, SUM(ts.total_revenue) AS region_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN TotalSales ts ON l.l_partkey = ts.l_partkey
    GROUP BY r.r_name
),
FilteredSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS filtered_revenue
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_discount > 0.1
    GROUP BY sh.s_suppkey, sh.s_name
)
SELECT 
    r.r_name,
    COALESCE(rs.region_revenue, 0) AS total_region_revenue,
    COALESCE(fs.filtered_revenue, 0) AS filtered_supplier_revenue,
    COUNT(DISTINCT fs.s_suppkey) AS unique_suppliers_count
FROM region r
LEFT JOIN RegionSales rs ON r.r_name = rs.r_name
LEFT JOIN FilteredSuppliers fs ON fs.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
GROUP BY r.r_name
HAVING total_region_revenue > 10000
ORDER BY total_region_revenue DESC, unique_suppliers_count DESC;
