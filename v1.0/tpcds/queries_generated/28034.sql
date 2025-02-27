
WITH StringMetrics AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_visited_count
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),
Benchmarking AS (
    SELECT
        *,
        CASE 
            WHEN full_name_length BETWEEN 20 AND 40 THEN 'Medium'
            WHEN full_name_length < 20 THEN 'Short'
            ELSE 'Long'
        END AS name_length_category
    FROM
        StringMetrics
)
SELECT
    name_length_category,
    COUNT(*) AS customer_count,
    AVG(first_name_length) AS avg_first_name_length,
    AVG(last_name_length) AS avg_last_name_length,
    AVG(full_name_length) AS avg_full_name_length,
    AVG(web_pages_visited_count) AS avg_web_pages_visited
FROM
    Benchmarking
GROUP BY
    name_length_category
ORDER BY
    name_length_category;
