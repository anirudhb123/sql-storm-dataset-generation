WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count
    FROM 
        SupplierSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    ts.s_suppkey,
    ts.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    CASE 
        WHEN ts.total_sales > 100000 THEN 'High Performer'
        WHEN ts.total_sales BETWEEN 50000 AND 100000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ts.s_suppkey)
WHERE 
    r.r_name LIKE 'E%' OR r.r_comment IS NULL
ORDER BY 
    region, total_sales DESC;
