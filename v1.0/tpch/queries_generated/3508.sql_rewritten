WITH SupplierSales AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.supplier_name, 
        ss.total_sales, 
        ss.order_count
    FROM 
        SupplierSales ss
    WHERE 
        ss.sales_rank <= 5
)
SELECT 
    t.supplier_name,
    t.total_sales,
    t.order_count,
    r.r_name AS supplier_region,
    COALESCE(n.n_name, 'Unknown') AS supplier_nation,
    CASE
        WHEN t.order_count > 100 THEN 'High Volume'
        WHEN t.order_count BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    TopSuppliers t
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_name = t.supplier_name)
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    t.total_sales DESC, t.supplier_name;