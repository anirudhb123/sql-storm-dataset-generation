WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
), MonthlySales AS (
    SELECT 
        o.o_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales, 
        DATE_TRUNC('month', o.o_orderdate) AS sale_month
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, sale_month
), SupplierSales AS (
    SELECT 
        sh.s_name,
        ms.sale_month,
        SUM(ms.total_sales) AS supplier_total
    FROM SupplierHierarchy sh
    LEFT JOIN MonthlySales ms ON sh.s_suppkey = ms.o_orderkey
    GROUP BY sh.s_name, ms.sale_month
), RankedSales AS (
    SELECT 
        s.s_name, 
        s.sale_month, 
        s.supplier_total,
        RANK() OVER (PARTITION BY s.sale_month ORDER BY s.supplier_total DESC) AS rank
    FROM SupplierSales s
    WHERE s.supplier_total IS NOT NULL
)
SELECT 
    r.s_name, 
    r.sale_month, 
    r.supplier_total, 
    CASE 
        WHEN r.rank IS NULL THEN 'No Sales'
        ELSE CAST(r.rank AS VARCHAR)
    END AS sales_rank
FROM RankedSales r
WHERE r.rank <= 3
ORDER BY r.sale_month, r.supplier_total DESC;
