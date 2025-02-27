WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_brand) AS brand_upper,
        LOWER(p.p_comment) AS comment_lower,
        REPLACE(p.p_comment, 'Lorem', 'Replaced') AS comment_replaced,
        CONCAT(p.p_name, ' - ', p.p_brand) AS name_brand_concat
    FROM 
        part p
    WHERE 
        p.p_size > 10 
        AND p.p_retailprice BETWEEN 100.00 AND 500.00
),
AggStringProcessing AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(name_length) AS avg_name_length,
        COUNT(DISTINCT brand_upper) AS unique_brands,
        STRING_AGG(DISTINCT comment_lower, '; ') AS all_comments,
        STRING_AGG(name_brand_concat, ', ') AS concatenated_names_brands
    FROM 
        StringProcessing
)
SELECT 
    total_parts,
    avg_name_length,
    unique_brands,
    all_comments,
    concatenated_names_brands
FROM 
    AggStringProcessing;
