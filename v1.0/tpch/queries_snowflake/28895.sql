
WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        REPLACE(p.p_name, 'a', '@') AS replaced_name,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        CONCAT(LEFT(p.p_name, 10), '...') AS truncated_name,
        LEN(REPLACE(p.p_name, ' ', '')) AS char_count_no_space,  -- Changed CHAR_LENGTH to LEN
        REGEXP_REPLACE(p.p_name, '[^A-Za-z]', '') AS letters_only
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name LIKE '%west%' AND 
        s.s_acctbal > 2000 
)
SELECT 
    COUNT(*) AS total_records,
    AVG(name_length) AS avg_name_length,
    MAX(name_length) AS max_name_length,
    MIN(name_length) AS min_name_length,
    STRING_AGG(upper_name, ', ') AS all_upper_names,
    STRING_AGG(truncated_name, ', ') AS all_truncated_names
FROM 
    StringBenchmark
GROUP BY 
    p_partkey, p_name, name_length, upper_name, truncated_name;  -- Added group by columns
