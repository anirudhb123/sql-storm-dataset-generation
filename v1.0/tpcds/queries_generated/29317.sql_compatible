
WITH StringProcessingResults AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        SUBSTRING(c.c_email_address, 1, 10) AS email_substring,
        LOWER(c.c_email_address) AS email_lowercase,
        UPPER(c.c_email_address) AS email_uppercase,
        REPLACE(c.c_email_address, '@', '[at]') AS email_replaced,
        REGEXP_REPLACE(c.c_email_address, '(^[a-zA-Z0-9]+)', 'user') AS email_regex_replaced,
        CHAR_LENGTH(c.c_first_name) + CHAR_LENGTH(c.c_last_name) AS total_name_length
    FROM 
        customer c
    WHERE 
        c.c_first_name IS NOT NULL 
        AND c.c_last_name IS NOT NULL
),
BenchmarkedResults AS (
    SELECT 
        s.s_store_name,
        sr.ss_net_paid,
        sr.ss_net_paid_inc_tax,
        sr.ss_net_profit,
        STRING_AGG(CONCAT(s.s_city, ', ', s.s_state), '; ') AS store_locations,
        COUNT(DISTINCT sr.ss_item_sk) AS distinct_items_sold
    FROM 
        store s
    JOIN 
        store_sales sr ON s.s_store_sk = sr.ss_store_sk
    GROUP BY 
        s.s_store_name, sr.ss_net_paid, sr.ss_net_paid_inc_tax, sr.ss_net_profit
)
SELECT 
    sp.full_name,
    sp.first_name_length,
    sp.last_name_length,
    sp.email_substring,
    sp.email_lowercase,
    sp.email_uppercase,
    sp.email_replaced,
    sp.email_regex_replaced,
    sp.total_name_length,
    br.s_store_name,
    br.store_locations,
    br.distinct_items_sold
FROM 
    StringProcessingResults sp
JOIN 
    BenchmarkedResults br ON sp.first_name_length + sp.last_name_length BETWEEN 10 AND 30
ORDER BY 
    sp.total_name_length DESC
LIMIT 100;
