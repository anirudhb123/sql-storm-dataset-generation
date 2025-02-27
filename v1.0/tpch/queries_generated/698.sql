WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
AggregatedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales
    FROM 
        AggregatedSales s
    WHERE 
        s.sales_rank <= 10
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(COALESCE(ts.total_sales, 0)) AS total_sales_by_region
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    orders o ON cs.c_custkey = o.o_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                                                                 FROM lineitem l 
                                                                 WHERE l.l_orderkey = o.o_orderkey) 
                                         LIMIT 1)
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    region_name, nation_name;
