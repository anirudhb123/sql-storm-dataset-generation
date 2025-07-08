
WITH RECURSIVE StringBenchmark AS (
    SELECT p_name AS original_string, 
           LENGTH(p_name) AS length, 
           UPPER(p_name) AS upper_case, 
           LOWER(p_name) AS lower_case, 
           REPLACE(p_name, 'a', '@') AS replace_a, 
           SUBSTRING(p_name, 1, 5) AS substring_5, 
           CONCAT(p_name, ' - Processed') AS concatenated 
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT original_string || ' ' || lower_case AS original_string,
           LENGTH(original_string || ' ' || lower_case) AS length,
           UPPER(original_string || ' ' || lower_case) AS upper_case,
           LOWER(original_string || ' ' || lower_case) AS lower_case,
           REPLACE(original_string || ' ' || lower_case, 'a', '@') AS replace_a,
           SUBSTRING(original_string || ' ' || lower_case, 1, 5) AS substring_5,
           CONCAT(original_string || ' ' || lower_case, ' - Processed') AS concatenated
    FROM StringBenchmark
    WHERE LENGTH(original_string) < 100
)
SELECT 
    original_string, 
    length, 
    upper_case, 
    lower_case, 
    replace_a, 
    substring_5, 
    concatenated 
FROM StringBenchmark
WHERE length IS NOT NULL
ORDER BY length DESC
LIMIT 50;
