
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
),
sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        rss.ws_item_sk,
        rss.ws_net_profit,
        ss.total_quantity,
        ss.total_net_profit
    FROM 
        ranked_sales rss
    JOIN 
        sales_summary ss ON rss.ws_item_sk = ss.ws_item_sk 
    WHERE 
        rss.rank = 1
)
SELECT 
    ti.ws_item_sk,
    ti.ws_net_profit,
    ti.total_quantity,
    ti.total_net_profit,
    COALESCE((SELECT AVG(total_net_profit) 
               FROM top_items 
               WHERE total_quantity > 100), 0) as avg_profit_over_100_units,
    CASE 
        WHEN ti.total_net_profit > COALESCE((SELECT MAX(total_net_profit) 
                                              FROM top_items 
                                              WHERE total_quantity < 50), 0) THEN 'High Performer'
        ELSE 'Low Performer'
    END as performance_category
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk LIMIT 1)
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND cd.cd_marital_status IS NOT NULL
ORDER BY 
    ti.total_net_profit DESC
LIMIT 100
OFFSET 50;
