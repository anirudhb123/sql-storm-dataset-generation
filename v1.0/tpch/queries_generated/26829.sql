WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        LENGTH(TRIM(p.p_name)) AS name_length,
        UPPER(SUBSTRING(p.p_comment FROM 1 FOR 10)) AS comment_prefix
    FROM 
        part p
    WHERE 
        p.p_size > 10 AND p.p_retailprice < 100
),
aggregated_data AS (
    SELECT 
        pp.name_length,
        COUNT(*) AS part_count,
        AVG(pp.p_retailprice) AS avg_price,
        STRING_AGG(pp.comment_prefix, ', ') AS prefixes
    FROM 
        processed_parts pp
    GROUP BY 
        pp.name_length
),
supplier_info AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        LEFT(s.s_comment, 20) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 500
)
SELECT 
    ai.name_length,
    ai.part_count,
    ai.avg_price,
    si.s_name,
    si.short_comment
FROM 
    aggregated_data ai
JOIN 
    supplier_info si ON ai.part_count > 10
ORDER BY 
    ai.avg_price DESC, ai.name_length ASC;
