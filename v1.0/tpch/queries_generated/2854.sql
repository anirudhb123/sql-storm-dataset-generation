WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.*, 
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SupplierSales s
)
SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT rs.s_suppkey) AS total_suppliers,
    AVG(rs.num_orders) AS avg_orders_per_supplier
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
WHERE r.r_comment LIKE '%important%'
AND (total_sales > 100000 OR total_sales IS NULL)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT rs.s_suppkey) > 10
ORDER BY total_sales DESC
LIMIT 10;
