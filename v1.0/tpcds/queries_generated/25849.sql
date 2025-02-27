
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(CONCAT(c.ca_street_number, ' ', c.ca_street_name, ' ', c.ca_street_type, 
                       CASE WHEN c.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', c.ca_suite_number) ELSE '' END,
                       ', ', c.ca_city, ', ', c.ca_state, ' ', c.ca_zip), '  ', ' ') AS full_address,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS month,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY month
),
address_count AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.full_address,
    ms.month,
    ms.total_sales,
    ms.order_count,
    ac.customer_count
FROM customer_info ci
JOIN monthly_sales ms ON DATE_TRUNC('month', current_date) = ms.month
LEFT JOIN address_count ac ON ci.full_address LIKE CONCAT('%', ac.ca_city, '%') AND ci.full_address LIKE CONCAT('%', ac.ca_state, '%')
WHERE ci.cd_purchase_estimate > 1000
ORDER BY ms.total_sales DESC, ci.full_name ASC;
