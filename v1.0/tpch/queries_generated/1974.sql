WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
)
SELECT 
    r.r_name,
    ns.n_name,
    COUNT(rs.s_suppkey) AS supplier_count,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales_by_region,
    AVG(rs.order_count) AS avg_orders_per_supplier
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    rankedSales rs ON ns.n_nationkey = (
        SELECT 
            s.s_nationkey 
        FROM 
            supplier s 
        WHERE 
            s.s_suppkey = rs.s_suppkey
    )
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    total_sales_by_region > 10000
ORDER BY 
    total_sales_by_region DESC
UNION ALL
SELECT 
    'Total' AS r_name,
    NULL AS n_name,
    COUNT(rs.s_suppkey) AS supplier_count,
    SUM(rs.total_sales) AS total_sales_by_region,
    AVG(rs.order_count) AS avg_orders_per_supplier
FROM 
    rankedSales rs
WHERE 
    rs.total_sales IS NOT NULL;
