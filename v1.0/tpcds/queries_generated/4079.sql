
WITH ranked_sales AS (
    SELECT 
        ws_ship_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales 
    GROUP BY ws_ship_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        ral.ws_ship_date_sk,
        ral.ws_item_sk,
        ral.total_quantity,
        ral.total_profit,
        rank() OVER (PARTITION BY ral.ws_ship_date_sk ORDER BY ral.total_profit DESC) AS rank
    FROM ranked_sales ral
    WHERE ral.profit_rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        coalesce(ub.lower_bound, 0) AS lower_income,
        coalesce(ub.upper_bound, 100000) AS upper_income,
        sc.s_store_name,
        sc.s_city
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ub ON hd.hd_income_band_sk = ub.ib_income_band_sk
    LEFT JOIN store sc ON c.c_current_addr_sk = sc.s_store_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.marital_status,
    SUM(ti.total_quantity) AS total_purchased,
    SUM(ti.total_profit) AS total_profit_earned,
    COUNT(DISTINCT ti.ws_item_sk) AS unique_items_purchased,
    AVG(ti.total_profit) AS average_profit_per_item
FROM customer_info ci
JOIN top_items ti ON ci.c_customer_id = CAST(ti.ws_item_sk AS CHAR(16))
GROUP BY 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.gender, 
    ci.marital_status
HAVING 
    SUM(ti.total_profit) > 1000
ORDER BY 
    total_profit_earned DESC
LIMIT 10;
