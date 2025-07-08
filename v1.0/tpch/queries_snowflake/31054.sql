
WITH RECURSIVE regional_sales AS (
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
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        total_sales DESC
),
ranked_sales AS (
    SELECT 
        n_nationkey, 
        n_name, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
)

SELECT 
    r.r_name AS region, 
    COUNT(DISTINCT CASE WHEN n.n_nationkey IS NULL THEN 'Unassigned' ELSE n.n_name END) AS nations_count,
    COALESCE(MAX(s.total_sales), 0) AS max_sales,
    ARRAY_AGG(n.n_name ORDER BY s.total_sales DESC) AS nation_names,
    r.r_comment
FROM 
    region r
LEFT OUTER JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN 
    ranked_sales s ON n.n_nationkey = s.n_nationkey
GROUP BY 
    r.r_name, r.r_comment
HAVING 
    COALESCE(MAX(s.total_sales), 0) > 10000
ORDER BY 
    nations_count DESC, max_sales DESC;
