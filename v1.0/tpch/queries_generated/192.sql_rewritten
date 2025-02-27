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
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales_by_nation,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    CASE 
        WHEN SUM(rs.total_sales) > 0 THEN AVG(rs.order_count) 
        ELSE 0 
    END AS avg_orders_per_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey) 
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_sales_by_nation DESC,
    supplier_count DESC;