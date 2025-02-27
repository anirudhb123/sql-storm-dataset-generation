
WITH ranked_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_education_status,
        r.cd_purchase_estimate
    FROM
        ranked_customers r
    WHERE
        r.purchase_rank <= 10
),
customer_addresses AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        tc.c_customer_sk
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN
        top_customers tc ON c.c_customer_sk = tc.c_customer_sk
)
SELECT
    a.ca_city,
    a.ca_state,
    a.ca_country,
    COUNT(tc.c_customer_sk) AS customer_count,
    GROUP_CONCAT(CONCAT(tc.c_first_name, ' ', tc.c_last_name) ORDER BY tc.c_first_name) AS customer_names
FROM
    customer_addresses a
JOIN
    top_customers tc ON a.c_customer_sk = tc.c_customer_sk
GROUP BY
    a.ca_city, a.ca_state, a.ca_country
ORDER BY
    customer_count DESC, a.ca_city;
