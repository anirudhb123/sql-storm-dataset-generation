
WITH customer_metrics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT s.ss_ticket_number) AS total_store_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_purchases,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate > 1000
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.total_store_purchases,
        cm.total_web_purchases,
        (cm.total_store_profit + cm.total_web_profit) AS grand_total_profit
    FROM
        customer_metrics cm
    JOIN
        customer c ON cm.c_customer_sk = c.c_customer_sk
    ORDER BY
        grand_total_profit DESC
    LIMIT 10
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_store_purchases,
    tc.total_web_purchases,
    tc.grand_total_profit
FROM
    top_customers tc
JOIN
    (SELECT DISTINCT d_year FROM date_dim WHERE d_year >= 2015) dy ON 1=1
ORDER BY
    tc.grand_total_profit DESC;
