WITH StringProcessingBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_comment,
        LOWER(p.p_name) AS lower_name,
        UPPER(p.p_name) AS upper_name,
        LENGTH(p.p_name) AS name_length,
        CASE 
            WHEN LENGTH(p.p_comment) > 50 THEN SUBSTRING(p.p_comment, 1, 50) || '...' 
            ELSE p.p_comment 
        END AS short_comment,
        REPLACE(p.p_comment, 'quality', 'QTY') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
),
AggregatedResults AS (
    SELECT 
        AVG(name_length) AS avg_length,
        COUNT(DISTINCT p_partkey) AS unique_parts,
        COUNT(*) AS total_records,
        STRING_AGG(lower_name, ', ') AS all_lower_names,
        STRING_AGG(upper_name, ', ') AS all_upper_names,
        STRING_AGG(short_comment, '; ') AS all_short_comments,
        STRING_AGG(modified_comment, '; ') AS all_modified_comments
    FROM 
        StringProcessingBenchmark
)
SELECT 
    'String Processing Benchmark' AS benchmark_name,
    avg_length,
    unique_parts,
    total_records,
    all_lower_names,
    all_upper_names,
    all_short_comments,
    all_modified_comments
FROM 
    AggregatedResults;
