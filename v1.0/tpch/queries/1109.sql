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
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(SUM(rs.total_sales), 0) AS total_supplier_sales,
    COALESCE(AVG(rs.order_count), 0) AS avg_orders_per_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSales rs ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey LIMIT 1)
GROUP BY 
    r.r_name
ORDER BY 
    region_name;
