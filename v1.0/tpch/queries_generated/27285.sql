WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9 ]', '') AS cleaned_comment,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.p_comment, ' ')) AS word_count
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SuppliersWithCommentMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_comment) AS comment_length,
        REGEXP_REPLACE(s.s_comment, '[^A-Za-z0-9 ]', '') AS cleaned_comment,
        ARRAY_LENGTH(STRING_TO_ARRAY(s.s_comment, ' ')) AS word_count
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00 
)
SELECT 
    sm.p_partkey,
    sm.p_name,
    sm.name_length AS part_name_length,
    sm.cleaned_comment AS part_cleaned_comment,
    sm.word_count AS part_comment_word_count,
    swcm.s_suppkey,
    swcm.s_name,
    swcm.name_length AS supplier_name_length,
    swcm.comment_length AS supplier_comment_length,
    swcm.cleaned_comment AS supplier_cleaned_comment,
    swcm.word_count AS supplier_comment_word_count
FROM 
    StringMetrics sm
JOIN 
    SuppliersWithCommentMetrics swcm ON sm.name_length = swcm.name_length
ORDER BY 
    sm.word_count DESC, swcm.comment_length ASC
LIMIT 100;
