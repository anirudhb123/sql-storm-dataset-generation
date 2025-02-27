
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(SUBSTRING(c.c_email_address, LOCATE('@', c.c_email_address) + 1), 'No Email') AS email_domain,
        c.c_city,
        c.c_state,
        (SELECT COUNT(*) FROM store_sales WHERE ss_customer_sk = c.c_customer_sk) AS sales_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
),

address_summary AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count
    FROM
        customer_address ca
    JOIN 
        customer_info ci ON ca.ca_city = ci.c_city AND ca.ca_state = ci.c_state
    GROUP BY
        ca.ca_state
)

SELECT
    asu.ca_state,
    asu.address_count,
    asu.customer_count,
    ROUND(asu.customer_count / NULLIF(asu.address_count, 0), 2) AS avg_customers_per_address
FROM
    address_summary asu
WHERE
    asu.customer_count > 10
ORDER BY
    avg_customers_per_address DESC;
