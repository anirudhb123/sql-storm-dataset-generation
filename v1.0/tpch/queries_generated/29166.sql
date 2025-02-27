WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(p.p_name, ' - ', p.p_comment) AS combined_string,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment,
        CASE 
            WHEN p.p_container LIKE '%BOX%' THEN 'BOX'
            WHEN p.p_container LIKE '%CRATE%' THEN 'CRATE' 
            ELSE 'OTHER' 
        END AS container_type
    FROM 
        part p
),
AggregateMetrics AS (
    SELECT 
        container_type,
        COUNT(*) AS part_count,
        AVG(name_length) AS avg_name_length,
        MAX(comment_length) AS max_comment_length,
        MIN(comment_length) AS min_comment_length,
        STRING_AGG(combined_string, '; ') AS combined_strings
    FROM 
        StringMetrics
    GROUP BY 
        container_type
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sm.container_type,
    sm.part_count,
    sm.avg_name_length,
    sm.max_comment_length,
    sm.min_comment_length,
    sm.combined_strings
FROM 
    AggregateMetrics sm
JOIN 
    supplier s ON sm.container_type = CASE 
                                          WHEN s.s_name LIKE '%SUPP%' THEN 'BOX'
                                          ELSE 'OTHER' 
                                       END
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    r.r_name, n.n_name, sm.container_type;
