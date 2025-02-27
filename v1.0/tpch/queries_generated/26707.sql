WITH StringProcessing AS (
    SELECT 
        p.p_name,
        SUBSTRING(p.p_name, 1, 10) AS name_prefix,
        UPPER(p.p_brand) AS brand_upper,
        LOWER(p.p_comment) AS comment_lower,
        CONCAT(p.p_name, ' - ', p.p_brand) AS full_description,
        REPLACE(p.p_comment, 'small', 'tiny') AS adjusted_comment,
        CHAR_LENGTH(p.p_name) AS name_length
    FROM 
        part p
),
AggregatedResults AS (
    SELECT 
        sp.brand_upper,
        COUNT(*) AS total_parts,
        AVG(name_length) AS avg_name_length,
        COUNT(DISTINCT name_prefix) AS unique_name_prefixes
    FROM 
        StringProcessing sp
    GROUP BY 
        sp.brand_upper
)
SELECT 
    ar.brand_upper,
    ar.total_parts,
    ar.avg_name_length,
    ar.unique_name_prefixes,
    STRING_AGG(DISTINCT sp.full_description, '; ') AS all_descriptions
FROM 
    AggregatedResults ar
JOIN 
    StringProcessing sp ON ar.brand_upper = sp.brand_upper
GROUP BY 
    ar.brand_upper, ar.total_parts, ar.avg_name_length, ar.unique_name_prefixes
ORDER BY 
    ar.total_parts DESC;
