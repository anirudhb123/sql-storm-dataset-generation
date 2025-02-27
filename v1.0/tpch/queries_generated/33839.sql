WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 3 
),
AggregatedSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY l.l_suppkey
),
RankedSuppliers AS (
    SELECT 
        sh.s_suppkey,
        sh.s_name,
        COALESCE(a.total_sales, 0) AS total_sales,
        a.order_count,
        a.total_quantity,
        ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY COALESCE(a.total_sales, 0) DESC) AS sales_rank
    FROM SupplierHierarchy sh
    LEFT JOIN AggregatedSales a ON sh.s_suppkey = a.l_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    SUM(rs.total_sales) AS total_sales,
    AVG(rs.total_quantity) AS avg_quantity
FROM RankedSuppliers rs
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rs.sales_rank <= 5
GROUP BY r.r_name
ORDER BY total_sales DESC
FETCH FIRST 10 ROWS ONLY;
