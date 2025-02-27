WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Type: ', p.p_type) AS descriptive_string
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
AggregatedMetrics AS (
    SELECT 
        AVG(name_length) AS avg_name_length,
        AVG(comment_length) AS avg_comment_length,
        STRING_AGG(descriptive_string, '; ') AS all_descriptive_strings
    FROM 
        StringMetrics
)
SELECT 
    a.avg_name_length,
    a.avg_comment_length,
    SPLIT_PART(a.all_descriptive_strings, '; ', 1) AS first_descriptive_string,
    SPLIT_PART(a.all_descriptive_strings, '; ', 2) AS second_descriptive_string,
    SUBSTRING(a.all_descriptive_strings FROM 1 FOR 100) AS snippet_of_descriptions
FROM 
    AggregatedMetrics a;
