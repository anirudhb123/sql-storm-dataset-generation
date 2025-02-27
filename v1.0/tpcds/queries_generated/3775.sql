
WITH ranked_sales AS (
    SELECT 
        ws.warehouse_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rank
    FROM web_sales ws
    WHERE ws_sold_date_sk BETWEEN 20231101 AND 20231130
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        CD.cd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) as income_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.cd_gender, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer_info ci
    JOIN ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
    WHERE ci.income_rank <= 5
    GROUP BY ci.c_customer_sk, ci.cd_gender
),
store_sales_summary AS (
    SELECT 
        ss.store_sk,
        SUM(ss.ss_net_sales) AS total_net_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE w.w_country = 'USA'
    GROUP BY ss.store_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(ss.total_net_sales, 0) AS total_net_sales,
    COALESCE(hvc.total_profit, 0) AS total_customer_profit
FROM store s
LEFT JOIN store_sales_summary ss ON s.s_store_sk = ss.store_sk
LEFT JOIN high_value_customers hvc ON hvc.c_customer_sk = s.s_store_sk
ORDER BY total_net_sales DESC, total_customer_profit DESC
LIMIT 10;

