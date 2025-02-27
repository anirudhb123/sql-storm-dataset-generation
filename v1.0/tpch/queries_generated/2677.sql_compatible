
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal > 0 
        AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSales AS (
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
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(rs.s_suppkey) AS supplier_count,
    AVG(rs.order_count) AS avg_orders_per_supplier
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    RankedSales rs ON ns.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    COALESCE(SUM(rs.total_sales), 0) > 100000
ORDER BY 
    total_sales DESC;
