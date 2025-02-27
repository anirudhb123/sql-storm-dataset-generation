WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 

TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY 
        ss.total_sales DESC
    LIMIT 5
)

SELECT 
    rs.r_name AS region_name, 
    ns.n_name AS nation_name, 
    ts.s_name AS supplier_name, 
    ts.total_sales
FROM 
    region rs
JOIN 
    nation ns ON rs.r_regionkey = ns.n_regionkey
JOIN 
    supplier ts ON ns.n_nationkey = ts.s_nationkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = ts.s_suppkey
WHERE 
    ts.total_sales > 100000
ORDER BY 
    region_name, nation_name, total_sales DESC;
