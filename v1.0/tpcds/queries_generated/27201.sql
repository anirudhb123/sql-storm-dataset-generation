
WITH String_Processing_Benchmark AS (
    SELECT 
        ca.c_city AS city,
        ca.ca_state AS state,
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS uppercase_email,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTRING_INDEX(c.c_email_address, '@', 1) AS email_prefix,
        CONCAT(SUBSTRING_INDEX(c.c_email_address, '@', 1), 
               TRIM(BOTH ' ' FROM ca.ca_city), 
               c.c_birth_year) AS concatenated_id
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
),
String_Aggregates AS (
    SELECT 
        city,
        state,
        COUNT(DISTINCT customer_id) AS unique_customers,
        AVG(email_length) AS avg_email_length,
        MAX(email_length) AS max_email_length,
        MIN(email_length) AS min_email_length
    FROM 
        String_Processing_Benchmark
    GROUP BY 
        city, state
)
SELECT 
    city,
    state,
    unique_customers,
    avg_email_length,
    max_email_length,
    min_email_length,
    CONCAT('Summary for ', city, ', ', state) AS report_title
FROM 
    String_Aggregates
ORDER BY 
    unique_customers DESC, state, city;
