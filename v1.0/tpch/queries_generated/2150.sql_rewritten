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
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-12-31' 
        AND o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    rs.s_suppkey,
    rs.s_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey)
WHERE 
    r.r_name LIKE 'Europ%' 
    AND (rs.sales_rank <= 10 OR rs.sales_rank IS NULL)
ORDER BY 
    region_name, total_sales DESC;