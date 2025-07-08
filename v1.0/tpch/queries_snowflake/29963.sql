
WITH StringMetrics AS (
    SELECT 
        s.s_suppkey,
        LENGTH(s.s_name) AS supplier_name_length,
        LOWER(s.s_comment) AS normalized_comment,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment,
        SIZE(ARRAY_COMPACT(ARRAY_AGG(LOWER(REGEXP_SPLIT_TO_ARRAY(s.s_comment, ' '))))) AS word_count,
        LENGTH(s.s_name) - LENGTH(REPLACE(s.s_name, 'a', '')) AS count_a,
        LENGTH(s.s_name) - LENGTH(REPLACE(s.s_name, 'e', '')) AS count_e,
        LENGTH(s.s_name) - LENGTH(REPLACE(s.s_name, 'i', '')) AS count_i,
        LENGTH(s.s_name) - LENGTH(REPLACE(s.s_name, 'o', '')) AS count_o,
        LENGTH(s.s_name) - LENGTH(REPLACE(s.s_name, 'u', '')) AS count_u
    FROM 
        supplier s
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_comment
),
AggregatedMetrics AS (
    SELECT 
        AVG(supplier_name_length) AS avg_name_length,
        SUM(word_count) AS total_words,
        SUM(count_a) AS total_a,
        SUM(count_e) AS total_e,
        SUM(count_i) AS total_i,
        SUM(count_o) AS total_o,
        SUM(count_u) AS total_u
    FROM 
        StringMetrics
)
SELECT 
    avg_name_length,
    total_words,
    total_a,
    total_e,
    total_i,
    total_o,
    total_u
FROM 
    AggregatedMetrics;
