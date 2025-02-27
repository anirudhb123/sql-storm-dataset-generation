WITH SupplierSales AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ss.total_sales
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE s.s_acctbal > 10000
),
SalesRanking AS (
    SELECT *,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM HighValueSuppliers
)
SELECT r.r_name,
       COUNT(DISTINCT hvs.s_suppkey) AS supplier_count,
       AVG(hvs.total_sales) AS avg_sales,
       MAX(hvs.total_sales) AS max_sales,
       MIN(hvs.total_sales) AS min_sales
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey,
           hvs.total_sales
    FROM nation n
    JOIN HighValueSuppliers hvs ON n.n_nationkey = hvs.s_nationkey
) AS region_suppliers ON r.r_regionkey = region_suppliers.n_regionkey
GROUP BY r.r_name
HAVING AVG(hvs.total_sales) > 5000 OR MAX(hvs.total_sales) IS NULL
ORDER BY supplier_count DESC;
