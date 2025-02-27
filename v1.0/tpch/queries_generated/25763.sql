WITH StringAggregates AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        s.s_name,
        c.c_name,
        CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name)) AS string_length,
        LOWER(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name)) AS lower_case_string,
        UPPER(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name)) AS upper_case_string,
        SUBSTRING(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name), 1, 10) AS substring_string
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    WHERE 
        p.p_size BETWEEN 1 AND 50
),
StringMetrics AS (
    SELECT 
        AVG(string_length) AS avg_length,
        MIN(string_length) AS min_length,
        MAX(string_length) AS max_length,
        COUNT(*) AS total_count
    FROM 
        StringAggregates
)
SELECT 
    sa.p_partkey,
    sa.combined_string,
    sm.avg_length,
    sm.min_length,
    sm.max_length,
    sa.lower_case_string,
    sa.upper_case_string,
    sa.substring_string
FROM 
    StringAggregates sa
CROSS JOIN 
    StringMetrics sm
ORDER BY 
    sa.p_partkey;
