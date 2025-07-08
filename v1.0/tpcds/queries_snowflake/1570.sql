
WITH sales_summary AS (
    SELECT
        ws_ship_date_sk,
        ws_web_page_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_ship_date_sk, ws_web_page_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_birth_year DESC) AS row_num
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ss.total_net_profit,
    ss.total_orders,
    DENSE_RANK() OVER (ORDER BY ss.total_net_profit DESC) AS rank_profit,
    (SELECT COUNT(*)
     FROM web_sales ws
     WHERE ws.ws_ship_date_sk = ss.ws_ship_date_sk
     AND ws.ws_web_page_sk = ss.ws_web_page_sk) AS total_sales_per_page,
    CASE 
        WHEN ci.cd_credit_rating = 'Excellent' THEN 'High Value'
        WHEN ci.cd_credit_rating = 'Good' THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    sales_summary ss
JOIN customer_info ci ON ci.c_customer_sk = (
    SELECT ws_bill_customer_sk
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk = ss.ws_ship_date_sk
    ORDER BY ws.ws_net_profit DESC
    LIMIT 1
)
WHERE
    ss.total_net_profit > 5000
ORDER BY
    ss.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
