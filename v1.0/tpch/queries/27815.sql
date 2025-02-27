WITH StringAggregation AS (
    SELECT 
        s.s_name AS supplier_name,
        STRING_AGG(DISTINCT p.p_name, '; ') AS aggregated_product_names,
        COUNT(DISTINCT p.p_partkey) AS product_count,
        SUBSTRING(s.s_comment, 1, 50) AS supplier_comment_excerpt
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        LENGTH(s.s_name) > 5
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_comment
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    STRING_AGG(DISTINCT sa.aggregated_product_names, ', ') AS all_supplier_product_names,
    STRING_AGG(DISTINCT sa.supplier_comment_excerpt, ' | ') AS unique_supplier_comments
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    StringAggregation sa ON n.n_nationkey = (
        SELECT 
            s_nationkey 
        FROM 
            supplier 
        WHERE 
            s_name LIKE '%' || n.n_name || '%'
        LIMIT 1
    )
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    nation_count DESC;
