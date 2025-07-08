
WITH regional_sales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        l.l_shipdate >= '1995-01-01'
        AND l.l_shipdate < '1996-01-01'
    GROUP BY 
        r.r_name
    UNION ALL
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1996-01-01' OR (l.l_shipdate IS NULL AND p.p_size > 10)
    GROUP BY 
        r.r_name
),

nested_avg AS (
    SELECT 
        r.r_name,
        AVG(total_sales) OVER (PARTITION BY r.r_name ORDER BY total_sales DESC ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS avg_sales
    FROM 
        regional_sales r
),

final_output AS (
    SELECT 
        r.r_name,
        COALESCE(n.avg_sales, 0) AS avg_sales,
        CASE 
            WHEN COALESCE(n.avg_sales, 0) > 100000 THEN 'High Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM 
        region r
    LEFT JOIN 
        nested_avg n ON r.r_name = n.r_name
)

SELECT 
    f.r_name,
    f.avg_sales,
    f.sales_category
FROM 
    final_output f
ORDER BY 
    f.avg_sales DESC
LIMIT 10 
OFFSET (SELECT COUNT(DISTINCT r_name) FROM final_output) / 2;
