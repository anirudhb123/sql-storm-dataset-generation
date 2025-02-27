WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(ls.l_quantity) AS avg_quantity
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem ls ON ps.ps_partkey = ls.l_partkey
    LEFT JOIN 
        orders o ON ls.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RankedPerformance AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierPerformance s
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.total_sales, 
        s.order_count, 
        s.avg_quantity
    FROM 
        RankedPerformance s
    WHERE 
        s.sales_rank <= 10
)
SELECT 
    t.s_suppkey,
    t.s_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.order_count, 0) AS order_count,
    COALESCE(t.avg_quantity, 0) AS avg_quantity,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    TopSuppliers t
LEFT JOIN 
    lineitem l ON l.l_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = t.s_suppkey
    )
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    t.s_suppkey, t.s_name, t.total_sales, t.order_count, t.avg_quantity
ORDER BY 
    t.total_sales DESC;
