
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
), 
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_income_band_sk,
        ci.total_orders,
        ci.total_spent
    FROM 
        customer_info ci
    WHERE 
        ci.total_spent > (
            SELECT AVG(total_spent) 
            FROM customer_info
        )
)
SELECT 
    t.rank,
    t.ws_item_sk,
    t.ws_order_number,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_income_band_sk,
    tc.total_orders,
    tc.total_spent
FROM 
    ranked_sales t
JOIN 
    top_customers tc ON t.ws_item_sk IN (
        SELECT 
            inv.inv_item_sk 
        FROM 
            inventory inv 
        WHERE 
            inv.inv_quantity_on_hand > 0
    )
WHERE 
    t.rank = 1
ORDER BY 
    tc.total_spent DESC
LIMIT 10;
