
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales 
    GROUP BY ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
top_customers AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.order_count,
        ca.total_spent
    FROM customer_analysis ca
    WHERE ca.total_spent IS NOT NULL
    ORDER BY ca.total_spent DESC
    LIMIT 10
),
inventory_status AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    GROUP BY i.i_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    sd.total_sold,
    sd.total_profit,
    is.total_inventory,
    CASE 
        WHEN sd.total_profit IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status
FROM top_customers tc
LEFT JOIN sales_data sd ON tc.c_customer_sk = sd.ws_item_sk
LEFT JOIN inventory_status is ON sd.ws_item_sk = is.i_item_sk
WHERE (is.total_inventory IS NULL OR is.total_inventory > 0)
ORDER BY tc.total_spent DESC, sd.total_profit DESC;
