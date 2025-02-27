WITH SupplierSales AS (
    SELECT s.s_suppkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           ss.total_sales,
           ss.order_count,
           RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
HighValueSuppliers AS (
    SELECT r.r_name,
           SUM(total_sales) AS regional_sales
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.sales_rank <= 10
    GROUP BY r.r_name
)
SELECT r.r_name,
       COALESCE(hv.regional_sales, 0) AS total_region_sales,
       SUM(CASE WHEN hv.regional_sales IS NULL THEN 1 ELSE 0 END) AS missing_sales_count
FROM region r
LEFT JOIN HighValueSuppliers hv ON r.r_name = hv.r_name
GROUP BY r.r_name
ORDER BY total_region_sales DESC
