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
        o.o_orderdate >= '2023-01-01'
        AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_sales,
    t.order_count,
    CASE 
        WHEN t.order_count > 5 THEN 'High'
        WHEN t.order_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS order_intensity,
    r.r_name AS region_name
FROM 
    TopSuppliers t
LEFT OUTER JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT OUTER JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT OUTER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;

WITH AvgSales AS (
    SELECT 
        n.n_name,
        AVG(s.total_sales) AS avg_sales
    FROM 
        SupplierSales s
    JOIN 
        supplier supp ON s.s_suppkey = supp.s_suppkey
    JOIN 
        nation n ON supp.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    COALESCE(as.avg_sales, 0) AS average_sales
FROM 
    region r
LEFT JOIN 
    AvgSales as ON r.r_name = as.n_name
WHERE 
    r.r_regionkey IS NOT NULL
ORDER BY 
    r.r_name;
