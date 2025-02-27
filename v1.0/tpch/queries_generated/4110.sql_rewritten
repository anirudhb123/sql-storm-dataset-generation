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
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    n.n_name AS nation,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.order_count) AS avg_orders_per_supplier
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = (
        SELECT 
            s_nationkey 
        FROM 
            supplier 
        WHERE 
            supplier.s_suppkey = rs.s_suppkey
        LIMIT 1
    )
GROUP BY 
    n.n_name
HAVING 
    SUM(rs.total_sales) > 10000
ORDER BY 
    total_sales DESC;