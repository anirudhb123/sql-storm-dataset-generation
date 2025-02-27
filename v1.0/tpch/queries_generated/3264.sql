WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank        
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s_nationkey,
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        sales_rank
    FROM 
        SupplierSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COALESCE(ts.s_name, 'No Suppliers') AS supplier_name,
    COALESCE(ts.total_sales, 0.00) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
ORDER BY 
    r.r_name, n.n_name, total_sales DESC;
