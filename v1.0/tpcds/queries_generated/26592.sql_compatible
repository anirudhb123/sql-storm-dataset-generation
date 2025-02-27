
WITH RECURSIVE split_words AS (
    SELECT 
        ca_address_id AS address_id,
        REGEXP_SUBSTR(ca_street_name, '[^ ]+', 1, LEVEL) AS word,
        LEVEL AS word_position
    FROM customer_address
    CONNECT BY REGEXP_SUBSTR(ca_street_name, '[^ ]+', 1, LEVEL) IS NOT NULL
),
word_counts AS (
    SELECT 
        word, 
        COUNT(*) AS count, 
        COUNT(DISTINCT address_id) AS unique_address_count
    FROM split_words
    GROUP BY word
)
SELECT 
    word, 
    count,
    unique_address_count,
    LENGTH(word) AS word_length,
    UPPER(word) AS upper_case_word
FROM word_counts
WHERE count > 5
ORDER BY count DESC, word_length ASC;
