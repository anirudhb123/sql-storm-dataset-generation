WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
), 
size_sales AS (
    SELECT 
        p.p_type, 
        AVG(p.p_retailprice) AS avg_price,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size IS NOT NULL AND p.p_retailprice > 0
    GROUP BY 
        p.p_type
),
ranked_sales AS (
    SELECT 
        ns.n_name, 
        ns.total_sales,
        RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM 
        nation_sales ns
)
SELECT 
    rs.n_name, 
    rs.total_sales,
    COALESCE(ss.avg_price, 0) AS avg_price,
    ss.unique_parts,
    CASE 
        WHEN rs.sales_rank <= 5 THEN 'Top Nation'
        WHEN rs.sales_rank IS NULL THEN 'No Data'
        ELSE 'Other'
    END AS sales_category
FROM 
    ranked_sales rs
LEFT JOIN 
    size_sales ss ON ss.p_type IN (SELECT DISTINCT p_type FROM part WHERE p_pkey IS NOT NULL) 
WHERE 
    rs.total_sales IS NOT NULL AND rs.n_name NOT LIKE '%test%'
ORDER BY 
    rs.total_sales DESC NULLS LAST
UNION ALL
SELECT 
    'Total' AS n_name,
    SUM(total_sales) AS total_sales,
    NULL AS avg_price,
    NULL AS unique_parts,
    'Overall' AS sales_category
FROM 
    ranked_sales
WHERE 
    sales_rank IS NOT NULL;
