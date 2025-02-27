
WITH customer_details AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
merged_data AS (
    SELECT
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        ss.total_spent,
        ss.total_orders
    FROM
        customer_details cd
    LEFT JOIN sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT
    md.ca_city,
    md.ca_state,
    AVG(md.total_spent) AS avg_spent,
    COUNT(md.c_customer_id) AS customer_count,
    COUNT(DISTINCT md.total_orders) AS unique_orders
FROM
    merged_data md
WHERE
    md.total_spent IS NOT NULL
GROUP BY
    md.ca_city,
    md.ca_state
ORDER BY
    avg_spent DESC
LIMIT 10;
