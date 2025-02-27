WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TotalSales AS (
    SELECT 
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_name
),
RegionSales AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(ts.total_sales) AS total_region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN TotalSales ts ON c.c_name = ts.c_name
    GROUP BY r.r_name
)
SELECT 
    rh.s_suppkey,
    rh.s_name,
    ts.total_sales,
    rs.total_region_sales,
    CASE 
        WHEN ts.total_sales > 10000 THEN 'High'
        WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM SupplierHierarchy rh
LEFT JOIN TotalSales ts ON rh.s_name = ts.c_name
LEFT JOIN RegionSales rs ON rh.s_nationkey = rs.r_nationkey
WHERE ts.total_sales IS NOT NULL OR rs.total_region_sales IS NOT NULL
ORDER BY rh.level, ts.total_sales DESC;
