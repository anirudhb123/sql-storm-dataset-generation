WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales,
        ss.sales_rank
    FROM SupplierSales ss
    WHERE ss.sales_rank <= 5
),
NationSales AS (
    SELECT 
        n.n_name,
        COALESCE(SUM(ts.total_sales), 0) AS total_sales,
        COUNT(ts.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
    GROUP BY n.n_name
)
SELECT 
    n.n_name,
    n.total_sales,
    n.supplier_count,
    (SELECT AVG(total_sales) FROM NationSales) AS avg_nation_sales,
    (SELECT MAX(total_sales) FROM NationSales) AS max_nation_sales
FROM NationSales n
ORDER BY n.total_sales DESC
HAVING n.total_sales > (SELECT AVG(total_sales) FROM NationSales) 
   AND n.supplier_count > 2
UNION ALL
SELECT 
    'Global Averages' AS n_name,
    AVG(total_sales) AS total_sales,
    NULL AS supplier_count
FROM NationSales
WHERE total_sales IS NOT NULL
ORDER BY total_sales DESC;
