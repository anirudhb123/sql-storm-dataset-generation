
WITH RECURSIVE string_benchmark AS (
    SELECT 
        s_suppkey,
        s_name,
        s_comment,
        CONCAT(s_name, ' | ', s_comment) AS combined_info,
        LENGTH(CONCAT(s_name, ' | ', s_comment)) AS string_length
    FROM supplier
    WHERE LENGTH(s_comment) > 20

    UNION ALL

    SELECT 
        s_suppkey,
        s_name,
        s_comment,
        CONCAT(combined_info, ' -> ', s_name) AS combined_info,
        LENGTH(CONCAT(combined_info, ' -> ', s_name)) AS string_length
    FROM string_benchmark 
    WHERE string_length < 255
)

SELECT 
    supplier.s_nationkey, 
    COUNT(DISTINCT string_benchmark.s_suppkey) AS unique_suppliers,
    AVG(string_length) AS avg_string_length,
    MAX(string_length) AS max_string_length
FROM string_benchmark 
JOIN supplier ON supplier.s_suppkey = string_benchmark.s_suppkey
GROUP BY supplier.s_nationkey
ORDER BY avg_string_length DESC;
