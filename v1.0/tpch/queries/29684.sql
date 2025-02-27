
WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT(p.p_name, ' | ', s.s_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' | ', s.s_name)) AS combined_length,
        CARDINALITY(STRING_TO_ARRAY(p.p_comment, ' ')) AS word_count,
        LOWER(p.p_name) AS lower_name,
        UPPER(s.s_name) AS upper_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 1 AND 15
)
SELECT 
    AVG(combined_length) AS avg_combined_length,
    SUM(word_count) AS total_word_count,
    COUNT(DISTINCT lower_name) AS distinct_lower_names,
    COUNT(DISTINCT upper_name) AS distinct_upper_names
FROM 
    StringBenchmark
WHERE 
    combined_length > 50
GROUP BY 
    combined_length, lower_name, upper_name;