
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_profit DESC
    LIMIT 10
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
high_value_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        is.total_quantity,
        is.total_net_profit
    FROM 
        item i
    JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
    WHERE 
        is.total_net_profit > 1000
        AND is.rn <= 5
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    hvi.i_item_desc,
    hvi.total_quantity,
    hvi.total_net_profit,
    COALESCE(hvi.total_net_profit / NULLIF(tc.total_profit, 0), 0) AS profit_ratio
FROM 
    top_customers tc
LEFT JOIN 
    high_value_items hvi ON hvi.total_net_profit > 0
ORDER BY 
    profit_ratio DESC
;
