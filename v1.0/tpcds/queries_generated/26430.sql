
WITH String_Benchmark AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) as name_length,
        TRIM(UPPER(c.c_email_address)) AS email_upper_trim,
        SUBSTRING(c.c_email_address, INSTR(c.c_email_address, '@') + 1) AS email_domain,
        COUNT(DISTINCT ca.ca_address_id) OVER (PARTITION BY c.c_customer_sk) AS address_count,
        DENSE_RANK() OVER (ORDER BY LENGTH(c.c_email_address)) AS email_length_rank
    FROM
        customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_preferred_cust_flag = 'Y' AND
        ca.ca_city IS NOT NULL
),
Aggregated_Results AS (
    SELECT 
        AVG(name_length) AS avg_full_name_length,
        COUNT(DISTINCT email_upper_trim) AS unique_emails,
        MAX(email_length_rank) AS max_email_rank
    FROM 
        String_Benchmark
)
SELECT 
    avg_full_name_length,
    unique_emails,
    max_email_rank
FROM 
    Aggregated_Results;
