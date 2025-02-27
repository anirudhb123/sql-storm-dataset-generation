WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Part: ', p.p_name, ' | Manufacturer: ', p.p_mfgr) AS part_info,
        REPLACE(SUBSTRING(p.p_comment, 1, 20), ' ', '-') AS short_comment,
        LENGTH(p.p_comment) AS comment_length,
        LOWER(p.p_type) AS type_lower,
        UPPER(p.p_brand) AS brand_upper,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
        AND p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
AggregatedData AS (
    SELECT 
        type_lower,
        COUNT(*) AS part_count,
        AVG(p_retailprice) AS avg_price,
        MAX(comment_length) AS max_comment_length,
        STRING_AGG(part_info, '; ') AS part_descriptions
    FROM 
        StringProcessing
    GROUP BY 
        type_lower
)
SELECT 
    type_lower,
    part_count,
    avg_price,
    max_comment_length,
    part_descriptions
FROM 
    AggregatedData
ORDER BY 
    avg_price DESC;
