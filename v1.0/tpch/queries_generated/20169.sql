WITH RECURSIVE SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
    UNION ALL
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales * 1.1 AS total_sales,
        ss.order_count + 1 AS order_count
    FROM SupplierSales ss
    WHERE ss.order_count < 10
),
RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY ss.total_sales DESC) AS rnk
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    COALESCE(r.rnk, 0) AS rank,
    s.s_name,
    r.total_sales,
    n.r_name,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales'
        WHEN r.total_sales > 5000 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status,
    CONCAT('Sales: ', CAST(r.total_sales AS VARCHAR), ' in ', n.r_name) AS sales_info
FROM RankedSales r
FULL OUTER JOIN supplier s ON r.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE (s.s_acctbal IS NOT NULL AND s.s_acctbal < 1000)
   OR (s.s_acctbal IS NULL)
ORDER BY rank DESC NULLS LAST, r.total_sales DESC, n.r_name ASC;
