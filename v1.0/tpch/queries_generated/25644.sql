WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS combined_info,
        LENGTH(CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name)) AS info_length,
        REPLACE(p.p_comment, ' ', '_') AS comment_with_underscores,
        SUBSTRING_INDEX(s.s_comment, ' ', 10) AS short_supplier_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_retailprice > 100.00
)
SELECT 
    part_name,
    supplier_name,
    combined_info,
    info_length,
    comment_with_underscores,
    short_supplier_comment,
    CHAR_LENGTH(comment_with_underscores) AS underscore_comment_length
FROM 
    StringProcessing
ORDER BY 
    info_length DESC
LIMIT 15;
