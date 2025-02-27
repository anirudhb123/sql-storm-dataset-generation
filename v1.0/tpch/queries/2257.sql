WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY s.total_sales DESC) as sales_rank
    FROM SupplierSales s
)
SELECT 
    r.r_name,
    ns.n_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    CASE 
        WHEN SUM(rs.total_sales) > 10000 THEN 'High Volume'
        WHEN SUM(rs.total_sales) > 5000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN RankedSales rs ON ns.n_nationkey = 
    (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
GROUP BY r.r_name, ns.n_name
ORDER BY r.r_name, ns.n_name;