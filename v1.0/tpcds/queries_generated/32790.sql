
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_order_number
), customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), top_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        si.total_quantity,
        si.total_net_paid
    FROM
        customer_info ci
    LEFT JOIN
        sales_summary si ON ci.c_customer_sk = si.ws_order_number
    WHERE
        ci.gender_rank <= 10
), address_info AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_address ca
    JOIN
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_address_id, ca.ca_city
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    ai.ca_city,
    ai.customer_count,
    COALESCE(tc.total_net_paid, 0) AS total_net_paid,
    RANK() OVER (ORDER BY COALESCE(tc.total_net_paid, 0) DESC) AS rank_by_spending
FROM
    top_customers tc
JOIN
    address_info ai ON tc.c_customer_sk = ai.customer_count
WHERE
    ai.customer_count > 1
ORDER BY
    rank_by_spending
LIMIT 100;
