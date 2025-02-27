WITH RECURSIVE RegionalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
    
    UNION ALL
    
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(r.total_sales) 
    FROM 
        RegionalSales r
    JOIN 
        nation n ON r.n_nationkey = n.n_nationkey
    WHERE 
        r.total_sales > 0
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'O') AS open_orders,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RegionalSales rs ON n.n_nationkey = rs.n_nationkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    r.r_name
HAVING 
    SUM(rs.total_sales) IS NOT NULL AND TOTAL_SALES > 0
ORDER BY 
    total_sales DESC;
