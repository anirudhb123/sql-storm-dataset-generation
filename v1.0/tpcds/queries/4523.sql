
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ss.total_net_profit
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ss.ws_item_sk LIMIT 1)
    WHERE ss.profit_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    SUM(ss.total_quantity) AS total_quantity,
    SUM(ss.total_net_profit) AS total_net_profit,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM top_customers tc
JOIN customer_info ci ON tc.c_customer_sk = ci.c_customer_sk
LEFT JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
JOIN sales_summary ss ON tc.c_customer_sk = ss.ws_item_sk
GROUP BY 
    tc.c_first_name, 
    tc.c_last_name, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound, 
    ci.cd_gender, 
    ci.cd_marital_status
ORDER BY total_net_profit DESC;
