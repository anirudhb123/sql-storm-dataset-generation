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
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
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
)
SELECT 
    ns.n_name AS nation_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM 
    nation ns
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = (
        SELECT 
            s_nationkey 
        FROM 
            supplier 
        WHERE 
            s_suppkey = rs.s_suppkey
    )
GROUP BY 
    ns.n_name
HAVING 
    SUM(rs.total_sales) > (
        SELECT 
            AVG(total_sales) 
        FROM 
            SupplierSales
    )
ORDER BY 
    total_sales DESC;