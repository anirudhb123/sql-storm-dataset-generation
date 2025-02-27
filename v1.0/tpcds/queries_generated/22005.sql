
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
store_average AS (
    SELECT 
        s.s_store_sk,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        COUNT(ss.ss_ticket_number) AS total_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    SUM(CASE WHEN rs.rank_profit = 1 THEN rs.ws_net_profit ELSE 0 END) AS top_profit,
    sa.avg_net_profit,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value Customer'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM customer_data cd
JOIN ranked_sales rs ON cd.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN store_average sa ON cd.hd_income_band_sk IS NULL OR cd.hd_income_band_sk = sa.s_store_sk
LEFT JOIN store_sales ss ON ss.ss_customer_sk = cd.c_customer_sk
WHERE cd.cd_marital_status = 'M' 
AND (cd.ib_lower_bound IS NULL OR cd.ib_upper_bound > 60000) 
GROUP BY cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, sa.avg_net_profit
ORDER BY total_orders DESC, top_profit DESC;
