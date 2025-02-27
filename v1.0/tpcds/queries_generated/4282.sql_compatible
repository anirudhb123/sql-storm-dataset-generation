
WITH recent_sales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        CA.ca_city,
        CA.ca_state
    FROM
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
),
sales_summary AS (
    SELECT
        ci.c_customer_sk,
        ci.cd_gender,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_spent,
        SUM(rs.ws_net_profit) AS total_profit
    FROM
        recent_sales rs
        JOIN customer_info ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
    WHERE
        ci.cd_gender = 'F'
    GROUP BY
        ci.c_customer_sk,
        ci.cd_gender
)
SELECT
    ss.c_customer_sk,
    ss.cd_gender,
    ss.total_spent,
    ss.total_profit,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = ss.c_customer_sk AND ss2.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)) AS store_sales_count,
    (SELECT AVG(ss_net_paid) FROM web_sales WHERE ws_bill_customer_sk = ss.c_customer_sk AND ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)) AS avg_web_sales
FROM
    sales_summary ss
WHERE
    ss.total_spent > 1000
ORDER BY
    ss.total_spent DESC
LIMIT 10;
