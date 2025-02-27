WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           1 AS level, ARRAY[s_suppkey] AS path
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1, sh.path || s.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> ALL(sh.path)
),
AggregatedSales AS (
    SELECT 
        l.l_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY l.l_suppkey
),
SupplierPerformance AS (
    SELECT 
        sh.level,
        sh.s_name,
        sh.path,
        COALESCE(a.total_sales, 0) AS total_sales,
        COALESCE(a.order_count, 0) AS order_count,
        RANK() OVER (PARTITION BY sh.level ORDER BY COALESCE(a.total_sales, 0) DESC) AS sales_rank
    FROM SupplierHierarchy sh
    LEFT JOIN AggregatedSales a ON sh.s_suppkey = a.l_suppkey
)
SELECT 
    sp.level,
    sp.s_name,
    sp.total_sales,
    sp.order_count,
    CASE 
        WHEN sp.sales_rank <= 10 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status
FROM SupplierPerformance sp
WHERE sp.total_sales > 10000
ORDER BY sp.level, total_sales DESC;
