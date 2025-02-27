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
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_sales IS NOT NULL
)
SELECT 
    t.s_name,
    t.total_sales,
    t.order_count,
    CASE 
        WHEN t.order_count > 100 THEN 'High Volume Supplier'
        WHEN t.order_count BETWEEN 51 AND 100 THEN 'Medium Volume Supplier'
        ELSE 'Low Volume Supplier'
    END AS supplier_category,
    COALESCE(r.r_name, 'Unknown Region') AS region_name
FROM 
    TopSuppliers t
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = t.s_suppkey LIMIT 1) LIMIT 1)))
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;