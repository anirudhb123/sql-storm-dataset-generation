WITH StringBenchmarks AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        SUBSTRING(p.p_name FROM 1 FOR 10) AS name_substring,
        REPLACE(p.p_name, 'a', '@') AS name_replaced,
        TRIM(p.p_comment) AS trimmed_comment,
        CONCAT('Part: ', p.p_name, ' | Container: ', p.p_container) AS concatenated_info
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30
),
AggregatedResults AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(name_length) AS avg_name_length,
        MIN(name_length) AS min_name_length,
        MAX(name_length) AS max_name_length,
        STRING_AGG(upper_name, ', ') AS upper_names,
        STRING_AGG(name_replaced, ', ') AS replaced_names,
        STRING_AGG(trimmed_comment, '; ') AS comments
    FROM 
        StringBenchmarks
)
SELECT 
    * 
FROM 
    AggregatedResults;
