WITH StringBenchmark AS (
    SELECT 
        p.p_name,
        CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_comment) AS upper_comment,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        REPLACE(p.p_comment, 'bad', 'good') AS clean_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
AggregatedResults AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(name_length) AS avg_name_length,
        MIN(name_length) AS min_name_length,
        MAX(name_length) AS max_name_length,
        STRING_AGG(upper_comment, '; ') AS aggregated_comments,
        STRING_AGG(supplier_info, ', ') AS all_suppliers_info
    FROM 
        StringBenchmark
)
SELECT 
    total_parts,
    avg_name_length,
    min_name_length,
    max_name_length,
    aggregated_comments,
    all_suppliers_info
FROM 
    AggregatedResults;
