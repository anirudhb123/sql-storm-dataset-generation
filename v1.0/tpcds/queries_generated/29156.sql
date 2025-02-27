
WITH StringAggregates AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS trimmed_full_name,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '-') AS hyphenated_name,
        CHAR_LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS char_length,
        REGEXP_COUNT(CONCAT(c.c_first_name, ' ', c.c_last_name), '[aeiou]') AS vowel_count
    FROM 
        customer c
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
FullNameCounts AS (
    SELECT 
        lower_full_name,
        COUNT(*) AS name_count
    FROM 
        StringAggregates
    GROUP BY 
        lower_full_name
)
SELECT 
    lower_full_name, 
    name_count,
    AVG(name_length) AS avg_name_length,
    SUM(vowel_count) AS total_vowel_count,
    MAX(name_count) AS max_name_frequency
FROM 
    StringAggregates
JOIN 
    FullNameCounts ON StringAggregates.lower_full_name = FullNameCounts.lower_full_name
GROUP BY 
    lower_full_name, name_count
ORDER BY 
    total_vowel_count DESC, avg_name_length ASC
LIMIT 10;
