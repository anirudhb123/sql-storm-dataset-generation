
WITH AddressWords AS (
    SELECT 
        DISTINCT 
        TRIM(LOWER(SUBSTRING(ca_street_name, POSITION(' ' IN ca_street_name) + 1))) AS word
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
),
WordCount AS (
    SELECT 
        word, 
        LENGTH(word) AS length,
        COUNT(*) AS count
    FROM 
        AddressWords
    GROUP BY 
        word
),
StringAggregation AS (
    SELECT 
        STRING_AGG(word, ', ') AS all_words,
        MAX(length) AS max_length,
        MIN(length) AS min_length,
        AVG(length) AS avg_length
    FROM 
        WordCount
)
SELECT 
    all_words,
    max_length,
    min_length,
    avg_length,
    COUNT(*) AS total_unique_words
FROM 
    StringAggregation
GROUP BY 
    all_words, max_length, min_length, avg_length
ORDER BY 
    avg_length DESC
LIMIT 10;
