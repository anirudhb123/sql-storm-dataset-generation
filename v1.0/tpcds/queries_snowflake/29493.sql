
WITH string_benchmark AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(LOWER(c.c_email_address), '@', '[at]') AS modified_email,
        LENGTH(c.c_first_name) + LENGTH(c.c_last_name) AS name_length,
        LISTAGG(DISTINCT ca.ca_city, ', ') WITHIN GROUP (ORDER BY ca.ca_city) AS unique_cities
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address
),
benchmark_summary AS (
    SELECT
        COUNT(*) AS total_customers,
        AVG(name_length) AS avg_name_length,
        COUNT(DISTINCT modified_email) AS unique_emails,
        MAX(LENGTH(full_name)) AS max_name_length,
        LISTAGG(DISTINCT unique_cities, '; ') WITHIN GROUP (ORDER BY unique_cities) AS all_cities
    FROM
        string_benchmark
)
SELECT
    *
FROM
    benchmark_summary;
