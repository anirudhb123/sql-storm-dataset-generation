
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_order_number
),
top_items AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit
    FROM ranked_sales
    WHERE rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        SUM(ti.total_profit) AS customer_profit,
        COUNT(DISTINCT ti.ws_order_number) AS order_count
    FROM customer_info ci
    LEFT JOIN top_items ti ON ci.c_customer_sk = ti.ws_item_sk
    GROUP BY ci.c_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.buy_potential,
    COALESCE(ss.customer_profit, 0) AS customer_profit,
    COALESCE(ss.order_count, 0) AS order_count,
    CASE 
        WHEN ss.customer_profit > 1000 THEN 'High Value'
        WHEN ss.customer_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
ORDER BY customer_profit DESC, ci.c_last_name, ci.c_first_name;
