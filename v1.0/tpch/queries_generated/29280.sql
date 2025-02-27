WITH StringBench AS (
    SELECT 
        p.p_name AS part_name,
        ps.ps_supplycost AS supply_cost,
        s.s_name AS supplier_name,
        CONCAT(p.p_name, ' - ', s.s_name, ' (Cost: ', ps.ps_supplycost, ')') AS full_description,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name, ' (Cost: ', ps.ps_supplycost, ')')) AS description_length,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        TRIM(REPLACE(REPLACE(s.s_comment, '  ', ' '), ' (', '')) AS cleaned_supplier_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size < 20
)
SELECT 
    AVG(description_length) AS avg_length,
    COUNT(*) AS total_records,
    MAX(short_comment) AS longest_short_comment,
    STRING_AGG(cleaned_supplier_comment, '; ') AS all_supplier_comments
FROM StringBench;
