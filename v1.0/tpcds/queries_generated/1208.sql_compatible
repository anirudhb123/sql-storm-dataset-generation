
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.order_count,
        cs.total_spent,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS rank
    FROM customer_summary cs
)
SELECT 
    t.ws_order_number AS order_number,
    it.i_item_id,
    it.i_product_name,
    t.ws_net_profit AS net_profit,
    COALESCE(cc.total_spent, 0) AS total_spent,
    COALESCE(cc.order_count, 0) AS order_count,
    CASE 
        WHEN cc.cd_gender = 'M' THEN 'Male'
        WHEN cc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_category
FROM ranked_sales t
JOIN item it ON t.ws_item_sk = it.i_item_sk
LEFT JOIN top_customers cc ON cc.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = t.ws_order_number LIMIT 1)
WHERE t.rn = 1 AND (cc.rank IS NULL OR cc.rank <= 10)
ORDER BY t.ws_net_profit DESC;
