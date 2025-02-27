WITH StringStats AS (
    SELECT 
        p.p_name AS part_name,
        p.p_brand,
        p.p_type,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(REPLACE(LOWER(p.p_name), ' ', ''), '-', '') AS normalized_name,
        CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type
    FROM 
        part p
    WHERE 
        p.p_size > 20
), 
AggregateData AS (
    SELECT 
        brand_type,
        COUNT(part_name) AS total_parts,
        AVG(comment_length) AS avg_comment_length
    FROM 
        StringStats
    GROUP BY 
        brand_type
)
SELECT 
    ad.brand_type,
    ad.total_parts,
    ad.avg_comment_length,
    SUBSTRING_INDEX(GROUP_CONCAT(ss.part_name ORDER BY ss.comment_length DESC SEPARATOR '|'), '|', 5) AS top_parts
FROM 
    AggregateData ad
JOIN 
    StringStats ss ON ad.brand_type = ss.brand_type
GROUP BY 
    ad.brand_type
ORDER BY 
    ad.total_parts DESC, ad.avg_comment_length DESC;
