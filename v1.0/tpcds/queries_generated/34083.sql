
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rnk
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
customer_demographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_address ca
    LEFT JOIN
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT
    cs.ws_bill_customer_sk,
    cs.total_sales,
    cs.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    ai.customer_count
FROM
    sales_summary cs
JOIN
    customer_demographics cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
JOIN
    address_info ai ON cd.c_current_addr_sk = ai.ca_address_sk
WHERE
    cs.rnk <= 10
    AND cd.cd_credit_rating IS NOT NULL
    AND ai.customer_count > 5
UNION ALL
SELECT
    NULL AS ws_bill_customer_sk,
    SUM(ws_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_count,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS cd_purchase_estimate,
    NULL AS ca_city,
    NULL AS ca_state,
    NULL AS ca_country,
    NULL AS customer_count
FROM
    web_sales
WHERE
    ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023);
