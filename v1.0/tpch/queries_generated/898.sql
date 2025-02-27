WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
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
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
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
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_sales,
    t.order_count,
    COALESCE(t.sales_rank, 'Not Ranked') AS sales_rank,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    TopSuppliers t
LEFT JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    t.total_sales > 50000
GROUP BY 
    t.s_suppkey, t.s_name, t.total_sales, t.order_count, t.sales_rank, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
ORDER BY 
    t.total_sales DESC;
