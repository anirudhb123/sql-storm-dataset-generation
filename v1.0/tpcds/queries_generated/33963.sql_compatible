
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        1 AS depth
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20230131
    
    UNION ALL
    
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        sd.depth + 1
    FROM 
        catalog_sales cs
    JOIN sales_data sd ON sd.ws_item_sk = cs.cs_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 20230101 AND 20230131 AND sd.depth < 3
)

SELECT 
    s.store_sk,
    SUM(sd.ws_quantity) AS total_quantity,
    AVG(sd.ws_net_profit) AS average_profit,
    COUNT(DISTINCT sd.ws_order_number) AS unique_orders,
    (
        SELECT 
            COUNT(*)
        FROM 
            store_returns sr
        WHERE 
            sr.sr_item_sk = sd.ws_item_sk AND 
            sr.sr_return_quantity > 0
    ) AS total_returns
FROM 
    store s
LEFT JOIN 
    sales_data sd ON s.s_store_sk = sd.ws_item_sk
GROUP BY 
    s.store_sk
HAVING 
    SUM(sd.ws_quantity) > 100
ORDER BY 
    average_profit DESC
LIMIT 10;
