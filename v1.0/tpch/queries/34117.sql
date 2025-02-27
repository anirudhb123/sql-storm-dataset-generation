
WITH RECURSIVE regional_sales AS (
    SELECT 
        n.n_nationkey,
        r.r_name AS region_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        r.r_name IS NOT NULL
    GROUP BY 
        n.n_nationkey, r.r_name
    
    UNION ALL
    
    SELECT 
        n.n_nationkey,
        r.r_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) + rs.total_sales
    FROM 
        regional_sales rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        r.r_name IS NOT NULL AND
        rs.total_sales < 1000000
    GROUP BY 
        n.n_nationkey, r.r_name, rs.total_sales
)

SELECT 
    rs.region_name,
    SUM(rs.total_sales) AS total_sales,
    COUNT(DISTINCT l.l_orderkey) AS orders_count,
    ROW_NUMBER() OVER (PARTITION BY rs.region_name ORDER BY SUM(rs.total_sales) DESC) AS region_rank
FROM 
    regional_sales rs
JOIN 
    lineitem l ON rs.n_nationkey = l.l_suppkey
GROUP BY 
    rs.region_name
HAVING 
    SUM(rs.total_sales) IS NOT NULL
ORDER BY 
    total_sales DESC;
