
WITH AddressWords AS (
    SELECT
        ca_address_sk,
        LOWER(ca_street_name) AS street_name,
        REGEXP_SPLIT_TO_TABLE(ca_street_name, '\s+') AS word
    FROM
        customer_address
),
WordCounts AS (
    SELECT
        ca_address_sk,
        word,
        COUNT(*) AS word_count
    FROM
        AddressWords
    WHERE
        LENGTH(word) > 3
    GROUP BY
        ca_address_sk, word
),
TopWords AS (
    SELECT
        word,
        SUM(word_count) AS total_count
    FROM
        WordCounts
    GROUP BY
        word
    ORDER BY
        total_count DESC
    LIMIT 10
)
SELECT
    ca.city,
    ca.state,
    STRING_AGG(w.word, ', ') AS top_words,
    SUM(w.total_count) AS aggregate_count
FROM
    customer_address ca
JOIN
    WordCounts wc ON ca.ca_address_sk = wc.ca_address_sk
JOIN
    TopWords w ON wc.word = w.word
GROUP BY
    ca.city, ca.state
ORDER BY
    aggregate_count DESC;
