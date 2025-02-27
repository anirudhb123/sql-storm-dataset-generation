WITH StringProcessing AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name) AS detailed_info,
        UPPER(p.p_brand) AS upper_brand,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'soft', 'hard') AS modified_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 50
)
SELECT 
    DISTINCT upper_brand, 
    COUNT(detailed_info) AS supplier_count,
    AVG(comment_length) AS avg_comment_length,
    STRING_AGG(modified_comment, '; ') AS all_modified_comments
FROM 
    StringProcessing
GROUP BY 
    upper_brand
ORDER BY 
    supplier_count DESC;
