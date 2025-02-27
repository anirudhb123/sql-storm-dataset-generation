WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
RegionRanking AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    rr.supplier_count AS region_supplier_count,
    ss.order_count AS total_orders,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 10000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM RegionRanking rr
JOIN region r ON rr.r_regionkey = r.r_regionkey
LEFT JOIN SupplierSales ss ON rr.supplier_count > 0 AND ss.sales_rank <= 5
ORDER BY r.r_name, total_sales DESC;
