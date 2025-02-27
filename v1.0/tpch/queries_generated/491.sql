WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= '2023-01-01'
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
SalesByNation AS (
    SELECT 
        n.n_name,
        SUM(ss.total_sales) AS total_nation_sales,
        AVG(ss.total_sales) AS avg_sales_per_supplier,
        COUNT(ss.s_suppkey) AS supplier_count
    FROM SupplierSales ss
    JOIN nation n ON ss.sales_rank = 1
    GROUP BY n.n_name
)
SELECT 
    COALESCE(sb.n_name, 'Unknown Region') AS Nation,
    COALESCE(sb.total_nation_sales, 0) AS TotalSales,
    COALESCE(sb.avg_sales_per_supplier, 0) AS AvgSales,
    COALESCE(sb.supplier_count, 0) AS SupplierCount,
    CASE 
        WHEN sb.total_nation_sales IS NULL OR sb.total_nation_sales = 0 THEN 'No Sales'
        ELSE 'Active Sales'
    END AS Sales_Status
FROM SalesByNation sb
FULL OUTER JOIN region r ON r.r_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = sb.Nation)
ORDER BY TotalSales DESC;
