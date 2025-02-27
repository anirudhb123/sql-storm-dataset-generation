
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
popular_items AS (
    SELECT
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_profit,
        ci.c_email_address
    FROM 
        ranked_sales ri
    JOIN 
        customer_info ci ON ci.c_customer_sk IN (
            SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ri.ws_item_sk
        )
    WHERE 
        ri.rank = 1 AND ri.total_quantity > 100
)
SELECT 
    pi.ws_item_sk,
    pi.total_quantity,
    pi.total_profit,
    ci.c_email_address,
    COALESCE(ci.cd_gender, 'Unknown') AS gender,
    COALESCE(ci.cd_marital_status, 'N/A') AS marital_status,
    "Above average" AS customer_status
FROM 
    popular_items pi
LEFT JOIN 
    customer_info ci ON ci.c_email_address = pi.c_email_address
WHERE 
    pi.total_profit > (
        SELECT AVG(total_profit) 
        FROM ranked_sales 
        WHERE rank = 1
    )
ORDER BY 
    pi.total_profit DESC
LIMIT 10;
