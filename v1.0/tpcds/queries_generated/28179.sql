
WITH StringBenchmarks AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        TRIM(BOTH ' ' FROM CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS trimmed_full_name,
        UPPER(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS upper_full_name,
        LENGTH(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS length_full_name,
        SUBSTRING(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) FROM 1 FOR 10) AS short_name,
        REPLACE(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name), ' ', '-') AS hyphenated_full_name,
        REGEXP_REPLACE(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name), '[^A-Za-z0-9 ]', '') AS alphanumeric_full_name,
        LPAD(c.c_customer_sk, 10, '0') AS padded_customer_id
    FROM 
        customer c
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
),
AggregatedBenchmarks AS (
    SELECT 
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        AVG(length_full_name) AS avg_length_full_name,
        COUNT(CASE WHEN trimmed_full_name LIKE '% %' THEN 1 END) AS multiple_word_names,
        COUNT(CASE WHEN length_full_name > 30 THEN 1 END) AS long_names
    FROM 
        StringBenchmarks
)
SELECT 
    *,
    (SELECT UPPER(STUFF(STRING_AGG(full_name, ', '), 1, 0, '')) FROM StringBenchmarks) AS aggregated_full_names
FROM 
    AggregatedBenchmarks;
