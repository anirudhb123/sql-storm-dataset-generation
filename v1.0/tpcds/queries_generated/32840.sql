
WITH RECURSIVE sales_summary AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_sk, ws.web_name
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CA.ca_city,
        cd.cd_gender,
        cd.cd_age,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, CA.ca_city, cd.cd_gender, cd.cd_age
),
top_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.ca_city,
        ci.cd_gender,
        ci.cd_age,
        ci.total_orders,
        ci.total_profit,
        RANK() OVER (ORDER BY ci.total_profit DESC) AS customer_rank
    FROM
        customer_info ci
    WHERE
        ci.total_profit > 1000
)
SELECT
    ss.web_name,
    ss.total_profit AS website_profit,
    ss.total_orders AS website_orders,
    tc.ca_city,
    tc.cd_gender,
    tc.cd_age,
    tc.total_orders AS customer_orders,
    tc.total_profit AS customer_profit
FROM
    sales_summary ss
FULL OUTER JOIN top_customers tc ON ss.web_site_sk = tc.c_customer_sk
WHERE
    ss.profit_rank <= 5
    OR tc.customer_rank <= 10
ORDER BY
    website_profit DESC, customer_profit DESC;
